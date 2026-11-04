// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                 Test Rpt ReqPage Ctrl (60751)
//
// A [RequestPageHandler] can read and write a request-page CONTROL, and a control bound to a
// report global is that global — not a copy of it.
//
// The distinction matters and is the reason these tests log from inside the report body
// rather than reading the control back in the handler. A handler that sets a control and
// then reads the same control back proves only that something remembered the write; it says
// nothing about whether the REPORT sees it. Report options exist to change what the report
// does, so the claim worth pinning is that the data item's OnAfterGetRecord reads the value
// the handler chose.
//
// Both directions are covered:
//   * write  -> the body's OnAfterGetRecord reads the handler's value, for a Text control
//               and for a Boolean control;
//   * read   -> a handler that writes nothing sees the value the report's own OnInitReport
//               put there, so the control is reading the live global rather than echoing;
//   * reject -> a Boolean control refuses a value that is not a boolean spelling, and the
//               refusal names the offending entry.

codeunit 60752 "Test Report ReqPage Control"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        // [RequestPageHandler] callbacks run in a read-only negotiation context, so a handler
        // cannot record what it observed through the database. The handler and the [Test]
        // procedure that declares it share one codeunit instance for the duration of a test,
        // which makes these ordinary AL state sharing.
        ObservedValue: Text[50];
        HandlerRan: Boolean;

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
        ObservedValue := '';
        HandlerRan := false;
        // Report.Run opens its own execution/UI scope, and real BC refuses to do that while
        // this transaction still has the writes above pending.
        Commit();
    end;

    // Positive, and the load-bearing one: what the handler writes into a Text control is what
    // the report body reads out of the report global that control is bound to. 'set-by-handler'
    // is asserted verbatim, so an implementation that dropped the write would log the report's
    // own 'from-report' default and fail here.
    [Test]
    [HandlerFunctions('SettingHandler')]
    procedure RequestPageControl_HandlerWrite_IsWhatTheReportBodyReads()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Ctrl");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        Assert.AreEqual(1, LogRec.MarkerCount('body-text:set-by-handler'),
            'the report body must read the Text the handler set on the request-page control');
        Assert.AreEqual(0, LogRec.MarkerCount('body-text:from-report'),
            'the report body must not still be reading the value OnInitReport seeded');
    end;

    // The same claim for a Boolean control, and it is a separate one: the body branches on the
    // value, so 'on' can only be logged if the handler's true actually reached the global.
    [Test]
    [HandlerFunctions('SettingHandler')]
    procedure RequestPageControl_HandlerWritesBoolean_TheBodyBranchesOnIt()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Ctrl");

        Assert.AreEqual(1, LogRec.MarkerCount('body-flag:on'),
            'the report body must take the true branch the handler selected');
        Assert.AreEqual(0, LogRec.MarkerCount('body-flag:off'),
            'the report body must not still be reading the false OnInitReport seeded');
    end;

    // The read direction. A handler that writes nothing must see the value the report itself
    // put in the global, not a blank — which is what distinguishes "the control reads the
    // report global" from "the control remembers what a test wrote into it".
    [Test]
    [HandlerFunctions('ReadingHandler')]
    procedure RequestPageControl_UnwrittenControl_ReadsTheReportsOwnValue()
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Ctrl");

        Assert.AreEqual('from-report', ObservedValue,
            'a control the handler did not write must read the value OnInitReport seeded on the report global');
    end;

    // Negative, with the specific refusal. A Boolean-bound control rejects a value that is not
    // a boolean spelling, and the error names the entry that was refused — so a runtime that
    // quietly coerced 'Maybe' to false would fail here rather than silently choosing a branch.
    [Test]
    [HandlerFunctions('RejectingHandler')]
    procedure RequestPageControl_BooleanControlSetToNonBoolean_IsRejectedByName()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();

        Report.Run(Report::"Test Rpt ReqPage Ctrl");

        Assert.IsTrue(HandlerRan, 'the [RequestPageHandler] never ran');
        // The refusal must not have quietly selected a branch either: the handler cancelled,
        // so the body never ran at all.
        Assert.AreEqual(0, LogRec.MarkerCount('body-flag:on'), 'a rejected entry must not select the true branch');
        Assert.AreEqual(0, LogRec.MarkerCount('body-flag:off'), 'a cancelled request page must not run the report body');
    end;

    [RequestPageHandler]
    procedure SettingHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Ctrl")
    begin
        HandlerRan := true;
        RequestPage.EchoText.SetValue('set-by-handler');
        RequestPage.IncludeAll.SetValue(true);
        // Reading a control back inside the handler is the weaker claim, but it is still one
        // BC makes, so it is pinned here alongside the body-side assertions above.
        Assert.AreEqual('set-by-handler', RequestPage.EchoText.Value(),
            'the control must read back the Text the handler just wrote');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure ReadingHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Ctrl")
    begin
        HandlerRan := true;
        ObservedValue := CopyStr(RequestPage.EchoText.Value(), 1, 50);
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RejectingHandler(var RequestPage: TestRequestPage "Test Rpt ReqPage Ctrl")
    begin
        HandlerRan := true;
        asserterror RequestPage.IncludeAll.SetValue('Maybe');
        Assert.ExpectedError('Maybe');
        RequestPage.Cancel().Invoke();
    end;
}
