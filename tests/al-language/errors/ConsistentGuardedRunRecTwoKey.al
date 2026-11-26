// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 99538-99546 (GRK X, GRK Y, GRK Mode, GRK Steps, GRK Inner X,
//   GRK Inner Z, GRK Z, GRK Kind, GRK Tests), 99547-99550 (GRK X3, GRK Z3, GRK Inner X3, GRK Inner Z3)
// Probe: from al-runner issue 9188 (follow-up of al-runner PR 9182, issue 8970). Same cells as ConsistentGuardedRunRecPage.al, but the
//   record argument of Codeunit.Run(Id, Rec) belongs to a table with a two-field primary key (an Enum field and a Code field), like
//   Purchase Header (Document Type, No.) and Warehouse Activity Header (Type, No.), or a three-field primary key (an Option, a Code
//   and an Integer field), like Warehouse Activity Line (Activity Type, No., Line No.).
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
//   - Three-field key table: GRK Z3 (never marked) and GRK X3 (marked first by startx or fxa, which then act on GRK X3). Fields:
//     Activity Type (Option ' ,Put-away,Pick', key 1), No. (Code, key 2), Line No. (Integer, key 3), Source Type, Source No., Name.
//     Rows: (Put-away, 1, 10000) 'caller', (Put-away, 1, 20000) 'line2', (Pick, 1, 10000) 'twin', (Put-away, 2, 10000) 'other'
//     (all Source Type 39; Source No. S1, but S2 on 'other'). Shapes: NoFilter3; KeyCode3 (SetRange("No.", '1')); ThreeKey3
//     (SetRange on Source Type 39, Source No. S1 and the key field Activity Type Put-away: FindWarehouseActivityLine of the
//     put-away preview tests in SCMInvtPutAwayPostPrev, which hand a Warehouse Activity Line to Gen. Jnl.-Post Preview).
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

table 99547 "GRK X3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Activity Type"; Option) { OptionMembers = " ","Put-away",Pick; }
        field(2; "No."; Code[20]) { }
        field(3; "Line No."; Integer) { }
        field(4; "Source Type"; Integer) { }
        field(5; "Source No."; Code[20]) { }
        field(6; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Activity Type", "No.", "Line No.") { Clustered = true; }
    }
}

table 99548 "GRK Z3"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Activity Type"; Option) { OptionMembers = " ","Put-away",Pick; }
        field(2; "No."; Code[20]) { }
        field(3; "Line No."; Integer) { }
        field(4; "Source Type"; Integer) { }
        field(5; "Source No."; Code[20]) { }
        field(6; Name; Text[30]) { }
    }

    keys
    {
        key(PK; "Activity Type", "No.", "Line No.") { Clustered = true; }
    }
}

// The steps the inner codeunit runs, and a log the caller writes (a SingleInstance codeunit is not rolled back).
codeunit 99540 "GRK Mode"
{
    SingleInstance = true;

    var
        Steps: Text;
        LogText: Text;
        ThreeKey: Boolean;

    procedure Set(NewSteps: Text)
    begin
        Steps := NewSteps;
        LogText := '';
        ThreeKey := false;
    end;

    // true: the steps that mark the argument table act on GRK X3 (three-field key) instead of GRK X.
    procedure SetThreeKey(NewThreeKey: Boolean)
    begin
        ThreeKey := NewThreeKey;
    end;

    procedure GetThreeKey(): Boolean
    begin
        exit(ThreeKey);
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
//   For a cell on the three-field key (Mode.GetThreeKey()), startx, fxa, fxc and txb act on GRK X3 instead of GRK X.
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
        X3A: Record "GRK X3";
        X3B: Record "GRK X3";
        X3C: Record "GRK X3";
        Step: Text;
    begin
        foreach Step in Mode.Get().Split(',') do
            if Mode.GetThreeKey() and (Step in ['startx', 'fxa', 'fxc', 'txb']) then
                case Step of
                    'startx':
                        StartX3();
                    'fxa':
                        X3A.Consistent(false);
                    'fxc':
                        X3C.Consistent(false);
                    'txb':
                        X3B.Consistent(true);
                end
            else
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

    local procedure StartX3()
    var
        X3: Record "GRK X3";
    begin
        X3.Init();
        X3."Activity Type" := X3."Activity Type"::Pick;
        X3."No." := '50';
        X3."Line No." := 10000;
        X3.Name := 'state';
        X3.Insert();
        X3.Consistent(false);
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


// The inner codeunit for a record of GRK X3. It logs the filter state of its argument.
codeunit 99549 "GRK Inner X3"
{
    TableNo = "GRK X3";

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


// The inner codeunit for a record of GRK Z3. It logs the filter state of its argument.
codeunit 99550 "GRK Inner Z3"
{
    TableNo = "GRK Z3";

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
        X3: Record "GRK X3";
        Z3: Record "GRK Z3";
        G: Integer;
    begin
        X.Consistent(true);
        Y.Consistent(true);
        Z.Consistent(true);
        X3.Consistent(true);
        Z3.Consistent(true);
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
        X3.DeleteAll();
        Z3.DeleteAll();
        InsertRow3(X3, Z3, X3."Activity Type"::"Put-away", '1', 10000, 'caller', 'S1');
        InsertRow3(X3, Z3, X3."Activity Type"::"Put-away", '1', 20000, 'line2', 'S1');
        InsertRow3(X3, Z3, X3."Activity Type"::Pick, '1', 10000, 'twin', 'S1');
        InsertRow3(X3, Z3, X3."Activity Type"::"Put-away", '2', 10000, 'other', 'S2');
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

    local procedure InsertRow3(var X3: Record "GRK X3"; var Z3: Record "GRK Z3"; ActivityType: Option; No: Code[20]; LineNo: Integer; NewName: Text[30]; SourceNo: Code[20])
    begin
        X3.Init();
        X3."Activity Type" := ActivityType;
        X3."No." := No;
        X3."Line No." := LineNo;
        X3."Source Type" := 39;
        X3."Source No." := SourceNo;
        X3.Name := NewName;
        X3.Insert();
        Z3.Init();
        Z3.TransferFields(X3);
        Z3.Insert();
    end;

    local procedure Rows(): Text
    var
        X: Record "GRK X";
        Y: Record "GRK Y";
        Z: Record "GRK Z";
        X3: Record "GRK X3";
        Z3: Record "GRK Z3";
        X3Names: Text;
        Z3Names: Text;
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
        if X3.FindSet() then
            repeat
                X3Names += X3.Name + ';';
            until X3.Next() = 0;
        if Z3.FindSet() then
            repeat
                Z3Names += Z3.Name + ';';
            until Z3.Next() = 0;
        exit('x=[' + XNames + '] y=[' + YNames + '] z=[' + ZNames + '] x3=[' + X3Names + '] z3=[' + Z3Names + ']');
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    // Runs the inner codeunit. Kind: z, x = a database record of GRK Z / X; z3, x3 = of GRK Z3 / X3. The argument is on the row
    // 'caller'.
    local procedure RunRec(Kind: Text; Shape: Text; var ArgName: Text; var ArgState: Text) Ok: Boolean
    var
        X: Record "GRK X";
        Z: Record "GRK Z";
        X3: Record "GRK X3";
        Z3: Record "GRK Z3";
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
            'z3':
                begin
                    PrepareZ3(Z3, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRK Inner Z3", Z3);
                    ArgName := Z3.Name;
                    RecRef.GetTable(Z3);
                    ArgState := Mode.Describe(RecRef, Z3.FilterGroup());
                end;
            'x3':
                begin
                    PrepareX3(X3, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRK Inner X3", X3);
                    ArgName := X3.Name;
                    RecRef.GetTable(X3);
                    ArgState := Mode.Describe(RecRef, X3.FilterGroup());
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

    local procedure PrepareX3(var R: Record "GRK X3"; Shape: Text)
    begin
        case Shape of
            'KeyCode3':
                begin
                    R.SetRange("No.", '1');
                end;
            'ThreeKey3':
                begin
                    R.SetRange("Source Type", 39); R.SetRange("Source No.", 'S1'); R.SetRange("Activity Type", R."Activity Type"::"Put-away");
                end;
        end;
        R.FindFirst();
    end;

    local procedure PrepareZ3(var R: Record "GRK Z3"; Shape: Text)
    begin
        case Shape of
            'KeyCode3':
                begin
                    R.SetRange("No.", '1');
                end;
            'ThreeKey3':
                begin
                    R.SetRange("Source Type", 39); R.SetRange("Source No.", 'S1'); R.SetRange("Activity Type", R."Activity Type"::"Put-away");
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
        Mode.SetThreeKey(Kind in ['z3', 'x3']);
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
        X3: Record "GRK X3";
        Z3: Record "GRK Z3";
        Res: Text;
        G: Integer;
    begin
        Res := 'x count=' + Format(X.Count()) + ' z count=' + Format(Z.Count()) + ' x3 count=' + Format(X3.Count()) + ' z3 count=' + Format(Z3.Count()) + ' z fg=' + Format(Z.FilterGroup());
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
    procedure RecZ_NoFilter3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_NoFilter3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'NoFilter3', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_KeyCode3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'KeyCode3', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecZ_ThreeKey3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z3', 'ThreeKey3', 'fxa,txb,fxc,fya,err');
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

    [Test]
    procedure RecX_NoFilter3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_NoFilter3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'NoFilter3', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_KeyCode3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'KeyCode3', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'startx,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'startx,fya');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'fxa,fya,commit');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_MarkedAgain()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'startx,fya,fyc,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_ReleasedThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'startx,txb,fya,err');
        Observer.Finish();
    end;

    [Test]
    procedure RecX_ThreeKey3_AgainThenHeld()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x3', 'ThreeKey3', 'fxa,txb,fxc,fya,err');
        Observer.Finish();
    end;
}
