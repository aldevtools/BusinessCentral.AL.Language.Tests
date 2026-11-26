// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 99538-99546 (GRK X, GRK Y, GRK Mode, GRK Steps, GRK Inner X,
//   GRK Inner Z, GRK Z, GRK Kind, GRK Tests)
// Probe: from al-runner issue 9188 (follow-up of al-runner PR 9182, issue 8970). Same cells as ConsistentGuardedRunRecPage.al, but the
//   record argument of Codeunit.Run(Id, Rec) belongs to a table with a two-field primary key (an Enum field and a Code field), like
//   Purchase Header (Document Type, No.) and Warehouse Activity Header (Type, No.).
// Area: the cells (the guarded run under asserterror that ends in Error('END'); then a Commit in the caller; then the durable rows):
//   - Argument table: GRK Z (never marked) and GRK X (marked first by the step startx or fxa). Fields: Doc Kind (Enum, key 1), No.
//     (Code, key 2), Name, Doc Type, Amount, Date Filter (FlowFilter), Kind (Enum, not in the key). Rows: (Order, 1) 'caller',
//     (Invoice, 2) 'other', (Invoice, 1) 'twin'. The argument is on the row 'caller' (FindFirst after the filters).
//   - Filter shapes: NoFilter; PageMix (group 2 SetRange on the key field Doc Kind, group 0 SetRange("Date Filter", 0D, WorkDate()):
//     the Purchase Invoice page shape of codeunit 134762 PurchaseInvoiceInvAndDiscPreview); PageMixKey (the same and SetFilter("No.",
//     '1'), the TestPage filter of that test); PageMixOut and PageMixOutKey (the same with the view on Kind, outside the key);
//     KeyCode (SetRange("No.", '1')); KeyEnum (SetRange("Doc Kind", Order)); KeyBoth (both); Three (SetRange on Name, Doc Type,
//     Amount); ThreeKey (SetRange on Doc Type, Name and the key field Doc Kind: the shape of FindWarehouseActivityLine in the put-away
//     preview tests, Source Type, Source No., Activity Type).
//   - Marks (steps of the inner codeunit): Fails = startx,fya,err; Ends = startx,fya; PlainCommit = fxa,fya,commit; MarkedAgain =
//     startx,fya,fyc,err; ReleasedThenHeld = startx,txb,fya,err; AgainThenHeld = fxa,txb,fxc,fya,err (as in
//     ConsistentGuardedRunRecPage.al).
//   Each cell reads: the run's error, the log of the caller (inner codeunit's view of the argument: FilterGroup, GetFilters of group
//   0, 1, 2, 4, 6, filtered count; return value; last error text and code; the argument's Name; the same view of the argument after
//   the run), the error of a later Commit, and the rows that are durable. Every cell starts with committed rows in every table.
//WHATBCDID
// The values are what BC produced.
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunit is the code under test.
// BC versions: 27.5, 28.5, 29.0

table 99538 "GRK X"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc Kind"; Enum "GRK Kind") { }
        field(2; "No."; Code[20]) { }
        field(3; Name; Text[30]) { }
        field(4; "Doc Type"; Integer) { }
        field(5; Amount; Decimal) { }
        field(6; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(7; Kind; Enum "GRK Kind") { }
    }

    keys
    {
        key(PK; "Doc Kind", "No.") { Clustered = true; }
    }
}

table 99539 "GRK Y"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 99544 "GRK Z"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Doc Kind"; Enum "GRK Kind") { }
        field(2; "No."; Code[20]) { }
        field(3; Name; Text[30]) { }
        field(4; "Doc Type"; Integer) { }
        field(5; Amount; Decimal) { }
        field(6; "Date Filter"; Date) { FieldClass = FlowFilter; }
        field(7; Kind; Enum "GRK Kind") { }
    }

    keys
    {
        key(PK; "Doc Kind", "No.") { Clustered = true; }
    }
}

enum 99545 "GRK Kind"
{
    Extensible = false;

    value(0; Quote) { }
    value(1; Order) { }
    value(2; Invoice) { }
}

// The steps the inner codeunit runs, and a log the caller writes (a SingleInstance codeunit is not rolled back).
codeunit 99540 "GRK Mode"
{
    SingleInstance = true;

    var
        Steps: Text;
        LogText: Text;

    procedure Set(NewSteps: Text)
    begin
        Steps := NewSteps;
        LogText := '';
    end;

    procedure Get(): Text
    begin
        exit(Steps);
    end;

    procedure Log(Line: Text)
    begin
        LogText += Line + ';';
    end;

    procedure GetLog(): Text
    begin
        exit(LogText);
    end;

    // The filter state of a record: the FilterGroup it reports, the filters of groups 0, 1, 2, 4, 6 and the filtered count.
    procedure Describe(var RecRef: RecordRef; Fg: Integer): Text
    var
        Groups: List of [Integer];
        G: Integer;
        Original: Integer;
        Result: Text;
    begin
        Groups.Add(0);
        Groups.Add(1);
        Groups.Add(2);
        Groups.Add(4);
        Groups.Add(6);
        Original := RecRef.FilterGroup();
        Result := 'fg=' + Format(Fg);
        foreach G in Groups do begin
            RecRef.FilterGroup(G);
            Result += ' g' + Format(G) + '=[' + RecRef.GetFilters() + ']';
        end;
        RecRef.FilterGroup(Original);
        Result += ' count=' + Format(RecRef.Count());
        exit(Result);
    end;
}

// The step interpreter: runs the steps of "GRK Mode", comma separated.
//   startx: insert a row into GRK X and mark GRK X from the same local variable (the preview state shape).
//   fxa, fya: Consistent(false) on a local variable for GRK X, GRK Y. commit: Commit. err: Error('inner failed').
codeunit 99541 "GRK Steps"
{
    procedure DoSteps()
    var
        Mode: Codeunit "GRK Mode";
        XA: Record "GRK X";
        YA: Record "GRK Y";
        XB: Record "GRK X";
        XC: Record "GRK X";
        YC: Record "GRK Y";
        Step: Text;
    begin
        foreach Step in Mode.Get().Split(',') do
            case Step of
                'startx':
                    StartX();
                'fxa':
                    XA.Consistent(false);
                'fya':
                    YA.Consistent(false);
                'fyc':
                    YC.Consistent(false);
                'fxc':
                    XC.Consistent(false);
                'txb':
                    XB.Consistent(true);
                'commit':
                    Commit();
                'err':
                    Error('inner failed');
            end;
    end;

    local procedure StartX()
    var
        X: Record "GRK X";
    begin
        X.Init();
        X."Doc Kind" := X."Doc Kind"::Quote;
        X."No." := '50';
        X.Name := 'state';
        X.Insert();
        X.Consistent(false);
    end;
}


// The inner codeunit for a record of GRK X. It logs the filter state of its argument.
codeunit 99542 "GRK Inner X"
{
    TableNo = "GRK X";

    trigger OnRun()
    var
        Steps: Codeunit "GRK Steps";
        Mode: Codeunit "GRK Mode";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Mode.Log('inner ' + Mode.Describe(RecRef, Rec.FilterGroup()));
        Steps.DoSteps();
    end;
}


// The inner codeunit for a record of GRK Z. It logs the filter state of its argument.
codeunit 99543 "GRK Inner Z"
{
    TableNo = "GRK Z";

    trigger OnRun()
    var
        Steps: Codeunit "GRK Steps";
        Mode: Codeunit "GRK Mode";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Mode.Log('inner ' + Mode.Describe(RecRef, Rec.FilterGroup()));
        Steps.DoSteps();
    end;
}


codeunit 99546 "GRK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Codeunit "GRK Mode";

    // Every cell starts with three committed rows in GRK X and GRK Z: (Order, 1) 'caller', (Invoice, 2) 'other' and (Invoice, 1)
    // 'twin' (same No. as 'caller', other Doc Kind), and two rows in GRK Y. The run gets the row 'caller'.
    local procedure Initialize(Steps: Text)
    var
        X: Record "GRK X";
        Y: Record "GRK Y";
        Z: Record "GRK Z";
        G: Integer;
    begin
        X.Consistent(true);
        Y.Consistent(true);
        Z.Consistent(true);
        for G := 0 to 6 do begin
            X.FilterGroup(G);
            X.SetRange("Doc Kind"); X.SetRange("No."); X.SetRange(Name); X.SetRange("Doc Type"); X.SetRange(Amount); X.SetRange("Date Filter"); X.SetRange(Kind);
            Z.FilterGroup(G);
            Z.SetRange("Doc Kind"); Z.SetRange("No."); Z.SetRange(Name); Z.SetRange("Doc Type"); Z.SetRange(Amount); Z.SetRange("Date Filter"); Z.SetRange(Kind);
        end;
        X.FilterGroup(0);
        Z.FilterGroup(0);
        X.DeleteAll();
        Y.DeleteAll();
        Z.DeleteAll();
        InsertRow(X, Z, X."Doc Kind"::Order, '1', 'caller', 1, 5);
        InsertRow(X, Z, X."Doc Kind"::Invoice, '2', 'other', 2, 50);
        InsertRow(X, Z, X."Doc Kind"::Invoice, '1', 'twin', 2, 50);
        Y.Init();
        Y.Id := 1;
        Y.Name := 'caller';
        Y.Insert();
        Y.Id := 2;
        Y.Name := 'other';
        Y.Insert();
        Commit();
        ClearLastError();
        Mode.Set(Steps);
    end;

    local procedure InsertRow(var X: Record "GRK X"; var Z: Record "GRK Z"; DocKind: Enum "GRK Kind"; No: Code[20]; NewName: Text[30]; DocType: Integer; NewAmount: Decimal)
    begin
        X.Init();
        X."Doc Kind" := DocKind;
        X."No." := No;
        X.Name := NewName;
        X."Doc Type" := DocType;
        X.Kind := DocKind;
        X.Amount := NewAmount;
        X.Insert();
        Z.Init();
        Z.TransferFields(X);
        Z.Insert();
    end;

    local procedure Rows(): Text
    var
        X: Record "GRK X";
        Y: Record "GRK Y";
        Z: Record "GRK Z";
        XNames: Text;
        YNames: Text;
        ZNames: Text;
    begin
        if X.FindSet() then
            repeat
                XNames += X.Name + ';';
            until X.Next() = 0;
        if Y.FindSet() then
            repeat
                YNames += Y.Name + ';';
            until Y.Next() = 0;
        if Z.FindSet() then
            repeat
                ZNames += Z.Name + ';';
            until Z.Next() = 0;
        exit('x=[' + XNames + '] y=[' + YNames + '] z=[' + ZNames + ']');
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    // Runs the inner codeunit. Kind: z, x = a database record of GRK Z / X. The argument is on the row 'caller'.
    local procedure RunRec(Kind: Text; Shape: Text; var ArgName: Text; var ArgState: Text) Ok: Boolean
    var
        X: Record "GRK X";
        Z: Record "GRK Z";
        RecRef: RecordRef;
    begin
        case Kind of
            'z':
                begin
                    PrepareZ(Z, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRK Inner Z", Z);
                    ArgName := Z.Name;
                    RecRef.GetTable(Z);
                    ArgState := Mode.Describe(RecRef, Z.FilterGroup());
                end;
            'x':
                begin
                    PrepareX(X, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRK Inner X", X);
                    ArgName := X.Name;
                    RecRef.GetTable(X);
                    ArgState := Mode.Describe(RecRef, X.FilterGroup());
                end;
        end;
    end;


    local procedure PrepareX(var R: Record "GRK X"; Shape: Text)
    begin
        case Shape of
            'PageMix':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Kind", R."Doc Kind"::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate());
                end;
            'PageMixKey':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Kind", R."Doc Kind"::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate()); R.SetFilter("No.", '1');
                end;
            'PageMixOut':
                begin
                    R.FilterGroup(2); R.SetRange(Kind, R.Kind::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate());
                end;
            'PageMixOutKey':
                begin
                    R.FilterGroup(2); R.SetRange(Kind, R.Kind::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate()); R.SetFilter("No.", '1');
                end;
            'KeyCode':
                begin
                    R.SetRange("No.", '1');
                end;
            'KeyEnum':
                begin
                    R.SetRange("Doc Kind", R."Doc Kind"::Order);
                end;
            'KeyBoth':
                begin
                    R.SetRange("Doc Kind", R."Doc Kind"::Order); R.SetRange("No.", '1');
                end;
            'Three':
                begin
                    R.SetRange(Name, 'caller'); R.SetRange("Doc Type", 1); R.SetRange(Amount, 5);
                end;
            'ThreeKey':
                begin
                    R.SetRange("Doc Type", 1); R.SetRange(Name, 'caller'); R.SetRange("Doc Kind", R."Doc Kind"::Order);
                end;
        end;
        R.FindFirst();
    end;

    local procedure PrepareZ(var R: Record "GRK Z"; Shape: Text)
    begin
        case Shape of
            'PageMix':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Kind", R."Doc Kind"::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate());
                end;
            'PageMixKey':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Kind", R."Doc Kind"::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate()); R.SetFilter("No.", '1');
                end;
            'PageMixOut':
                begin
                    R.FilterGroup(2); R.SetRange(Kind, R.Kind::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate());
                end;
            'PageMixOutKey':
                begin
                    R.FilterGroup(2); R.SetRange(Kind, R.Kind::Order); R.FilterGroup(0); R.SetRange("Date Filter", 0D, WorkDate()); R.SetFilter("No.", '1');
                end;
            'KeyCode':
                begin
                    R.SetRange("No.", '1');
                end;
            'KeyEnum':
                begin
                    R.SetRange("Doc Kind", R."Doc Kind"::Order);
                end;
            'KeyBoth':
                begin
                    R.SetRange("Doc Kind", R."Doc Kind"::Order); R.SetRange("No.", '1');
                end;
            'Three':
                begin
                    R.SetRange(Name, 'caller'); R.SetRange("Doc Type", 1); R.SetRange(Amount, 5);
                end;
            'ThreeKey':
                begin
                    R.SetRange("Doc Type", 1); R.SetRange(Name, 'caller'); R.SetRange("Doc Kind", R."Doc Kind"::Order);
                end;
        end;
        R.FindFirst();
    end;
    local procedure RunThenEnd(Kind: Text; Shape: Text)
    var
        Ok: Boolean;
        ArgName: Text;
        ArgState: Text;
    begin
        Ok := RunRec(Kind, Shape, ArgName, ArgState);
        Mode.Log('run=' + Format(Ok));
        Mode.Log('text=' + GetLastErrorText());
        Mode.Log('code=' + GetLastErrorCode());
        Mode.Log('arg=' + ArgName);
        Mode.Log('argstate ' + ArgState);
        ClearLastError();
        Error('END');
    end;

    local procedure CommitThenEnd()
    begin
        Commit();
        Error('END');
    end;

    local procedure RecCell(var Observer: Codeunit "Probe Observer"; Kind: Text; Shape: Text; Steps: Text)
    begin
        Initialize(Steps);
        asserterror RunThenEnd(Kind, Shape);
        Observer.ObserveError('run end');
        Observer.Observe('log', Mode.GetLog());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Observe('fresh record', FreshState());
    end;

    local procedure FreshState(): Text
    var
        X: Record "GRK X";
        Z: Record "GRK Z";
        Res: Text;
        G: Integer;
    begin
        Res := 'x count=' + Format(X.Count()) + ' z count=' + Format(Z.Count()) + ' z fg=' + Format(Z.FilterGroup());
        for G := 0 to 6 do begin
            Z.FilterGroup(G);
            Res += ' g' + Format(G) + '=[' + Z.GetFilters() + ']';
        end;
        exit(Res);
    end;

    [Test]
    procedure RecZ_NoFilter_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMix_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMix', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOut_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOut', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_PageMixOutKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'PageMixOutKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyCode', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyEnum_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyEnum', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyBoth_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'KeyBoth', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_Three_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Three', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'ThreeKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMix_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMix', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOut_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOut', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_PageMixOutKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'PageMixOutKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyCode', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyEnum_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyEnum', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyBoth_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'KeyBoth', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_Three_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Three', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'ThreeKey', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;
}
