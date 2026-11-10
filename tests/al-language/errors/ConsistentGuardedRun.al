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
//   - the run is not guarded (a statement), then Consistent(true) and Commit.
//   Each test reads what the guarded run returned, the last error text and code, and the rows that are still there after an unrelated
//   error (the rows a commit made durable).
// Measured on BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): while ERR Consist Row is marked with
//   Consistent(false), by the caller or by the inner codeunit, a guarded Codeunit.Run (Ok := Codeunit.Run(...)) does not return false:
//   it raises the inconsistency error, also when the inner codeunit writes nothing or fails, and also when another variable of the
//   table called Consistent(true) before the run. Those tests assert the error with asserterror. Only an inner codeunit that calls
//   Consistent(true) before it ends lets the guarded run return Yes. Two tests were removed: after Consistent(false) the caller wrote
//   again and committed after the guarded run, but the guarded run already raises, so that question cannot be reached.
// Already pinned elsewhere, not repeated: Consistent(false) then Commit, and Consistent(false), Consistent(true), Commit
//   (CuCommitTests.al, Consistent_False_ThenCommit and Consistent_FalseThenTrue_ThenCommit); the commit of a guarded Codeunit.Run
//   without a mark (CuCommitTests.al, item 36).
// local object: the tests must commit (a guarded Codeunit.Run commits), and the inner codeunits are the code under test.
// The values are what BC produced.
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

    [Test]
    procedure Consistent_False_GuardedRun_InsertsMarkedTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        Row.Consistent(false);
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
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
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Insert Other");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
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
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Nothing");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
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
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Insert Fail");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
    end;

    [Test]
    procedure GuardedRun_InnerMarksAndInserts()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "ERR Consist Row";
        Ok: Boolean;
    begin
        Initialize();
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Mark Insert");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
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
        // BC 27.5, 28.5 and 29.0 (CI batch runs 42826078233, 42826192322, 42826312960): this guarded Codeunit.Run does not return;
        // it raises the inconsistency error of ERR Consist Row, and the Ok := form does not catch it.
        asserterror Ok := Codeunit.Run(Codeunit::"ERR Consist Insert");
        Observer.Observe('guarded run', GetLastErrorText());
        Observer.Expect('guarded run', 'The transaction cannot be completed because it will cause inconsistencies in the ERR Consist Row table. Check where and how the CONSISTENT function is used in the transaction to find the reason for the error.\\Contact your system administrator.\\Tables can be marked as inconsistent during comprehensive tasks, such as posting. This prevents data from being updated incorrectly.');
        Observer.Verify();
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
}
