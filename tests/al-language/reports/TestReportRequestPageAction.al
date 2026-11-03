// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                 Test Rpt ReqPage Action (60398)
//
// A [RequestPageHandler] cannot invoke an action the request page declares. The TestRequestPage
// compiles `RequestPage.StampText.Invoke()`, but BC answers with its own test-page refusal,
// "The action with ID = <id> is not found on the page.", and the action's OnAction does not run.
//
// The expected text includes the id. It is BC's member id for the action, derived from the
// report id and the action name, so it is the same on every BC version, and it identifies which
// action BC looked up. A refusal that named a different action would fail these tests.
//
//   * refused  -> each of the three actions is refused with BC's text and its own id;
//   * no run   -> the report body still reads the value OnInitReport seeded, and a run counter
//                 of 0, so no OnAction ran (not even the one whose OnAction raises an error);
//   * control  -> after the refusal the request page still works: the handler reads and writes
//                 the bound control, OK runs the report, and the body reads the handler's value.

codeunit 60399 "Test Report ReqPage Action"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // [RequestPageHandler] callbacks share this codeunit's instance with the [Test] that
        // declares them.
        ObservedAfterRefusal: Text[50];
        HandlerRan: Boolean;
        StampNotFoundErr: Label 'The action with ID = 727081671 is not found on the page.', Locked = true;
        AppendNotFoundErr: Label 'The action with ID = 622821794 is not found on the page.', Locked = true;
        RefuseNotFoundErr: Label 'The action with ID = 1188892507 is not found on the page.', Locked = true;

    local procedure Initialize()
    var
        Row: Record "Test Rpt RunReqPage Row";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        LogRec.DeleteAll();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'only';
        Row.Insert();
        ObservedAfterRefusal := '';
        HandlerRan := false;
        // Report.Run opens its own execution/UI scope, which real BC refuses while writes are pending.
        Commit();
    end;

    [Test]
    [HandlerFunctions('StampHandler')]
    procedure RequestPageAction_Invoke_IsNotFoundOnThePage_AndOnActionDoesNotRun()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual(1, LogRec.MarkerCount('body-text:from-report'),
            'the refused action''s OnAction must not have changed the report global');
        Assert.AreEqual(0, LogRec.MarkerCount('body-text:set-by-action'),
            'the refused action''s OnAction must not have run');
        Assert.AreEqual(1, LogRec.MarkerCount('body-actions:0'),
            'no OnAction may have run');
    end;

    [Test]
    [HandlerFunctions('AllActionsHandler')]
    procedure RequestPageAction_EveryDeclaredAction_IsRefusedWithItsOwnId()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual(1, LogRec.MarkerCount('body-text:from-report'),
            'none of the refused actions may have changed the report global');
        Assert.AreEqual(1, LogRec.MarkerCount('body-actions:0'),
            'no OnAction may have run');
    end;

    [Test]
    [HandlerFunctions('RefuseThenSetHandler')]
    procedure RequestPageAction_AfterARefusal_TheRequestPageStillWorks()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Action");

        Assert.AreEqual('from-report', ObservedAfterRefusal,
            'after the refused Invoke the control must still read the value OnInitReport seeded');
        Assert.AreEqual(1, LogRec.MarkerCount('body-text:set-by-handler'),
            'a control write after the refusal must reach the report body');
        Assert.AreEqual(1, LogRec.MarkerCount('body-actions:0'),
            'no OnAction may have run');
    end;

    [RequestPageHandler]
    procedure StampHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        asserterror RequestPage.StampText.Invoke();
        Assert.ExpectedError(StampNotFoundErr);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure AllActionsHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        asserterror RequestPage.StampText.Invoke();
        Assert.ExpectedError(StampNotFoundErr);
        asserterror RequestPage.AppendText.Invoke();
        Assert.ExpectedError(AppendNotFoundErr);
        // This action's OnAction raises 'refused-by-request-page-action'. BC's not-found error,
        // and not that one, shows the lookup failed before any trigger could run.
        asserterror RequestPage.RefuseAction.Invoke();
        Assert.ExpectedError(RefuseNotFoundErr);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RefuseThenSetHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Action")
    begin
        HandlerRan := true;
        asserterror RequestPage.StampText.Invoke();
        Assert.ExpectedError(StampNotFoundErr);
        ObservedAfterRefusal := CopyStr(RequestPage.EchoText.Value(), 1, 50);
        RequestPage.EchoText.SetValue('set-by-handler');
        RequestPage.OK().Invoke();
    end;
}
