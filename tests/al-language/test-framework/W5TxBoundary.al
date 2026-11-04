// Batch 5, md:87 (a failing test's writes), md:165 (a failing AutoRollback test), md:374 (a test that stops with an error keeps or loses what it wrote).
// Every probe test ends in Observer.Finish(), which raises: so every test here is a FAILING test. What the next test of the same codeunit sees
// of the failed test's rows is the observation. The "reader" tests deliberately do NOT start with DeleteAll (they observe what is left); each reader
// cleans up after its observation. Tests run in declaration order.
// The "returns normally commits at the test boundary" half of md:87 is not observable in this style (a test that returns normally cannot carry an observation): skipped.

table 67061 "W5 Tx Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 67062 "W5 Tx Boundary Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // Default transaction model: the test writes and then fails.
    [Test]
    procedure T01_Default_WritesThenFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W5 Tx Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Note := 'default failing';
        Row.Insert();
        Observer.Observe('count_inside_test', Format(Row.Count()));
        Observer.Expect('count_inside_test', '1');
        Observer.Verify();
    end;

    // The failed default-model test's row: kept or gone?
    // AutoRollback: the test writes without Commit and then fails.
    [Test]
    [TransactionModel(TransactionModel::AutoRollback)]
    procedure T03_AutoRollback_WritesThenFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W5 Tx Row";
    begin
        Row.DeleteAll();
        Row.Id := 2;
        Row.Note := 'autorollback failing';
        Row.Insert();
        Observer.Observe('count_inside_test', Format(Row.Count()));
        Observer.Expect('count_inside_test', '1');
        Observer.Verify();
    end;

    // AutoCommit: the test writes and then fails.
    [Test]
    [TransactionModel(TransactionModel::AutoCommit)]
    procedure T05_AutoCommit_WritesThenFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W5 Tx Row";
    begin
        Row.DeleteAll();
        Row.Id := 3;
        Row.Note := 'autocommit failing';
        Row.Insert();
        Observer.Observe('count_inside_test', Format(Row.Count()));
        Observer.Expect('count_inside_test', '1');
        Observer.Verify();
    end;

    // Default model with an explicit Commit before the failure: the row is durable.
    [Test]
    procedure T07_Default_WritesCommitsThenFails()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W5 Tx Row";
    begin
        Row.DeleteAll();
        Commit();
        Row.Id := 4;
        Row.Note := 'committed then failing';
        Row.Insert();
        Commit();
        Observer.Observe('count_inside_test', Format(Row.Count()));
        Observer.Expect('count_inside_test', '1');
        Observer.Verify();
    end;

    [Test]
    procedure T08_Default_ReadsRowOfFailedCommittedTest()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "W5 Tx Row";
    begin
        Observer.Observe('count_after_failed_committed_test', Format(Row.Count()));
        Observer.Observe('row_4_found', Format(Row.Get(4)));
        Row.DeleteAll();
        Commit();
        Observer.Observe('count_after_cleanup', Format(Row.Count()));
        Observer.Expect('count_after_failed_committed_test', '1');
        Observer.Expect('row_4_found', 'Yes');
        Observer.Expect('count_after_cleanup', '0');
        Observer.Verify();
    end;
}
