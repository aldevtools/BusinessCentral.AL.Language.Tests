// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope
// Fixtures used: Test Page BgTask Row (60790), Test Page BgTask Card (60792),
//                Test Page BgTask Worker (60791), Test Page BgTask TxWorker (67200),
//                Test Page BgTask TxNoop (67201), Test Page BgTask Tx Card (67203), Assert (60021)
//
// A page background task's worker runs in a child session, not in the caller's transaction.
// These tests pin what that child session sees of a caller holding an open write transaction:
//   - which of the caller's rows the worker reads: a committed baseline, an uncommitted insert
//     on top of it, and an uncommitted delete from it, each in its own test with its own key
//     prefix, so no read can be answered from an earlier test's read;
//   - that the worker is not itself in a write transaction, so a guarded Codeunit.Run -- refused
//     in the caller while its write is pending -- is allowed inside the worker;
//   - that the caller's write transaction is still open after the task returns, also when the
//     worker fails, and that a commit inside the worker does not commit the caller's rows.
// Base Application's Journal Errors factbox ("Check Gen. Jnl. Line. Backgr.", 9081) runs
// Gen. Jnl.-Check Line through a guarded Codeunit.Run over journal lines the test has not
// committed (BusinessCentral.AL.Runner#4679).

codeunit 67202 "Test Page BgTask Tx Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // Leaves the table empty AND committed, so each test's committed baseline is exactly what
    // it writes before its own Commit().
    local procedure Initialize()
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.DeleteAll();
        Commit();
    end;

    local procedure SeedRow(No: Code[20])
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Insert();
    end;

    // RunCompletionTrigger = false throughout: the Card's own OnPageBackgroundTaskCompleted is
    // written for Test Page BgTask Worker's results, not this worker's.
    local procedure WorkerKeys(Prefix: Text): Text
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Params.Add('Prefix', Prefix);
        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, false);
        Card.Close();
        Results.Get('Keys', Value);
        exit(Value);
    end;

    // Control for the three visibility tests below: with nothing uncommitted, the worker's
    // filtered read returns exactly the committed rows. If this fails, the instrument is wrong,
    // not the transaction model.
    [Test]
    procedure RunPageBackgroundTask_WorkerSeesCommittedRows()
    begin
        Initialize();
        SeedRow('VIS-C1');
        SeedRow('VIS-C2');
        Commit();

        Assert.AreEqual('VIS-C1,VIS-C2', WorkerKeys('VIS'), 'the worker must see the two committed rows');
    end;

    // An uncommitted INSERT on top of a committed baseline, and nothing else uncommitted.
    [Test]
    procedure RunPageBackgroundTask_UncommittedInsert_IsVisibleToWorker()
    begin
        Initialize();
        SeedRow('INS-C');
        Commit();
        SeedRow('INS-U');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: INS-U must still be uncommitted');

        Assert.AreEqual('INS-C,INS-U', WorkerKeys('INS'), 'the worker must see the committed row and the row the caller inserted without committing');
    end;

    // An uncommitted DELETE from a committed baseline, and nothing else uncommitted. DeleteAll
    // over a key filter deletes without reading the row first.
    [Test]
    procedure RunPageBackgroundTask_UncommittedDelete_IsVisibleToWorker()
    var
        Row: Record "Test Page BgTask Row";
    begin
        Initialize();
        SeedRow('DEL-C1');
        SeedRow('DEL-C2');
        Commit();
        Row.SetRange("No.", 'DEL-C2');
        Row.DeleteAll();
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: the delete of DEL-C2 must still be uncommitted');

        Assert.AreEqual('DEL-C1', WorkerKeys('DEL'), 'the worker must not see the row the caller deleted without committing');
    end;

    // The worker is outside the caller's write transaction: it reports none, and a guarded
    // Codeunit.Run inside it starts. The same guarded run in the caller, with the caller's
    // write still pending after the task returned, is refused.
    [Test]
    procedure RunPageBackgroundTask_WorkerIsOutsideCallersWriteTransaction()
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
        Ok: Boolean;
    begin
        Initialize();
        SeedRow('TX-1');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: the seeded row must still be uncommitted');

        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, false);
        Card.Close();

        Results.Get('InWriteTx', Value);
        Assert.AreEqual('false', Value, 'the worker must not be in the caller''s write transaction');
        Results.Get('GuardedRun', Value);
        Assert.AreEqual('true', Value, 'a guarded Codeunit.Run inside the worker must be allowed to run');

        Assert.IsTrue(Database.IsInWriteTransaction(), 'the caller''s write transaction must still be open after the task');
        asserterror Ok := Codeunit.Run(Codeunit::"Test Page BgTask TxNoop");
        Assert.ExpectedError('the transaction is stopped');
    end;

    // The worker's guarded Codeunit.Run commits the worker's own transaction, not the
    // caller's: a trapped error afterwards still rolls back the row the caller wrote before
    // the task ran.
    [Test]
    procedure RunPageBackgroundTask_WorkerCommitLeavesCallersRowsUncommitted()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Initialize();
        SeedRow('TX-RB');

        Card.OpenView();
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TxWorker", Params, false);
        Card.Close();
        Results.Get('GuardedRun', Value);
        Assert.AreEqual('true', Value, 'precondition: the worker''s guarded Codeunit.Run must have run and committed');
        Assert.IsTrue(Row.Get('TX-RB'), 'the caller''s row must still be readable after the task');

        asserterror Error('bgtx rollback probe');
        Assert.ExpectedError('bgtx rollback probe');

        Assert.IsFalse(Row.Get('TX-RB'), 'the worker''s commit must not have made the caller''s uncommitted row durable');
    end;

    // A FAILING worker leaves the caller's write transaction as it found it: still open, and
    // still the caller's to commit.
    [Test]
    procedure RunPageBackgroundTask_FailingWorker_LeavesCallersWriteTransactionOpen()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
    begin
        Initialize();
        SeedRow('ERR-U');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: ERR-U must still be uncommitted');

        Card.OpenView();
        Params.Add('No', 'FAIL-ERR');
        Assert.IsFalse(TryRunFailingTask(Card, Params), 'the worker must have failed');
        Assert.ExpectedError('Test Page BgTask Worker deliberately failed for FAIL-ERR');
        Card.Close();

        Assert.IsTrue(Database.IsInWriteTransaction(), 'the caller''s write transaction must still be open after a failing task');
        Commit();
        asserterror Error('bgtx failing-worker probe');
        Assert.ExpectedError('bgtx failing-worker probe');
        Assert.IsTrue(Row.Get('ERR-U'), 'the caller''s Commit() after the failing task must have made ERR-U durable');
    end;

    // The FactBox shape: CurrPage.EnqueueBackgroundTask from OnAfterGetCurrRecord while the
    // caller holds an uncommitted insert on top of a committed row. The completion trigger must
    // have run with the worker's results -- not the error trigger.
    [Test]
    procedure EnqueueBackgroundTask_WithUncommittedInsert_CompletesWithWorkerResults()
    var
        Card: TestPage "Test Page BgTask Tx Card";
    begin
        Initialize();
        SeedRow('ENQ-C');
        Commit();
        SeedRow('ENQ-U');
        Assert.IsTrue(Database.IsInWriteTransaction(), 'precondition: ENQ-U must still be uncommitted');

        Card.OpenView();
        Assert.AreEqual('', Card.ErrorCtl.Value(), 'the background task must not have raised an error');
        Assert.AreEqual('false', Card.InWriteTxCtl.Value(), 'the worker must not be in the caller''s write transaction');
        Assert.AreEqual('true', Card.GuardedRunCtl.Value(), 'a guarded Codeunit.Run inside the worker must be allowed to run');
        Assert.AreEqual('ENQ-C,ENQ-U', Card.KeysCtl.Value(), 'the worker must see the committed row and the uncommitted insert');
        Card.Close();
    end;

    [TryFunction]
    local procedure TryRunFailingTask(var Card: TestPage "Test Page BgTask Card"; Params: Dictionary of [Text, Text])
    var
        Results: Dictionary of [Text, Text];
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask Worker", Params, false);
    end;
}
