// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onqueryclosepage-page-trigger
// Scope: in-scope
// Fixtures used: MQC Trace (60271), MQC Row (60272), MQC Trace Modal (60273),
//                MQC Persist Modal (60274), Assert (60021)
//
// The corpus pins what a [ModalPageHandler] RETURNS (TestPageModalHandlerStatic_Tests.al) and
// that OnClosePage runs when a test calls Close() itself (TestPageRecordTriggers.al). Neither
// pins the CLOSE LIFECYCLE of a page the platform closed on the handler's behalf: whether
// OnQueryClosePage runs at all, with which CloseAction, and in what order relative to
// OnClosePage.
//
// That matters because OnQueryClosePage is where the "Manage X" worksheet shape does its
// work — a caller RunModal's a page variable, hands it a copy of a record, and the page
// writes that copy back when the user confirms. If the trigger never runs the write is lost
// silently: no error, the caller just reads the old value back.
//
// Every arm records 'QUERYCLOSE:' + Format(CloseAction) and 'CLOSEPAGE' into an ordered
// table, so the assertions pin the sequence, not just the presence. Negatives carry their
// own weight here: Cancel must reach OnQueryClosePage too (with a cancelling CloseAction),
// and it must NOT persist — an implementation that fired the trigger with a hardcoded OK
// would pass the positive arms and fail the cancel ones.

codeunit 60276 "MQC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Trace: Record "MQC Trace";
        Row: Record "MQC Row";
    begin
        Trace.DeleteAll();
        Row.DeleteAll();
    end;

    local procedure SeedRow(No: Code[20]; var Row: Record "MQC Row")
    begin
        Row.Init();
        Row."No." := No;
        Row."Set ID" := 999;
        Row.Insert();
    end;

    // (a) Plain modal, handler confirms. OnQueryClosePage must run with a confirming
    // CloseAction, before OnClosePage.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure PlainModal_HandlerOk_RunsQueryClosePageThenClosePage()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Trace Modal";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual('QUERYCLOSE:OK;CLOSEPAGE;', Trace.Events(),
            'a modal closed by the handler OK must raise OnQueryClosePage(OK) and then OnClosePage');
        Assert.AreEqual(Format(Action::OK), Format(Result), 'RunModal must report the handler OK');
    end;

    // (b) Plain (non-lookup) modal whose handler invokes nothing. Pairs with (e), and the
    // pair is the point: the CloseAction the platform substitutes when the handler made no
    // choice is NOT the same in both modes — plain gets OK, lookup gets LookupCancel — so
    // neither value can be inferred from the other, nor from the confirming arms.
    [Test]
    [HandlerFunctions('NoInvokeHandler')]
    procedure PlainModal_HandlerInvokesNothing_ObservedCloseLifecycle()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Trace Modal";
        Result: Action;
    begin
        Initialize();

        Result := Modal.RunModal();

        Assert.AreEqual('QUERYCLOSE:OK;CLOSEPAGE;', Trace.Events(),
            'a plain modal whose handler invoked nothing still raises OnQueryClosePage');
        Assert.AreEqual(Format(Action::OK), Format(Result),
            'RunModal must report what the platform chose for a handler that invoked nothing');
    end;

    // (b2) Why there is no plain-mode cancel MEASUREMENT in this file, recorded so the gap
    // does not read as an oversight. Every cancel arm here is a LOOKUP-mode cancel. That is not
    // an omission: BC offers no built-in Cancel action on a modal page that is NOT in lookup
    // mode, so a plain-mode handler has nothing to invoke and there is no CloseAction for a
    // cancelled plain modal to report.
    //
    // MEASURED, not predicted, and it is the correction of a wrong prediction. This arm was
    // first written as PlainModal_HandlerCancel_RunsQueryClosePageWithCancel, asserting
    // 'QUERYCLOSE:Cancel;CLOSEPAGE;' and Action::Cancel by symmetry with the confirming pair
    // ((a) OK / (c) LookupOK). All eight cloud legs refused it with the message below instead.
    // The symmetry argument was simply wrong, and the refusal is the real answer.
    //
    // (d) is the control that makes this a fact about the MODE rather than about the page or
    // the handler: same page, same CancelHandler, same Cancel() call, and it passes -- the one
    // difference is the LookupMode(true) this arm does not do. So the pair isolates the mode.
    //
    // This also explains (b) vs (e), the no-choice defaults that already disagreed: a plain
    // modal has no cancelling built-in to fall back on, so it defaults to OK, while lookup mode
    // has LookupCancel available and uses it.
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure PlainModal_HasNoBuiltInCancelAction()
    var
        Modal: Page "MQC Trace Modal";
    begin
        Initialize();

        asserterror Modal.RunModal();

        Assert.ExpectedError('The built-in action = Cancel is not found on the page');
    end;

    // (c) Lookup mode changes the CloseAction the trigger sees, not whether it runs.
    [Test]
    [HandlerFunctions('OkHandler')]
    procedure LookupModal_HandlerOk_RunsQueryClosePageWithLookupOk()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Trace Modal";
        Result: Action;
    begin
        Initialize();

        Modal.LookupMode(true);
        Result := Modal.RunModal();

        Assert.AreEqual('QUERYCLOSE:LookupOK;CLOSEPAGE;', Trace.Events(),
            'a lookup-mode modal confirmed by the handler must raise OnQueryClosePage(LookupOK)');
        Assert.AreEqual(Format(Action::LookupOK), Format(Result), 'RunModal must report LookupOK in lookup mode');
    end;

    // (d) The cancelling half of (c).
    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure LookupModal_HandlerCancel_RunsQueryClosePageWithLookupCancel()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Trace Modal";
        Result: Action;
    begin
        Initialize();

        Modal.LookupMode(true);
        Result := Modal.RunModal();

        Assert.AreEqual('QUERYCLOSE:LookupCancel;CLOSEPAGE;', Trace.Events(),
            'a cancelled lookup-mode modal must raise OnQueryClosePage(LookupCancel)');
        Assert.AreEqual(Format(Action::LookupCancel), Format(Result), 'RunModal must report LookupCancel');
    end;

    // (e) The handler returns without invoking any built-in action at all. What CloseAction
    // the platform then passes — and what RunModal returns — is the case an implementation
    // has no way to guess, so it is pinned rather than assumed.
    [Test]
    [HandlerFunctions('NoInvokeHandler')]
    procedure LookupModal_HandlerInvokesNothing_ObservedCloseLifecycle()
    var
        Trace: Record "MQC Trace";
        Modal: Page "MQC Trace Modal";
        Result: Action;
    begin
        Initialize();

        Modal.LookupMode(true);
        Result := Modal.RunModal();

        Assert.AreEqual('QUERYCLOSE:LookupCancel;CLOSEPAGE;', Trace.Events(),
            'a handler that invokes nothing still closes the page; this pins how');
        Assert.AreEqual(Format(Action::LookupCancel), Format(Result),
            'RunModal must report what the platform chose for a handler that invoked nothing');
    end;

    // (f) The shape the whole file exists for: the page writes a caller-supplied record copy
    // back from OnQueryClosePage. The row changing is the only evidence the trigger ran with
    // a confirming CloseAction.
    [Test]
    [HandlerFunctions('PersistOkHandler')]
    procedure PersistInQueryClosePage_HandlerOk_WriteReachesTheTable()
    var
        Row: Record "MQC Row";
        Modal: Page "MQC Persist Modal";
    begin
        Initialize();
        SeedRow('F', Row);

        Modal.SetTarget(Row);
        Modal.LookupMode(true);
        Modal.RunModal();

        Row.Get('F');
        Assert.AreEqual(0, Row."Set ID",
            'OnQueryClosePage must run on a handler-confirmed modal, so its Modify reaches the table');
    end;

    // The negative for (f). A page whose OnQueryClosePage only writes on a confirming
    // CloseAction must leave the row alone when the handler cancels — so an implementation
    // that raised the trigger with a hardcoded OK fails here.
    [Test]
    [HandlerFunctions('PersistCancelHandler')]
    procedure PersistInQueryClosePage_HandlerCancel_LeavesTheTableAlone()
    var
        Row: Record "MQC Row";
        Modal: Page "MQC Persist Modal";
    begin
        Initialize();
        SeedRow('G', Row);

        Modal.SetTarget(Row);
        Modal.LookupMode(true);
        Modal.RunModal();

        Row.Get('G');
        Assert.AreEqual(999, Row."Set ID",
            'a cancelled modal must not persist — OnQueryClosePage saw a cancelling CloseAction');
    end;

    // (g) The NON-modal twin. Page.Run reaches a [PageHandler] and ends through the same
    // close lifecycle; whether the CloseAction differs from the modal case is exactly what a
    // runner cannot infer from the modal arms.
    [Test]
    [HandlerFunctions('OkPageHandler')]
    procedure NonModalPageRun_HandlerOk_RunsQueryClosePageThenClosePage()
    var
        Trace: Record "MQC Trace";
        Target: Page "MQC Trace Modal";
    begin
        Initialize();

        Target.Run();

        Assert.AreEqual('QUERYCLOSE:OK;CLOSEPAGE;', Trace.Events(),
            'a [PageHandler]-driven Page.Run must raise OnQueryClosePage before OnClosePage');
    end;

    [ModalPageHandler]
    procedure OkHandler(var Modal: TestPage "MQC Trace Modal")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelHandler(var Modal: TestPage "MQC Trace Modal")
    begin
        Modal.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure NoInvokeHandler(var Modal: TestPage "MQC Trace Modal")
    begin
        // Deliberately invokes nothing.
    end;

    [ModalPageHandler]
    procedure PersistOkHandler(var Modal: TestPage "MQC Persist Modal")
    begin
        Modal.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure PersistCancelHandler(var Modal: TestPage "MQC Persist Modal")
    begin
        Modal.Cancel().Invoke();
    end;

    [PageHandler]
    procedure OkPageHandler(var Target: TestPage "MQC Trace Modal")
    begin
        Target.OK().Invoke();
    end;
}
