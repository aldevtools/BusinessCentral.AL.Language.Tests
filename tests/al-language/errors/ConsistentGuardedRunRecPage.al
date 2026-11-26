// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-filtergroup-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 99525-99534 (GRP X, GRP Y, GRP Z, GRP Mode, GRP Steps, GRP Inner X,
//   GRP Inner Z, GRP List X, GRP List Z, GRP Tests)
// Probe: from al-runner issue 8970, page-style filters. Same shape as ConsistentGuardedRunRecFiltered.al (inner codeunit marks tables
//   with Consistent(false), then ends or fails), but the record argument of Codeunit.Run(Id, Rec) carries the filters a page puts on
//   its record: a filter in FilterGroup 2 (and 1, 4, 6), a range on a FlowFilter field, and a key filter, together or alone.
// Area: the cells (the guarded run under asserterror that ends in Error('END'); then a Commit in the caller; then the durable rows):
//   - Argument table: GRP Z (never marked) and GRP X (marked first by the step startx or fxa). Fields: Id (key), Name, Doc Type,
//     Amount, Date Filter (FlowFilter). Rows: Id 1 'caller' (Doc Type 1, Amount 5) and Id 2 'other' (Doc Type 2, Amount 50).
//   - Filter shapes: NoFilter; G2, G1, G4, G6 (SetRange on Doc Type in that FilterGroup, group 0 restored); G2Left (group 2 left as the
//     current group at the call); FlowRange (SetRange from..to on the FlowFilter), FlowFilterPat (SetFilter '..x'); NormalRange (SetRange
//     on Amount); G2Key (group 2 and a key range); G2FlowKey (group 2, FlowFilter range and key range: the page shape); Pipe (SetFilter
//     'caller|zzz' on Name); NotEqual (SetFilter '<>other' on Name); G2NotEqual (SetFilter '<>2' on Doc Type in group 2).
//   - Marks (steps of the inner codeunit): Fails = startx,fya,err (insert into GRP X and mark it, mark GRP Y, Error);
//     Ends = startx,fya (the inner codeunit ends holding marks); PlainCommit = fxa,fya,commit (mark GRP X and GRP Y, then Commit).
//   - Page cells (Page...): the argument is the Rec of a list page with SourceTableView Doc Type = 1; ViewId, ViewFlow and
//     ViewIdFlow add TestPage filters on Id and on Date Filter. The action runs Codeunit.Run(Id, Rec) and logs the same.
//   Each cell reads: the run's error, the log of the caller (inner codeunit's view of the argument: FilterGroup, GetFilters of group
//   0, 1, 2, 4, 6, filtered count; return value; last error text and code; the argument's Name; the same view of the argument after
//   the run), the error of a later Commit, and the rows that are durable. Every cell starts with two committed rows per table.
// What BC did (identical on 27.5, 28.5 and 29.0):
//   - Page cells: the inner codeunit sees the page view as a filter in FilterGroup 2 (Doc Type: 1), the TestPage Id and Date Filter
//     filters in group 0, and FilterGroup 0 current. Ends: the Codeunit.Run call raises the inconsistency error (TestWrapped:CSide);
//     Fails and PlainCommit: the run ends with the guarded error (TestWrapped:Dialog), the later Commit is not blocked, and all
//     rows of GRP X, GRP Y and GRP Z are durable.
//   - A group-1 filter on the record passed to Codeunit.Run stays on a fresh variable of that table in the same test (cell
//     RecZ_G1_Fails, expectation 'fresh record'); Reset on the fresh variable did not clear it. Initialize therefore clears the filter
//     groups 0..6 of the fixture records before every cell, so the cells do not depend on each other.
// The values are what BC produced.
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunit is the code under test.
// BC versions: 27.5, 28.5, 29.0

table 99525 "GRP X"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Doc Type"; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 99526 "GRP Y"
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

table 99527 "GRP Z"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; "Doc Type"; Integer) { }
        field(4; Amount; Decimal) { }
        field(5; "Date Filter"; Date) { FieldClass = FlowFilter; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The steps the inner codeunit runs, and a log the caller writes (a SingleInstance codeunit is not rolled back).
codeunit 99528 "GRP Mode"
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

// The step interpreter: runs the steps of "GRP Mode", comma separated.
//   startx: insert a row into GRP X and mark GRP X from the same local variable (the preview state shape).
//   fxa, fya: Consistent(false) on a local variable for GRP X, GRP Y. commit: Commit. err: Error('inner failed').
codeunit 99529 "GRP Steps"
{
    procedure DoSteps()
    var
        Mode: Codeunit "GRP Mode";
        XA: Record "GRP X";
        YA: Record "GRP Y";
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
                'commit':
                    Commit();
                'err':
                    Error('inner failed');
            end;
    end;

    local procedure StartX()
    var
        X: Record "GRP X";
    begin
        X.Init();
        X.Id := 50;
        X.Name := 'state';
        X.Insert();
        X.Consistent(false);
    end;
}


// The inner codeunit for a record of GRP X. It logs the filter state of its argument.
codeunit 99530 "GRP Inner X"
{
    TableNo = "GRP X";

    trigger OnRun()
    var
        Steps: Codeunit "GRP Steps";
        Mode: Codeunit "GRP Mode";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Mode.Log('inner ' + Mode.Describe(RecRef, Rec.FilterGroup()));
        Steps.DoSteps();
    end;
}


// The inner codeunit for a record of GRP Z. It logs the filter state of its argument.
codeunit 99531 "GRP Inner Z"
{
    TableNo = "GRP Z";

    trigger OnRun()
    var
        Steps: Codeunit "GRP Steps";
        Mode: Codeunit "GRP Mode";
        RecRef: RecordRef;
    begin
        RecRef.GetTable(Rec);
        Mode.Log('inner ' + Mode.Describe(RecRef, Rec.FilterGroup()));
        Steps.DoSteps();
    end;
}


page 99532 "GRP List X"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "GRP X";
    SourceTableView = where("Doc Type" = const(1));

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Doc Type"; Rec."Doc Type") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Date Filter"; Rec."Date Filter") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunInner)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mode: Codeunit "GRP Mode";
                    RecRef: RecordRef;
                    Ok: Boolean;
                begin
                    Ok := Codeunit.Run(Codeunit::"GRP Inner X", Rec);
                    RecRef.GetTable(Rec);
                    Mode.Log('run=' + Format(Ok));
                    Mode.Log('text=' + GetLastErrorText());
                    Mode.Log('code=' + GetLastErrorCode());
                    Mode.Log('arg=' + Rec.Name);
                    Mode.Log('argstate ' + Mode.Describe(RecRef, Rec.FilterGroup()));
                    ClearLastError();
                    Error('END');
                end;
            }
        }
    }
}


page 99533 "GRP List Z"
{
    PageType = List;
    ApplicationArea = All;
    UsageCategory = None;
    SourceTable = "GRP Z";
    SourceTableView = where("Doc Type" = const(1));

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
                field("Doc Type"; Rec."Doc Type") { ApplicationArea = All; }
                field(Amount; Rec.Amount) { ApplicationArea = All; }
                field("Date Filter"; Rec."Date Filter") { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(RunInner)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Mode: Codeunit "GRP Mode";
                    RecRef: RecordRef;
                    Ok: Boolean;
                begin
                    Ok := Codeunit.Run(Codeunit::"GRP Inner Z", Rec);
                    RecRef.GetTable(Rec);
                    Mode.Log('run=' + Format(Ok));
                    Mode.Log('text=' + GetLastErrorText());
                    Mode.Log('code=' + GetLastErrorCode());
                    Mode.Log('arg=' + Rec.Name);
                    Mode.Log('argstate ' + Mode.Describe(RecRef, Rec.FilterGroup()));
                    ClearLastError();
                    Error('END');
                end;
            }
        }
    }
}


codeunit 99534 "GRP Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Codeunit "GRP Mode";

    // Every cell starts with two committed rows in each table: Id 1 'caller' and Id 2 'other'. The run gets the first one.
    local procedure Initialize(Steps: Text)
    var
        X: Record "GRP X";
        Y: Record "GRP Y";
        Z: Record "GRP Z";
        G: Integer;
    begin
        X.Consistent(true);
        Y.Consistent(true);
        Z.Consistent(true);
        X.Reset();
        Y.Reset();
        Z.Reset();
        for G := 0 to 6 do begin
            X.FilterGroup(G);
            X.SetRange("Doc Type");
            Z.FilterGroup(G);
            Z.SetRange("Doc Type");
        end;
        X.FilterGroup(0);
        Z.FilterGroup(0);
        X.DeleteAll();
        Y.DeleteAll();
        Z.DeleteAll();
        X.Init();
        X.Id := 1;
        X.Name := 'caller';
        X."Doc Type" := 1;
        X.Amount := 5;
        X.Insert();
        X.Id := 2;
        X.Name := 'other';
        X."Doc Type" := 2;
        X.Amount := 50;
        X.Insert();
        Y.Init();
        Y.Id := 1;
        Y.Name := 'caller';
        Y.Insert();
        Y.Id := 2;
        Y.Name := 'other';
        Y.Insert();
        Z.Init();
        Z.Id := 1;
        Z.Name := 'caller';
        Z."Doc Type" := 1;
        Z.Amount := 5;
        Z.Insert();
        Z.Id := 2;
        Z.Name := 'other';
        Z."Doc Type" := 2;
        Z.Amount := 50;
        Z.Insert();
        Commit();
        ClearLastError();
        Mode.Set(Steps);
    end;

    local procedure Rows(): Text
    var
        X: Record "GRP X";
        Y: Record "GRP Y";
        Z: Record "GRP Z";
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

    // Runs the inner codeunit. Kind: z, x = a database record of GRP Z / X. The argument is on the row 'caller'.
    local procedure RunRec(Kind: Text; Shape: Text; var ArgName: Text; var ArgState: Text) Ok: Boolean
    var
        X: Record "GRP X";
        Z: Record "GRP Z";
        RecRef: RecordRef;
    begin
        case Kind of
            'z':
                begin
                    PrepareZ(Z, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRP Inner Z", Z);
                    ArgName := Z.Name;
                    RecRef.GetTable(Z);
                    ArgState := Mode.Describe(RecRef, Z.FilterGroup());
                end;
            'x':
                begin
                    PrepareX(X, Shape);
                    Ok := Codeunit.Run(Codeunit::"GRP Inner X", X);
                    ArgName := X.Name;
                    RecRef.GetTable(X);
                    ArgState := Mode.Describe(RecRef, X.FilterGroup());
                end;
        end;
    end;


    local procedure PrepareX(var R: Record "GRP X"; Shape: Text)
    begin
        case Shape of
            'G2':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G2Left':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1);
                end;
            'G1':
                begin
                    R.FilterGroup(1); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G4':
                begin
                    R.FilterGroup(4); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G6':
                begin
                    R.FilterGroup(6); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'FlowRange':
                begin
                    R.SetRange("Date Filter", DMY2Date(1, 1, 2025), DMY2Date(31, 12, 2025));
                end;
            'FlowFilterPat':
                begin
                    R.SetFilter("Date Filter", '..%1', DMY2Date(31, 12, 2025));
                end;
            'NormalRange':
                begin
                    R.SetRange(Amount, 0, 10);
                end;
            'G2Key':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0); R.SetRange(Id, 1);
                end;
            'G2FlowKey':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0); R.SetRange("Date Filter", DMY2Date(1, 1, 2025), DMY2Date(31, 12, 2025)); R.SetRange(Id, 1);
                end;
            'Pipe':
                begin
                    R.SetFilter(Name, 'caller|zzz');
                end;
            'NotEqual':
                begin
                    R.SetFilter(Name, '<>other');
                end;
            'G2NotEqual':
                begin
                    R.FilterGroup(2); R.SetFilter("Doc Type", '<>2'); R.FilterGroup(0);
                end;
        end;
        R.FindFirst();
    end;

    local procedure PrepareZ(var R: Record "GRP Z"; Shape: Text)
    begin
        case Shape of
            'G2':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G2Left':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1);
                end;
            'G1':
                begin
                    R.FilterGroup(1); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G4':
                begin
                    R.FilterGroup(4); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'G6':
                begin
                    R.FilterGroup(6); R.SetRange("Doc Type", 1); R.FilterGroup(0);
                end;
            'FlowRange':
                begin
                    R.SetRange("Date Filter", DMY2Date(1, 1, 2025), DMY2Date(31, 12, 2025));
                end;
            'FlowFilterPat':
                begin
                    R.SetFilter("Date Filter", '..%1', DMY2Date(31, 12, 2025));
                end;
            'NormalRange':
                begin
                    R.SetRange(Amount, 0, 10);
                end;
            'G2Key':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0); R.SetRange(Id, 1);
                end;
            'G2FlowKey':
                begin
                    R.FilterGroup(2); R.SetRange("Doc Type", 1); R.FilterGroup(0); R.SetRange("Date Filter", DMY2Date(1, 1, 2025), DMY2Date(31, 12, 2025)); R.SetRange(Id, 1);
                end;
            'Pipe':
                begin
                    R.SetFilter(Name, 'caller|zzz');
                end;
            'NotEqual':
                begin
                    R.SetFilter(Name, '<>other');
                end;
            'G2NotEqual':
                begin
                    R.FilterGroup(2); R.SetFilter("Doc Type", '<>2'); R.FilterGroup(0);
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
        X: Record "GRP X";
        Z: Record "GRP Z";
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

    local procedure PageCell(var Observer: Codeunit "Probe Observer"; Kind: Text; Variant: Text; Steps: Text)
    var
        TPX: TestPage "GRP List X";
        TPZ: TestPage "GRP List Z";
    begin
        Initialize(Steps);
        if Kind = 'x' then begin
            TPX.OpenView();
            case Variant of
                'ViewId':
                    TPX.Filter.SetFilter(Id, '1');
                'ViewFlow':
                    TPX.Filter.SetFilter("Date Filter", '..' + Format(DMY2Date(31, 12, 2025)));
                'ViewIdFlow':
                    begin
                        TPX.Filter.SetFilter(Id, '1');
                        TPX.Filter.SetFilter("Date Filter", '..' + Format(DMY2Date(31, 12, 2025)));
                    end;
            end;
            asserterror TPX.RunInner.Invoke();
            Observer.ObserveError('run end');
            TPX.Close();
        end else begin
            TPZ.OpenView();
            case Variant of
                'ViewId':
                    TPZ.Filter.SetFilter(Id, '1');
                'ViewFlow':
                    TPZ.Filter.SetFilter("Date Filter", '..' + Format(DMY2Date(31, 12, 2025)));
                'ViewIdFlow':
                    begin
                        TPZ.Filter.SetFilter(Id, '1');
                        TPZ.Filter.SetFilter("Date Filter", '..' + Format(DMY2Date(31, 12, 2025)));
                    end;
            end;
            asserterror TPZ.RunInner.Invoke();
            Observer.ObserveError('run end');
            TPZ.Close();
        end;
        Observer.Observe('log', Mode.GetLog());
        asserterror CommitThenEnd();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
    end;


    [Test]
    procedure RecZ_NoFilter_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NoFilter_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NoFilter_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NoFilter', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Left_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Left', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Left_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Left', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Left_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Left', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G1_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G1', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;]');
        Observer.Expect('fresh record', 'x count=2 z count=1 z fg=0 g0=[] g1=[Doc Type: 1] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G1_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G1', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;]');
        Observer.Expect('fresh record', 'x count=2 z count=1 z fg=0 g0=[] g1=[Doc Type: 1] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G1_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G1', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;]');
        Observer.Expect('fresh record', 'x count=2 z count=1 z fg=0 g0=[] g1=[Doc Type: 1] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G4_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G4', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G4_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G4', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G4_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G4', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G6_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G6', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G6_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G6', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G6_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G6', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowRange_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowRange', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowRange_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowRange', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowRange_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowRange', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowFilterPat_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowFilterPat', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowFilterPat_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowFilterPat', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_FlowFilterPat_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'FlowFilterPat', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NormalRange_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NormalRange', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NormalRange_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NormalRange', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NormalRange_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NormalRange', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Key_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Key', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Key_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Key', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2Key_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2Key', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2FlowKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2FlowKey', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2FlowKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2FlowKey', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2FlowKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2FlowKey', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_Pipe_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Pipe', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_Pipe_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Pipe', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_Pipe_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'Pipe', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NotEqual_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NotEqual', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NotEqual_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NotEqual', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_NotEqual_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'NotEqual', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2NotEqual_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2NotEqual', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2NotEqual_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2NotEqual', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecZ_G2NotEqual_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'z', 'G2NotEqual', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NoFilter_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NoFilter_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NoFilter_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NoFilter', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Left_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Left', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Left_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Left', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Left_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Left', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=2 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G1_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G1', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=1 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G1_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G1', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=1 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G1_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G1', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[Doc Type: 1] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=1 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G4_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G4', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G4_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G4', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G4_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G4', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[Doc Type: 1] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G6_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G6', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G6_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G6', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G6_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G6', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[] g4=[] g6=[Doc Type: 1] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowRange_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowRange', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowRange_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowRange', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowRange_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowRange', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: 01/01/25..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowFilterPat_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowFilterPat', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowFilterPat_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowFilterPat', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_FlowFilterPat_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'FlowFilterPat', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[] g4=[] g6=[] count=2;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NormalRange_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NormalRange', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NormalRange_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NormalRange', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NormalRange_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NormalRange', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Amount: 0..10] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Key_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Key', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Key_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Key', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2Key_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2Key', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2FlowKey_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2FlowKey', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2FlowKey_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2FlowKey', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2FlowKey_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2FlowKey', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: 01/01/25..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_Pipe_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Pipe', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_Pipe_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Pipe', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_Pipe_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'Pipe', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Name: caller|zzz] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NotEqual_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NotEqual', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NotEqual_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NotEqual', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_NotEqual_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'NotEqual', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Name: <>other] g1=[] g2=[] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2NotEqual_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2NotEqual', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2NotEqual_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2NotEqual', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'DB:TableInConsistent');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure RecX_G2NotEqual_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RecCell(Observer, 'x', 'G2NotEqual', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: <>2] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Expect('fresh record', 'x count=2 z count=2 z fg=0 g0=[] g1=[] g2=[] g3=[] g4=[] g5=[] g6=[]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_View_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'View', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_View_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'View', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_View_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'View', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewId_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewId', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewId_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewId', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewId_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewId', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewFlow_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewFlow', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewFlow_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewFlow', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewFlow_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewFlow', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewIdFlow_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewIdFlow', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewIdFlow_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewIdFlow', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageZ_ViewIdFlow_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'z', 'ViewIdFlow', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_View_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'View', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_View_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'View', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_View_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'View', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewId_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewId', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewId_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewId', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewId_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewId', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewFlow_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewFlow', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewFlow_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewFlow', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewFlow_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewFlow', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewIdFlow_Fails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewIdFlow', 'startx,fya,err');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=inner failed;code=Dialog;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewIdFlow_Ends()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewIdFlow', 'startx,fya');
        Observer.Expect('run end|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('run end|code', 'TestWrapped:CSide');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;

    [Test]
    procedure PageX_ViewIdFlow_PlainCommit()
    var
        Observer: Codeunit "Probe Observer";
    begin
        PageCell(Observer, 'x', 'ViewIdFlow', 'fxa,fya,commit');
        Observer.Expect('run end|text', 'END');
        Observer.Expect('run end|code', 'TestWrapped:Dialog');
        Observer.Expect('log', 'inner fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;run=No;text=The transaction cannot be completed because it will cause inconsistencies in the GRP X table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.;code=DB:TableInConsistent;arg=caller;argstate fg=0 g0=[Id: 1, Date Filter: ..12/31/25] g1=[] g2=[Doc Type: 1] g4=[] g6=[] count=1;');
        Observer.Expect('commit|text', 'END');
        Observer.Expect('commit|code', 'Dialog');
        Observer.Expect('durable rows', 'x=[caller;other;] y=[caller;other;] z=[caller;other;]');
        Observer.Verify();
    end;
}
