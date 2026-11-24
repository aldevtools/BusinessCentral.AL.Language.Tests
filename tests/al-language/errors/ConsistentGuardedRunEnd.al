// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 75779-75788 (GRC Row, GRC Other, GRC Captioned, GRC Mode, GRC State,
//   GRC Inner, GRC Inner Rec, GRC Nothing, GRC Outer, GRC Tests)
// Probe: from al-runner issue 8970 (posting preview: the posting codeunit marks a table with Consistent(false) inside a guarded
//   Codeunit.Run and then fails on purpose; the run returns false and the caller goes on).
// Area: what a guarded Codeunit.Run does at its end while Consistent(false) marks a table. Neighbors of ConsistentGuardedRun.al:
//   - the inner codeunit marks the table and fails: with Error('text'), Error(''), a failed Get, a failed TestField; with the four
//     call forms Codeunit.Run(Id), Codeunit.Run(Id, Rec), CodeunitVar.Run(), CodeunitVar.Run(Rec); the mark set from a local
//     variable of a SingleInstance codeunit (the preview state shape), from a codeunit global (the G/L Entry shape), on another
//     table without a write, on two tables, on a table with a caption, on a temporary record;
//   - the inner codeunit succeeds: marks and unmarks the same variable, marks and "unmarks" with another variable, marks twice,
//     marks two tables (which one the error names), marks a table with a caption, marks a temporary record;
//   - the caller marks before the run, with the record argument forms and the error code;
//   - Commit after Consistent(true) on another variable, and Consistent on a temporary record;
//   - the preview flow: an outer guarded run whose CommitBehavior::Error procedure runs the inner codeunit, then Error('').
// Measured on BC 29.0 (local container, both test runners); 27.5 and 28.5 by the corpus CI:
//   - When the inner codeunit fails, the guarded run returns false with the inner error (text and code), whatever it marked: the
//     mark ends with the run's rolled back transaction. A Commit after it succeeds and a second guarded run returns Yes.
//   - When the inner codeunit succeeds with a mark still set, the guarded run raises DB:TableInConsistent (not trapped). The error
//     names the table that was marked first, and a table's caption, not its name.
//   - Consistent(true) lifts a mark only on the variable that set it. Consistent(true) on another variable of the table, also when
//     the marking variable is gone, leaves the mark: the next Commit or guarded run raises.
//   - Consistent(false) on a temporary record marks the database table: a Commit raises the error of that table, and Consistent(true)
//     on the same temporary variable lifts it.
//   - A mark the caller sets before the run raises at the end of the run with the record argument forms too (code DB:TableInConsistent).
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunits are the code under test.
// The values are what BC produced.
// BC versions: 27.5, 28.5, 29.0

table 75779 "GRC Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75780 "GRC Other"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Code; Code[10]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 75781 "GRC Captioned"
{
    Caption = 'GRC Caption Text';
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// The steps the inner codeunits run, set by the test before the run (a guarded Codeunit.Run(Id) gets a new instance).
codeunit 75782 "GRC Mode"
{
    SingleInstance = true;

    var
        Steps: Text;

    procedure Set(NewSteps: Text)
    begin
        Steps := NewSteps;
    end;

    procedure Get(): Text
    begin
        exit(Steps);
    end;
}

// The preview-state shape: Start inserts a row and marks the table from a local variable of a procedure (the variable is gone when the
// procedure returns); Stop deletes the row and calls Consistent(true) on another, new variable.
codeunit 75783 "GRC State"
{
    SingleInstance = true;

    var
        StateId: Integer;

    procedure Start()
    var
        Row: Record "GRC Row";
    begin
        Row.Init();
        Row.Id := 0;
        Row.Name := 'state';
        Row.Insert();
        Row.Consistent(false);
        StateId := Row.Id;
    end;

    procedure Stop()
    var
        Row: Record "GRC Row";
    begin
        if StateId <> 0 then
            if Row.Get(StateId) then
                Row.Delete();
        StateId := 0;
        Row.Consistent(true);
    end;

    procedure Reset()
    begin
        StateId := 0;
    end;
}

// The inner codeunit: runs the steps of "GRC Mode", comma separated. Marker is a global record (the G/L Entry shape of a posting codeunit).
codeunit 75784 "GRC Inner"
{
    trigger OnRun()
    begin
        DoSteps();
    end;

    var
        Marker: Record "GRC Row";

    procedure DoSteps()
    var
        Mode: Codeunit "GRC Mode";
        State: Codeunit "GRC State";
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        Captioned: Record "GRC Captioned";
        TempRow: Record "GRC Row" temporary;
        Step: Text;
    begin
        foreach Step in Mode.Get().Split(',') do
            case Step of
                'start':
                    State.Start();
                'stop':
                    State.Stop();
                'markg':
                    Marker.Consistent(false);
                'unmarkg':
                    Marker.Consistent(true);
                'markl':
                    Row.Consistent(false);
                'ins':
                    begin
                        Row.Init();
                        Row.Id := 0;
                        Row.Name := 'inner';
                        Row.Insert();
                    end;
                'insother':
                    begin
                        Other.Init();
                        Other.Id := 5;
                        Other.Insert();
                    end;
                'markother':
                    begin
                        Other.Init();
                        Other.Consistent(false);
                    end;
                'markcap':
                    Captioned.Consistent(false);
                'marktemp':
                    TempRow.Consistent(false);
                'err':
                    Error('inner failed');
                'err0':
                    Error('');
                'get':
                    Other.Get(999);
                'testfield':
                    begin
                        Other.Init();
                        Other.TestField(Code);
                    end;
            end;
    end;

    procedure UnmarkGlobal()
    begin
        Marker.Consistent(true);
    end;
}

// The same steps with a record argument (TableNo); the steps run on a codeunit global of this instance.
codeunit 75785 "GRC Inner Rec"
{
    TableNo = "GRC Other";

    trigger OnRun()
    begin
        Inner.DoSteps();
    end;

    var
        Inner: Codeunit "GRC Inner";

    procedure UnmarkGlobal()
    begin
        Inner.UnmarkGlobal();
    end;
}

codeunit 75786 "GRC Nothing"
{
    trigger OnRun()
    begin
    end;
}

// The preview flow: the run inside a CommitBehavior::Error procedure, then Stop, then Error('').
codeunit 75787 "GRC Outer"
{
    trigger OnRun()
    begin
        PreviewStart();
        Error('');
    end;

    var
        InnerResult: Boolean;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure PreviewStart()
    var
        State: Codeunit "GRC State";
        Inner: Codeunit "GRC Inner";
    begin
        InnerResult := Inner.Run();
        State.Stop();
    end;
}

codeunit 75788 "GRC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize(Steps: Text)
    var
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        Mode: Codeunit "GRC Mode";
        State: Codeunit "GRC State";
    begin
        Row.Consistent(true);
        Row.DeleteAll();
        Other.DeleteAll();
        Commit();
        ClearLastError();
        State.Reset();
        Mode.Set(Steps);
    end;

    local procedure Rows(): Text
    var
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        Names: Text;
    begin
        if Row.FindSet() then
            repeat
                Names += Row.Name + ';';
            until Row.Next() = 0;
        exit('[' + Names + '] other=' + Format(Other.Count()));
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    local procedure Preview()
    var
        Outer: Codeunit "GRC Outer";
    begin
        Outer.Run();
    end;

    // ---- the inner codeunit marks the table and fails: the base shape and its call forms ----

    [Test]
    procedure GuardedRunId_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('rows after run', '[] other=0');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerStartsStateAndFails_StopThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "GRC State";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        State.Stop();
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerStartsStateAndFails_ThenGuardedRunNothing()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Ok2: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Ok2 := Codeunit.Run(Codeunit::"GRC Nothing");
        Observer.Observe('second run', Format(Ok2));
        Observer.ObserveError('second last error');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('second run', 'Yes');
        Observer.Expect('second last error|text', '');
        Observer.Expect('second last error|code', '');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunIdRec_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner Rec", Other);
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('rows after run', '[] other=0');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstance_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Codeunit "GRC Inner";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Inner.Run();
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('rows after run', '[] other=0');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstanceRec_InnerStartsStateAndFails_StopThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        InnerRec: Codeunit "GRC Inner Rec";
        State: Codeunit "GRC State";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := InnerRec.Run(Other);
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        State.Stop();
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('rows after run', '[] other=0');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstanceRec_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
        InnerRec: Codeunit "GRC Inner Rec";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := InnerRec.Run(Other);
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    // ---- the kind of error that ends the inner codeunit ----

    [Test]
    procedure GuardedRunId_InnerStartsStateAndErrorsEmpty()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,ins,err0');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', '');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerStartsStateAndGetFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,ins,get');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'The GRC Other does not exist. Identification fields and values: Id=''999''');
        Observer.Expect('last error|code', 'DB:RecordNotFound');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerStartsStateAndTestFieldFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,ins,testfield');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'Code must have a value in GRC Other: Id=0. It cannot be zero or empty.');
        Observer.Expect('last error|code', 'TestField');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    // ---- other marks the inner codeunit sets before it fails ----

    [Test]
    procedure GuardedRunId_InnerMarksLocalWritesNothingAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markl,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksOtherTableInsertsRowAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markother,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksTwoTablesAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,markother,insother,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksGlobalTwiceAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markg,ins,markg,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksAndUnmarksGlobalAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markg,ins,unmarkg,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksCaptionedTableAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markcap,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksTemporaryAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('marktemp,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    // ---- a codeunit global that set the mark is still there after the run ----

    [Test]
    procedure GuardedRunInstance_InnerMarksGlobalAndFails_ThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Codeunit "GRC Inner";
        Ok: Boolean;
    begin
        Initialize('markg,ins,err');
        Ok := Inner.Run();
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstance_InnerMarksGlobalAndFails_UnmarkThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        Inner: Codeunit "GRC Inner";
        Ok: Boolean;
    begin
        Initialize('markg,ins,err');
        Ok := Inner.Run();
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Inner.UnmarkGlobal();
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstanceRec_InnerMarksGlobalAndFails_ThenCommit()
    var
        Observer: Codeunit "Probe Observer";
        InnerRec: Codeunit "GRC Inner Rec";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('markg,ins,err');
        Ok := InnerRec.Run(Other);
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    // ---- the inner codeunit succeeds ----

    [Test]
    procedure GuardedRunId_InnerMarksAndUnmarksGlobal_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markg,ins,unmarkg');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'Yes');
        Observer.Expect('last error|text', '');
        Observer.Expect('last error|code', '');
        Observer.Expect('durable rows', '[inner;] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerStartsAndStopsState_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('start,ins,stop');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksGlobalTwice_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markg,ins,markg');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunIdRec_InnerStartsState_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('start,ins');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner Rec", Other);
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksRowThenOther_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markl,markother,ins');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksOtherThenRow_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markother,markl,ins');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Other table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksCaptioned_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('markcap,ins');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Caption Text table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_InnerMarksTemporary_Succeeds()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize('marktemp,ins');
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    // ---- the caller marks the table before the run ----

    [Test]
    procedure GuardedRunIdRec_CallerMarks_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('ins,err');
        Row.Consistent(false);
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner Rec", Other);
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunIdRec_CallerMarks_InnerSucceeds()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        Ok: Boolean;
    begin
        Initialize('ins');
        Row.Consistent(false);
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner Rec", Other);
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunInstanceRec_CallerMarks_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "GRC Row";
        Other: Record "GRC Other";
        InnerRec: Codeunit "GRC Inner Rec";
        Ok: Boolean;
    begin
        Initialize('ins,err');
        Row.Consistent(false);
        asserterror Ok := InnerRec.Run(Other);
        Observer.ObserveError('guarded run');
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_CallerMarks_InnerFails_ErrorCode()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "GRC Row";
        Ok: Boolean;
    begin
        Initialize('ins,err');
        Row.Consistent(false);
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_CallerStartsState_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "GRC State";
        Ok: Boolean;
    begin
        Initialize('ins,err');
        State.Start();
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_CallerStartsAndStopsState_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "GRC State";
        Ok: Boolean;
    begin
        Initialize('ins,err');
        State.Start();
        State.Stop();
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_CallerMarksCaptioned_InnerSucceeds()
    var
        Observer: Codeunit "Probe Observer";
        Captioned: Record "GRC Captioned";
        Ok: Boolean;
    begin
        Initialize('ins');
        Captioned.Consistent(false);
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Caption Text table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_CallerMarksCaptioned()
    var
        Observer: Codeunit "Probe Observer";
        Captioned: Record "GRC Captioned";
    begin
        Initialize('');
        Captioned.Consistent(false);
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Expect('commit|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Caption Text table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('commit|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_CallerMarksTemporary()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "GRC Row" temporary;
        Row: Record "GRC Row";
    begin
        Initialize('');
        TempRow.Consistent(false);
        Row.Init();
        Row.Name := 'caller';
        Row.Insert();
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('commit|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('commit|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRunId_CallerMarksTemporary_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "GRC Row" temporary;
        Ok: Boolean;
    begin
        Initialize('ins,err');
        TempRow.Consistent(false);
        asserterror Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.ObserveError('guarded run');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('guarded run|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('guarded run|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_TemporaryMarkedThenUnmarked()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "GRC Row" temporary;
        Row: Record "GRC Row";
    begin
        Initialize('');
        TempRow.Consistent(false);
        TempRow.Consistent(true);
        Row.Init();
        Row.Name := 'caller';
        Row.Insert();
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('durable rows', '[caller;] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_TemporaryMarked_DatabaseVariableUnmarks()
    var
        Observer: Codeunit "Probe Observer";
        TempRow: Record "GRC Row" temporary;
        Row: Record "GRC Row";
    begin
        Initialize('');
        TempRow.Consistent(false);
        Row.Consistent(true);
        Row.Init();
        Row.Name := 'caller';
        Row.Insert();
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('commit|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('commit|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_StateStartedAndStopped()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "GRC State";
    begin
        Initialize('');
        State.Start();
        State.Stop();
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('commit|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('commit|code', 'DB:TableInConsistent');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_FalseOnOneVariable_TrueOnAnother()
    var
        Observer: Codeunit "Probe Observer";
        Marker: Record "GRC Row";
        Unmarker: Record "GRC Row";
    begin
        Initialize('');
        Marker.Consistent(false);
        Unmarker.Consistent(true);
        asserterror Commit();
        Observer.ObserveError('commit');
        Observer.Expect('commit|text', 'The transaction cannot be completed because it will cause inconsistencies in the GRC Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Expect('commit|code', 'DB:TableInConsistent');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_FalseOnOneVariable_TrueOnAnother_ThenTrueOnFirst()
    var
        Observer: Codeunit "Probe Observer";
        Marker: Record "GRC Row";
        Unmarker: Record "GRC Row";
        Row: Record "GRC Row";
    begin
        Initialize('');
        Marker.Consistent(false);
        Unmarker.Consistent(true);
        Marker.Consistent(true);
        Row.Init();
        Row.Name := 'caller';
        Row.Insert();
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('durable rows', '[caller;] other=0');
        Observer.Verify();
    end;

    // ---- the preview flow: an outer guarded run, the inner run in a CommitBehavior::Error procedure, Stop, Error('') ----

    [Test]
    procedure Preview_OuterGuardedRun_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
        Outer: Codeunit "GRC Outer";
        Ok: Boolean;
    begin
        Initialize('start,ins,err');
        Ok := Outer.Run();
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', '');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Preview_AssertError_InnerStartsStateAndFails()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize('start,ins,err');
        asserterror Preview();
        Observer.ObserveError('preview');
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('preview|text', '');
        Observer.Expect('preview|code', 'Dialog');
        Observer.Expect('durable rows', '[] other=0');
        Observer.Verify();
    end;

    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure GuardedRunId_InnerStartsStateAndFails_AutoRollback()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "GRC State";
        Mode: Codeunit "GRC Mode";
        Ok: Boolean;
    begin
        // No Commit under AutoRollback: the earlier tests leave the tables empty.
        ClearLastError();
        State.Reset();
        Mode.Set('start,ins,err');
        Ok := Codeunit.Run(Codeunit::"GRC Inner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        State.Stop();
        Observer.Expect('run', 'No');
        Observer.Expect('last error|text', 'inner failed');
        Observer.Expect('last error|code', 'Dialog');
        Observer.Expect('rows after run', '[] other=0');
        Observer.Verify();
    end;
}
