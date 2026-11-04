// BC Documentation:
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-enqueuebackgroundtask-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-runpagebackgroundtask-method
// Scope: in-scope
// Fixtures used: Test Page BgTask Row (60790), Test Page BgTask Worker (60791),
//                Test Page BgTask Card (60792), Test Page BgTask WriteWorker (60794),
//                Test Page BgTask Temp Row (60783), Test Page BgTask TempWorker (60784),
//                Assert (60021)
//
// Page background tasks run a worker codeunit outside the AL statement that triggered them
// and report back through Page.SetBackgroundTaskResult() / a page's OnPageBackgroundTaskCompleted
// (or OnPageBackgroundTaskError) trigger. Under a TestPage, BC's own test framework runs the
// worker SYNCHRONOUSLY: by the time OpenView()/GoToRecord() returns, the task has already
// completed and its trigger has already fired -- there is no separate "wait for background work"
// step the AL author has to perform.

codeunit 60793 "Test Page BgTask Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20]; Name: Text[50]; Handle: Boolean)
    var
        Row: Record "Test Page BgTask Row";
    begin
        Row.Init();
        Row."No." := No;
        Row.Name := Name;
        Row.Handle := Handle;
        Row.Insert();
    end;

    // Positive: CurrPage.EnqueueBackgroundTask, fired from OnAfterGetCurrRecord on the FIRST
    // row a TestPage opens onto, must have already completed -- and its OnPageBackgroundTaskCompleted
    // trigger must have already run -- by the time OpenView() returns.
    [Test]
    procedure EnqueueBackgroundTask_CompletesBeforeOpenViewReturns()
    var
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('BGT-2', 'Bravo', false);

        Card.OpenView();
        Assert.AreEqual('BG:BGT-1', Card.CountTextCtl.Value(), 'background task for the first row must have completed before OpenView returns');
        Card.Close();
    end;

    // Positive: the same, but for a row reached via GoToRecord after the page is already open --
    // proves this is not an artifact of the very first OnAfterGetCurrRecord only.
    [Test]
    procedure EnqueueBackgroundTask_CompletesBeforeGoToRecordReturns()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('BGT-2', 'Bravo', false);
        Row.Get('BGT-2');

        Card.OpenView();
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must find the seeded row BGT-2');
        Assert.AreEqual('BG:BGT-2', Card.CountTextCtl.Value(), 'background task for the GoToRecord-reached row must have completed before GoToRecord returns');
        Card.Close();
    end;

    // Positive: TestPage.RunPageBackgroundTask(CodeunitId, Parameters, RunCompletionTriggers)
    // must return the worker's own result dictionary, independent of whatever
    // OnAfterGetCurrRecord already enqueued for the current row.
    [Test]
    procedure RunPageBackgroundTask_ReturnsWorkerResult()
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        CountValue: Text;
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);

        Card.OpenView();
        Params.Add('No', 'RPT-1');
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask Worker", Params, false);
        Card.Close();

        Assert.IsTrue(Results.Get('Count', CountValue), 'RunPageBackgroundTask must return the worker''s Results dictionary');
        Assert.AreEqual('BG:RPT-1', CountValue, 'RunPageBackgroundTask must return the worker''s own computed value');
    end;

    // Positive: a worker Error() reaches the page's OnPageBackgroundTaskError trigger with the
    // error's own text, and setting IsHandled := true suppresses the exception -- GoToRecord
    // must complete normally rather than raise it.
    [Test]
    procedure EnqueueBackgroundTask_HandledErrorDoesNotPropagate()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('FAIL-H', 'Handled failure', true);
        Row.Get('FAIL-H');

        Card.OpenView();
        Assert.IsTrue(Card.GoToRecord(Row), 'GoToRecord must find the seeded row FAIL-H even though its background task errors');
        Assert.AreEqual('Test Page BgTask Worker deliberately failed for FAIL-H', Card.LastErrorTextCtl.Value(), 'OnPageBackgroundTaskError must receive the worker''s own error text');
        Card.Close();
    end;

    // Negative: the same worker error, but OnPageBackgroundTaskError leaves IsHandled false
    // (its default) -- the exception must propagate out of GoToRecord rather than be swallowed.
    [Test]
    procedure EnqueueBackgroundTask_UnhandledErrorPropagates()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
    begin
        Initialize();
        SeedRow('BGT-1', 'Alpha', false);
        SeedRow('FAIL-U', 'Unhandled failure', false);
        Row.Get('FAIL-U');

        Card.OpenView();
        asserterror Card.GoToRecord(Row);
        // Measured (BC 27.5 and 28.3): the propagated error is NOT the worker's own text --
        // an unhandled page-background-task error during GoToRecord tears down the TestPage's
        // underlying client session, and what actually reaches the caller is BC's own
        // "The TestPage is not open." This is a general TestPage error-teardown behaviour
        // (any unhandled trigger error during a TestPage-driven navigation call appears to do
        // the same), not something specific to page background tasks -- out of #2514's scope
        // to fully pin here. What #2514 cares about is proven regardless: the error is NOT
        // swallowed, it propagates out of GoToRecord. No Close() afterward -- the page is
        // already gone.
        Assert.ExpectedError('The TestPage is not open');
    end;

    // Negative: a worker codeunit's Insert(), called directly (no TryFunction -- round 1
    // wrapped the write in a [TryFunction] local procedure and measured a DIFFERENT,
    // unrelated restriction instead: "Call to the function 'INSERT' is not allowed inside the
    // call to 'RootMethodScope' when it is used as a TryFunction", a general rule about
    // TryFunction being the first call from a freshly-dispatched root scope, not a statement
    // about page background tasks), must be refused by the platform's own permission-denied
    // wording -- measured verbatim against BC 27.5 and 28.3: "Sorry, the current permissions
    // prevented the action. (TableData 60790 Test Page BgTask Row Insert: AL Language
    // Coverage Tests)". The row must not exist afterward -- not merely "some error was
    // raised", the write itself must never have landed.
    [Test]
    procedure EnqueueBackgroundTask_WorkerInsert_RefusedByReadOnlySession()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
    begin
        Initialize();
        Card.OpenView();

        Clear(Params);
        Params.Add('Op', 'Insert');
        Params.Add('No', 'WR-NEW');
        Assert.IsFalse(TryRunWriteTask(Card, Params), 'a page background task worker''s Insert() must be refused');
        Assert.ExpectedError('Sorry, the current permissions prevented the action');

        Assert.IsFalse(Row.Get('WR-NEW'), 'a refused Insert() must not have landed the row');
        Card.Close();
    end;

    // Same shape, Modify against a row that already exists -- rules out "Insert specifically
    // is refused, Modify is fine" as a narrower reading. Measured verbatim against BC 27.5
    // and 28.3: "Sorry, the current permissions prevented the action. (TableData 60790 Test
    // Page BgTask Row Modify: AL Language Coverage Tests)".
    [Test]
    procedure EnqueueBackgroundTask_WorkerModify_RefusedByReadOnlySession()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
    begin
        Initialize();
        SeedRow('WR-EXIST', 'Original', false);
        Card.OpenView();

        Clear(Params);
        Params.Add('Op', 'Modify');
        Params.Add('No', 'WR-EXIST');
        Assert.IsFalse(TryRunWriteTask(Card, Params), 'a page background task worker''s Modify() must be refused');
        Assert.ExpectedError('Sorry, the current permissions prevented the action');

        Row.Get('WR-EXIST');
        Assert.AreEqual('Original', Row.Name, 'a refused Modify() must not have changed the row');
        Card.Close();
    end;

    // Same shape, Rename against a row that already exists: a key change is a write too, and
    // the read-only session refuses it with the same permission-denied wording.
    [Test]
    procedure EnqueueBackgroundTask_WorkerRename_RefusedByReadOnlySession()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
    begin
        Initialize();
        SeedRow('WR-REN', 'Original', false);
        Card.OpenView();

        Clear(Params);
        Params.Add('Op', 'Rename');
        Params.Add('No', 'WR-REN');
        Assert.IsFalse(TryRunWriteTask(Card, Params), 'a page background task worker''s Rename() must be refused');
        Assert.ExpectedError('Sorry, the current permissions prevented the action');

        Assert.IsTrue(Row.Get('WR-REN'), 'a refused Rename() must leave the row under its old key');
        Assert.IsFalse(Row.Get('WR-REN-R'), 'a refused Rename() must not create the new key');
        Card.Close();
    end;

    // Positive contrast to the two refusals above: the read-only-session refusal a page
    // background task worker runs under applies to DATABASE writes only. A write to a
    // TEMPORARY record is a session-memory write -- it never reaches the database -- so it
    // must succeed inside the very same worker dispatch that refuses the database write.
    // Same table (60790) as EnqueueBackgroundTask_WorkerInsert_RefusedByReadOnlySession, the
    // only difference being the `temporary` keyword on the worker's Record variable, so
    // nothing else can account for a difference in outcome.
    [Test]
    procedure EnqueueBackgroundTask_WorkerInsertIntoTemporaryVar_Succeeds()
    var
        Row: Record "Test Page BgTask Row";
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Initialize();
        Card.OpenView();

        Clear(Params);
        Params.Add('Op', 'TempVar');
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TempWorker", Params, true);
        Card.Close();

        Results.Get('Count', Value);
        Assert.AreEqual('2', Value, 'both Insert()s into the temporary Record variable must have landed');
        Results.Get('Name', Value);
        Assert.AreEqual('WRITTEN-BY-WORKER', Value, 'the temporary row the worker inserted must read back with the value it wrote');
        Assert.IsFalse(Row.Get('TMP-1'), 'a temporary write must not have reached the database table');
    end;

    // Same claim for a table declared TableType = Temporary, where the AL author never writes
    // the `temporary` keyword anywhere -- the temporariness is a property of the table, and it
    // must be honoured the same way inside a page background task worker.
    [Test]
    procedure EnqueueBackgroundTask_WorkerInsertIntoTemporaryTable_Succeeds()
    var
        Card: TestPage "Test Page BgTask Card";
        Params: Dictionary of [Text, Text];
        Results: Dictionary of [Text, Text];
        Value: Text;
    begin
        Initialize();
        Card.OpenView();

        Clear(Params);
        Params.Add('Op', 'TempTable');
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask TempWorker", Params, true);
        Card.Close();

        Results.Get('Count', Value);
        Assert.AreEqual('2', Value, 'both Insert()s into the TableType = Temporary table must have landed');
        Results.Get('Name', Value);
        Assert.AreEqual('WRITTEN-BY-WORKER', Value, 'the TableType = Temporary row the worker inserted must read back with the value it wrote');
    end;

    [TryFunction]
    local procedure TryRunWriteTask(var Card: TestPage "Test Page BgTask Card"; Params: Dictionary of [Text, Text])
    var
        Results: Dictionary of [Text, Text];
    begin
        Results := Card.RunPageBackgroundTask(Codeunit::"Test Page BgTask WriteWorker", Params, false);
    end;
}

// CurrPage.CancelBackgroundTask is NOT covered here: it is not reachable through a TestPage
// handle at all. AL's own compiler (the real BC language service, via al-runner's BcCompiler)
// rejects `Card.CancelBackgroundTask(...)` against a `TestPage "Test Page BgTask Card"` variable
// with AL0132 "'TestPage Test Page BgTask Card' does not contain a definition for
// 'CancelBackgroundTask'" -- TestPage's generated surface exposes fields, actions and the
// documented TestPage-only methods (OpenView/GoToRecord/Close/RunPageBackgroundTask/...), never
// arbitrary page procedures, and CancelBackgroundTask is a plain Page-instance method, not a
// TestPage one. This is a compile-time fact, not something a real BC service tier needs to
// adjudicate at runtime, so there is nothing to measure -- and nothing "cheap" to add here.
