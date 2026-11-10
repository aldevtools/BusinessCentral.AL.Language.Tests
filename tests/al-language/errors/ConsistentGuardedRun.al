// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-consistent-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own objects 97436-97444 (ERR Consist Row, ERR Consist Other, six inner codeunits,
//   ERR Consist Run Tests)
// Probe: from al-runner issue 7586 item 4 (Consistent(false), then a guarded Codeunit.Run, then Consistent(true); met in Microsoft's
//   test apps).
// Area: a table marked with Consistent(false) while a guarded Codeunit.Run ends a transaction. A guarded run that succeeds commits.
//   - the caller marks the table, the inner codeunit: inserts into the marked table, inserts into another table only, writes nothing,
//     inserts and then fails;
//   - the inner codeunit marks the table itself and inserts (and the same with Consistent(true) before it ends);
//   - the mark is set on one variable and taken back on another variable of the same table before the run;
//   - the run is not guarded (a statement), then Consistent(true) and Commit;
//   - after a guarded run that inserted, the caller writes once more and calls Commit without Consistent(true).
//   Each test reads what the guarded run returned, the last error text and code, and the rows that are still there after an unrelated
//   error (the rows a commit made durable).
//   A test whose guarded run raises instead of returning false fails with that error: the failure is the reading.
// Already pinned elsewhere, not repeated: Consistent(false) then Commit, and Consistent(false), Consistent(true), Commit
//   (CuCommitTests.al, Consistent_False_ThenCommit and Consistent_FalseThenTrue_ThenCommit); the commit of a guarded Codeunit.Run
//   without a mark (CuCommitTests.al, item 36).
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunits are the code under test.
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)

table 97436 "ERR Consist Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 97437 "ERR Consist Other"
{
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

codeunit 97438 "ERR Consist Insert"
{
    trigger OnRun()
    var
        Row: Record "ERR Consist Row";
    begin
        Row.Init();
        Row.Id := 77;
        Row.Insert();
    end;
}

codeunit 97439 "ERR Consist Insert Other"
{
    trigger OnRun()
    var
        Other: Record "ERR Consist Other";
    begin
        Other.Init();
        Other.Id := 1;
        Other.Insert();
    end;
}

codeunit 97440 "ERR Consist Nothing"
{
    trigger OnRun()
    begin
    end;
}

codeunit 97441 "ERR Consist Insert Fail"
{
    trigger OnRun()
    var
        Row: Record "ERR Consist Row";
    begin
        Row.Init();
        Row.Id := 78;
        Row.Insert();
        Error('inner failed');
    end;
}

codeunit 97442 "ERR Consist Mark Insert"
{
    trigger OnRun()
    var
        Row: Record "ERR Consist Row";
    begin
        Row.Consistent(false);
        Row.Init();
        Row.Id := 88;
        Row.Insert();
    end;
}

codeunit 97443 "ERR Consist Mark Unmark"
{
    trigger OnRun()
    var
        Row: Record "ERR Consist Row";
    begin
        Row.Consistent(false);
        Row.Init();
        Row.Id := 89;
        Row.Insert();
        Row.Consistent(true);
    end;
}

codeunit 97444 "ERR Consist Run Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "ERR Consist Row";
        Other: Record "ERR Consist Other";
    begin
        Row.Consistent(true);
        Row.DeleteAll();
        Other.DeleteAll();
        Commit();
        ClearLastError();
    end;

    local procedure Rows(): Text
    var
        Row: Record "ERR Consist Row";
        Other: Record "ERR Consist Other";
        Ids: Text;
    begin
        if Row.FindSet() then
            repeat
                Ids += Format(Row.Id) + ';';
            until Row.Next() = 0;
        exit('[' + Ids + '] other=' + Format(Other.Count()));
    end;

    // The rows a commit made durable: an unrelated error undoes every write since the last commit.
    local procedure DurableRows(): Text
    begin
        asserterror Error('unrelated');
        ClearLastError();
        exit(Rows());
    end;

    local procedure InsertRow(Id: Integer)
    var
        Row: Record "ERR Consist Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Insert();
    end;

    local procedure CommitAfterRun()
    begin
        InsertRow(50);
        Commit();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_InsertsMarkedTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_InsertsOtherTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert Other");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_WritesNothing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Nothing");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_InnerFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert Fail");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure GuardedRun_InnerMarksAndInserts()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Ok := Codeunit.Run(Codeunit::"ERR Consist Mark Insert");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('rows after run', Rows());
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure GuardedRun_InnerMarksInsertsAndUnmarks()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        Ok := Codeunit.Run(Codeunit::"ERR Consist Mark Unmark");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('run', 'Yes');
        Observer.Expect('last error|text', '');
        Observer.Expect('last error|code', '');
        Observer.Expect('durable rows', '[89;] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Consistent_FalseOnOneVariable_TrueOnAnother_GuardedRun()
    var
        Observer: Codeunit "Probe Observer";
        Marker: Record "ERR Consist Row";
        Unmarker: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Marker.Consistent(false);
        Unmarker.Consistent(true);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('last error');
        Marker.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Consistent_False_StatementRun_ThenTrueAndCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
    begin
        Initialize();
        Row.Consistent(false);
        Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('rows after run', Rows());
        Row.Consistent(true);
        Commit();
        Observer.Observe('durable rows', DurableRows());
        Observer.Expect('rows after run', '[77;] other=0');
        Observer.Expect('durable rows', '[77;] other=0');
        Observer.Verify();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_ThenWriteAndCommit()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        // Does the mark outlive the guarded run? The caller writes once more and commits without Consistent(true).
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('run', Format(Ok));
        ClearLastError();
        asserterror CommitAfterRun();
        Observer.ObserveError('commit');
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;

    [Test]
    procedure Consistent_False_GuardedRun_ThenWriteAndCommit_Statement()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        // The same as the test before, with the commit as a plain statement: only one of the two can end in Finish().
        Initialize();
        Row.Consistent(false);
        Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('run', Format(Ok));
        CommitAfterRun();
        Row.Consistent(true);
        Observer.Observe('durable rows', DurableRows());
        Observer.Finish();
    end;
}
