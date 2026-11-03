// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

codeunit 90605 "LT WB Modal Close Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure HandlerErrorLeavesPageOpenAndCloseIsAllowed()
    begin
        // [SCENARIO] A ModalPageHandler raises an error and leaves a modal Worksheet with a ListPart open
        // [GIVEN] The Worksheet and ListPart allow the platform close
        CloseTrace.Reset(true);

        // [WHEN] The ModalPageHandler raises an error without closing the TestPage
        asserterror RunModalWorksheet();

        // [THEN] RunModal raises the handler error after closing the ListPart and Worksheet
        Assert.ExpectedError('Handler failure');
        Assert.AreEqual('Part:None|Page:LookupCancel', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    [Test]
    [HandlerFunctions('PageErrorHandler')]
    procedure PageActionErrorLeavesPageOpenAndCloseIsAllowed()
    begin
        // [SCENARIO] A page action raises an error through a ModalPageHandler and leaves the page open
        // [GIVEN] The Worksheet and ListPart allow the platform close
        CloseTrace.Reset(true);

        // [WHEN] The ModalPageHandler invokes the erroring page action
        asserterror RunModalWorksheet();

        // [THEN] RunModal raises the page error after closing the ListPart and Worksheet
        Assert.ExpectedError('Page failure');
        Assert.AreEqual('Part:None|Page:LookupCancel', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    [Test]
    [HandlerFunctions('CancelThenErrorHandler')]
    procedure HandlerErrorAfterExplicitCancelDoesNotCloseAgain()
    begin
        // [SCENARIO] A ModalPageHandler closes a modal page before raising an error
        // [GIVEN] The Worksheet and ListPart allow Cancel
        CloseTrace.Reset(true);

        // [WHEN] The ModalPageHandler invokes Cancel and then raises an error
        asserterror RunModalWorksheet();

        // [THEN] RunModal raises the handler error without another platform close
        Assert.ExpectedError('Handler failure');
        Assert.AreEqual('Part:None|Page:LookupCancel', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    [Test]
    [HandlerFunctions('CancelHandler')]
    procedure ExplicitCancelReturnsCancel()
    var
        Result: Action;
    begin
        // [SCENARIO] A ModalPageHandler explicitly cancels a modal Worksheet
        // [GIVEN] The Worksheet and ListPart allow Cancel
        CloseTrace.Reset(true);

        // [WHEN] The ModalPageHandler invokes Cancel
        Result := RunModalWorksheet();

        // [THEN] RunModal returns Cancel after closing the ListPart and Worksheet
        Assert.IsTrue(Result = Action::LookupCancel, 'RunModal should return LookupCancel');
        Assert.AreEqual('Part:None|Page:LookupCancel', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure ExplicitTestPageCloseRaisesAlreadyClosedError()
    begin
        // [SCENARIO] A ModalPageHandler explicitly closes a modal Worksheet
        // [GIVEN] The Worksheet and ListPart allow the close
        CloseTrace.Reset(true);

        // [WHEN] The ModalPageHandler calls TestPage.Close
        asserterror RunModalWorksheet();

        // [THEN] RunModal reports that the page was already closed
        Assert.ExpectedError('The RunModal procedure could not close the page 90604 as it has already been closed.');
        Assert.AreEqual('Part:None|Page:LookupCancel', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    [Test]
    [HandlerFunctions('LeaveOpenHandler')]
    procedure HandlerErrorLeavesPageOpenAndCloseIsRefused()
    begin
        // [SCENARIO] A ModalPageHandler raises an error and the modal Worksheet refuses the platform close
        // [GIVEN] The Worksheet and ListPart refuse the close
        CloseTrace.Reset(false);

        // [WHEN] The ModalPageHandler raises an error without closing the TestPage
        asserterror RunModalWorksheet();

        // [THEN] RunModal raises the handler error after asking the ListPart to close
        Assert.ExpectedError('Handler failure');
        Assert.AreEqual('Part:None', CloseTrace.GetTrace(), 'Close lifecycle');
    end;

    local procedure RunModalWorksheet(): Action
    var
        ModalWorksheet: Page "LT WB Modal Worksheet";
    begin
        ModalWorksheet.LookupMode(true);
        exit(ModalWorksheet.RunModal());
    end;

    [ModalPageHandler]
    procedure LeaveOpenHandler(var ModalWorksheet: TestPage "LT WB Modal Worksheet")
    begin
        Error('Handler failure');
    end;

    [ModalPageHandler]
    procedure PageErrorHandler(var ModalWorksheet: TestPage "LT WB Modal Worksheet")
    begin
        ModalWorksheet.RaisePageError.Invoke();
    end;

    [ModalPageHandler]
    procedure CancelThenErrorHandler(var ModalWorksheet: TestPage "LT WB Modal Worksheet")
    begin
        ModalWorksheet.Cancel().Invoke();
        Error('Handler failure');
    end;

    [ModalPageHandler]
    procedure CancelHandler(var ModalWorksheet: TestPage "LT WB Modal Worksheet")
    begin
        ModalWorksheet.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CloseHandler(var ModalWorksheet: TestPage "LT WB Modal Worksheet")
    begin
        ModalWorksheet.Close();
    end;

    var
        Assert: Codeunit Assert;
        CloseTrace: Codeunit "LT WB Close Trace";
}
