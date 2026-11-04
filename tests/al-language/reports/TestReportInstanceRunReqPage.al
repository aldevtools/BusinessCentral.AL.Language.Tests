// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                 Test Rpt InstRunReqPage (60319)
//
// The INSTANCE form of Report.RunRequestPage, which codeunit 60545 does not cover — it drives
// the by-id form only. Two overloads exist on a report variable:
//
//     MyReport.RunRequestPage()             -> the parameters the handler left behind
//     MyReport.RunRequestPage(parameters)   -> the same, seeded with a parameters string
//
// Why the instance form is worth its own codeunit rather than an extra arm on 60545: the
// caller keeps the report instance across the call, so a value the handler wrote into a
// request-page control is readable off the report's own global afterwards. The by-id form
// constructs and discards its instance, so that observable does not exist there. Pinning it
// here means "the request page ran on the instance the caller holds" is a measured claim and
// not an inference from the by-id result.
//
// Both directions are pinned, as in 60545: a handler that confirms yields a parameters
// document and the control value it set; a handler that cancels yields an empty string while
// the page still opened and the handler still ran.

codeunit 60317 "Test Report Inst RunReqPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [RequestPageHandler] callbacks execute in a read-only negotiation context, so the
    // handler cannot write a table to prove it ran — see the same note on codeunit 60545.
    // A codeunit global carries that proof instead; the handler and the [Test] procedure
    // share one codeunit instance for the duration of a test.
    var
        HandlerRan: Boolean;
        HandlerCancelled: Boolean;

    local procedure Initialize()
    var
        Row: Record "Test Rpt RunReqPage Row";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        LogRec.DeleteAll();
        Row.DeleteAll();
        Row.Init();
        Row."Entry No." := 1;
        Row.Name := 'first';
        Row.Insert();
        Row.Init();
        Row."Entry No." := 2;
        Row.Name := 'second';
        Row.Insert();
        HandlerRan := false;
        HandlerCancelled := false;
        // RunRequestPage opens its own execution scope, which BC refuses to enter while this
        // transaction still has the writes above pending. Commit first, as Base App code does.
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmingInstanceHandler')]
    procedure TestReport_InstanceRunRequestPage_RunsTheHandlerAndReturnsItsFilter()
    var
        InstReport: Report "Test Rpt InstRunReqPage";
        LogRec: Record "Test Rpt RunReqPage Log";
        Parameters: Text;
    begin
        Initialize();

        Parameters := InstReport.RunRequestPage();

        if LogRec.MarkerCount('inst-rp-open') <> 1 then
            Error('The request page never opened, so its OnOpenPage never ran: expected exactly 1 inst-rp-open log row, got %1.',
                LogRec.MarkerCount('inst-rp-open'));
        if not HandlerRan then
            Error('The [RequestPageHandler] never ran.');
        if Parameters = '' then
            Error('The instance RunRequestPage returned an empty parameters string after the handler confirmed with OK.');
        if StrPos(Parameters, 'ReportParameters') = 0 then
            Error('Expected a ReportParameters document, got: %1', Parameters);
        // BC serialises a data item's view with useCaptions:false, so a filter on "Entry No."
        // (field 1) appears as WHERE(Field1=1(1)) — the field NUMBER, not its caption.
        if StrPos(Parameters, 'DataItem name="Rows"') = 0 then
            Error('The Rows data item is missing from the parameters: %1', Parameters);
        if StrPos(Parameters, 'WHERE(Field1=1') = 0 then
            Error('The filter the handler set did not survive into the parameters: %1', Parameters);
    end;

    [Test]
    [HandlerFunctions('ConfirmingInstanceHandler')]
    procedure TestReport_InstanceRunRequestPage_LeavesTheControlValueOnTheInstance()
    var
        InstReport: Report "Test Rpt InstRunReqPage";
        Parameters: Text;
    begin
        // The observable that exists only on the instance form: the handler writes the
        // EchoText request-page control, and the caller — which still holds the report —
        // reads the report global that control is bound to.
        Initialize();

        Parameters := InstReport.RunRequestPage();

        if Parameters = '' then
            Error('The instance RunRequestPage returned no parameters, so nothing ran.');
        if InstReport.GetEchoText() <> 'set-by-handler' then
            Error('The value the handler wrote into the request page did not reach the report instance the caller holds: got "%1", expected "set-by-handler".',
                InstReport.GetEchoText());
    end;

    [Test]
    [HandlerFunctions('CancellingInstanceHandler')]
    procedure TestReport_InstanceRunRequestPage_CancelledReturnsNoParameters()
    var
        InstReport: Report "Test Rpt InstRunReqPage";
        LogRec: Record "Test Rpt RunReqPage Log";
        Parameters: Text;
    begin
        Initialize();

        Parameters := InstReport.RunRequestPage();

        if LogRec.MarkerCount('inst-rp-open') <> 1 then
            Error('The request page never opened, so its OnOpenPage never ran: expected exactly 1 inst-rp-open log row, got %1.',
                LogRec.MarkerCount('inst-rp-open'));
        if not HandlerCancelled then
            Error('The cancelling [RequestPageHandler] never ran.');
        if Parameters <> '' then
            Error('A cancelled request page must yield no parameters, got: %1', Parameters);
    end;

    [Test]
    [HandlerFunctions('ConfirmingInstanceHandler')]
    procedure TestReport_InstanceRunRequestPage_SeededWithParameters_StillRunsTheHandler()
    var
        InstReport: Report "Test Rpt InstRunReqPage";
        SeedReport: Report "Test Rpt InstRunReqPage";
        LogRec: Record "Test Rpt RunReqPage Log";
        Seed: Text;
        Parameters: Text;
    begin
        // The second instance overload takes a parameters string. Capture one from a first
        // run, then hand it back: the handler still runs and the filter still comes back, so
        // the seeded overload is not a silently different code path.
        Initialize();
        Seed := SeedReport.RunRequestPage();
        if Seed = '' then
            Error('Could not capture a parameters string to seed the second call with.');

        LogRec.DeleteAll();
        HandlerRan := false;
        Commit();

        Parameters := InstReport.RunRequestPage(Seed);

        if LogRec.MarkerCount('inst-rp-open') <> 1 then
            Error('The seeded instance RunRequestPage did not open the request page: expected exactly 1 inst-rp-open log row, got %1.',
                LogRec.MarkerCount('inst-rp-open'));
        if not HandlerRan then
            Error('The [RequestPageHandler] never ran on the seeded call.');
        if StrPos(Parameters, 'WHERE(Field1=1') = 0 then
            Error('The filter the handler set did not survive the seeded call: %1', Parameters);
    end;

    [RequestPageHandler]
    procedure ConfirmingInstanceHandler(var RequestPage: TestRequestPage "Test Rpt InstRunReqPage")
    begin
        HandlerRan := true;
        RequestPage.EchoText.SetValue('set-by-handler');
        // Stands in for the user narrowing the report to a single row.
        RequestPage.Rows.SetFilter("Entry No.", '1');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancellingInstanceHandler(var RequestPage: TestRequestPage "Test Rpt InstRunReqPage")
    begin
        HandlerCancelled := true;
        RequestPage.Cancel().Invoke();
    end;
}
