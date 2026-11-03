// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: none — Base Application page 5134 "Contact Duplicates" and report 5187
//                "Generate Dupl. Search String"
//
// REPORT.Run called from Base Application code, not from this app, still hands the
// [RequestPageHandler] the report's request page.
//
// TestReportRunWithRequestPage.al pins Report.Run() called from test code. This file pins the
// same handler contract when the caller is compiled into a dependency: page 5134's action
// GenerateDuplicateSearchString runs `REPORT.Run(REPORT::"Generate Dupl. Search String")`.
// Report 5187 is ProcessingOnly, and page 5187 in Base Application is an unrelated List page
// ("Inter. Log Entry Comment Sheet"), so a handler given a page instead of the request page
// would not find the Cancel built-in action.
//
// Three claims:
//   1. The handler runs exactly once, and Cancel on the request page closes it with no error.
//   2. An error the handler raises reaches the test through the Base Application caller,
//      unchanged — the handler is really on the call path, not bypassed.
//   3. The request page of this ProcessingOnly report offers a plain OK, and confirming with it
//      runs the report with no error.
codeunit 60037 "Rpt Run Precompiled Caller"
{
    Subtype = Test;

    var
        HandlerCalls: Integer;

    [Test]
    [HandlerFunctions('CancelGenerateDuplSearchString')]
    procedure ReportRun_FromBaseAppPageAction_HandlerCancelsTheRequestPage()
    var
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        HandlerCalls := 0;
        ContactDuplicates.OpenEdit();

        ContactDuplicates.GenerateDuplicateSearchString.Invoke();

        if HandlerCalls <> 1 then
            Error('Expected the [RequestPageHandler] to run exactly once for REPORT.Run from page 5134, got %1.', HandlerCalls);
        ContactDuplicates.Close();
    end;

    [Test]
    [HandlerFunctions('FailingGenerateDuplSearchString')]
    procedure ReportRun_FromBaseAppPageAction_HandlerErrorReachesTheTest()
    var
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        HandlerCalls := 0;
        ContactDuplicates.OpenEdit();

        asserterror ContactDuplicates.GenerateDuplicateSearchString.Invoke();

        if HandlerCalls <> 1 then
            Error('Expected the failing [RequestPageHandler] to run exactly once, got %1: %2', HandlerCalls, GetLastErrorText());
        if StrPos(GetLastErrorText(), 'RPPC handler stopped the report') = 0 then
            Error('Expected the handler''s own error to reach the test, got: %1', GetLastErrorText());
    end;

    [Test]
    [HandlerFunctions('OkGenerateDuplSearchString')]
    procedure ReportRun_FromBaseAppPageAction_HandlerConfirmsOk()
    var
        ContactDuplicates: TestPage "Contact Duplicates";
    begin
        HandlerCalls := 0;
        ContactDuplicates.OpenEdit();

        ContactDuplicates.GenerateDuplicateSearchString.Invoke();

        if HandlerCalls <> 1 then
            Error('Expected the OK [RequestPageHandler] to run exactly once, got %1.', HandlerCalls);
        ContactDuplicates.Close();
    end;

    [RequestPageHandler]
    procedure CancelGenerateDuplSearchString(var RequestPage: TestRequestPage "Generate Dupl. Search String")
    begin
        HandlerCalls += 1;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure FailingGenerateDuplSearchString(var RequestPage: TestRequestPage "Generate Dupl. Search String")
    begin
        HandlerCalls += 1;
        Error('RPPC handler stopped the report');
    end;

    [RequestPageHandler]
    procedure OkGenerateDuplSearchString(var RequestPage: TestRequestPage "Generate Dupl. Search String")
    begin
        HandlerCalls += 1;
        RequestPage.OK().Invoke();
    end;
}
