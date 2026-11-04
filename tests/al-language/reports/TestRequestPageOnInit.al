// Tests for the fixture in TestRequestPageOnInitReport.al.
//
// CLAIM: a report request page's own OnInit trigger runs before the request page is handed to
// a [RequestPageHandler], so a global assigned only there is readable through a control.
//
// Written for AL Runner issue StefanMaron/BusinessCentral.AL.Runner#4149, which measures the
// runner leaving that control blank. These arms record what BC does, which is the thing that
// was missing -- the issue says so and names this test as what would settle it.
//
// One handler run feeds all three arms: the handler captures all three controls and the arms
// assert them separately, so the three claims are independently attributable without paying
// for three report runs.

codeunit 60977 "RPI OnInit Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        SeenReqInit: Text[30];
        SeenReqOpen: Text[30];
        SeenRptInit: Text[30];

    local procedure RunTheReport()
    begin
        SeenReqInit := '';
        SeenReqOpen := '';
        SeenRptInit := '';
        Report.Run(Report::"RPI OnInit Report", true);
    end;

    [Test]
    [HandlerFunctions('RpiHandler')]
    procedure RequestPageOnInit_HasRun_WhenTheHandlerSeesTheRequestPage()
    // THE SUBJECT. ReqInitVar is assigned nowhere but the request page's OnInit, so a blank
    // here means that trigger did not run before the handler was given the page.
    begin
        RunTheReport();

        Assert.AreEqual(
            'req-oninit', SeenReqInit,
            'A control bound to a global assigned only in the request page''s OnInit must read that value, so OnInit ran before the handler saw the page.');
    end;

    [Test]
    [HandlerFunctions('RpiHandler')]
    procedure RequestPageOnOpenPage_HasRun_SoTheRequestPageIsLive()
    // The discriminator. If this passes while the arm above fails, the request page is live
    // and its OnInit specifically is missing -- a different fix from "no request-page trigger
    // runs at all".
    begin
        RunTheReport();

        Assert.AreEqual(
            'req-onopenpage', SeenReqOpen,
            'A control bound to a global assigned only in the request page''s OnOpenPage must read that value.');
    end;

    [Test]
    [HandlerFunctions('RpiHandler')]
    procedure ReportOnInitReport_HasRun_SoTheReportHalfInitialised()
    // The control. If this fails too, nothing about the report initialised and the two arms
    // above are measuring that rather than anything about the request page.
    begin
        RunTheReport();

        Assert.AreEqual(
            'rpt-oninitreport', SeenRptInit,
            'A control bound to a global assigned only in the report''s OnInitReport must read that value.');
    end;

    [RequestPageHandler]
    procedure RpiHandler(var RequestPage: TestRequestPage "RPI OnInit Report")
    begin
        // CopyStr rather than a bare assignment: Value() is an unbounded Text and these
        // globals are Text[30], which AL rejects at compile time without an explicit truncate.
        SeenReqInit := CopyStr(RequestPage.ReqInitField.Value(), 1, 30);
        SeenReqOpen := CopyStr(RequestPage.ReqOpenField.Value(), 1, 30);
        SeenRptInit := CopyStr(RequestPage.RptInitField.Value(), 1, 30);
        RequestPage.OK().Invoke();
    end;
}
