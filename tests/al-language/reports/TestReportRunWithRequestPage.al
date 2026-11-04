// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-run-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                Test Rpt RunReqPage Report (60543), Test Rpt RunReqPage Dataset (60544)
//
// Report.Run() on a report INSTANCE, under test, and the request page it opens on the way.
//
// TestReportRunRequestPage.al already pins Report.RunRequestPage — the explicit,
// parameters-capturing entry point that never runs the report body. This file pins the far
// more common shape: a test that never mentions the request page at all, declares a
// [RequestPageHandler] and calls Report.Run(). The request page is still opened, the handler
// is still what closes it, and how it closes decides whether the body runs at all.
//
// Three claims, each separable from the others:
//
//   1. Run() opens the request page, routes it to the declared handler, and — when the
//      handler confirms — runs the report body over every seeded row.
//   2. A handler that CANCELS stops the report: the page still opened, the handler still
//      ran, and the body executed zero times. No error is raised — cancelling a request
//      page is an ordinary outcome, not a failure. Claims 1 and 2 are the pair that matters:
//      a runner that ignored the request page entirely would iterate in BOTH cases, so only
//      "2 rows when confirmed, 0 when cancelled" proves the handler decided the outcome.
//   3. Plain OK is not even available on the request page of a report that is NOT
//      ProcessingOnly. OK carries no report intent — no preview, no print, no save — and BC
//      does not offer it there, so invoking it fails with "The built-in action = OK is not
//      found on the page." Pinned because it is the boundary of claim 1: OK is a
//      processing-only report's confirmation, not a universal one.
//
// TWO MEASURED FACTS THIS FILE ENCODES, both of which contradicted the obvious guess and
// were settled by this repo's CI on all eight BC versions:
//
//   * After Report.Run(), the caller's report variable does NOT carry the report's globals
//     back — Probe.RowsProcessed() reads 0 even when the body iterated every row. Row counts
//     are therefore taken from the "Test Rpt RunReqPage Log" table, which a table write makes
//     visible regardless of which instance executed. TestReportRunExecution.al documents the
//     same channel for the static Report.Run forms.
//   * A non-ProcessingOnly report's request page has no OK action at all — BC raises rather
//     than accepting a bare confirmation, and the message names the missing action.
//
// [RequestPageHandler] bodies run in a read-only negotiation context (real BC raises
// "A transaction must be started before changes can be made to the database" for a write
// attempted inside one), so proof that a handler ran is carried on codeunit globals; only
// the report's own triggers, which run in the report's execution scope, write to the log.

codeunit 60933 "Test Report Run RequestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerRan: Boolean;
        HandlerCancelled: Boolean;
        HandlerConfirmedPlainOK: Boolean;

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
        HandlerConfirmedPlainOK := false;
        // Report.Run opens its own execution/UI scope, same as RunModal — real BC refuses to
        // do that while this transaction still has the writes above pending.
        Commit();
    end;

    [Test]
    [HandlerFunctions('RunConfirmingRequestPageHandler')]
    procedure Report_Run_OpensTheRequestPageAndRunsTheBodyWhenTheHandlerConfirms()
    var
        Probe: Report "Test Rpt RunReqPage Report";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();
        Clear(Probe);

        Probe.Run();

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('Report.Run() did not open the request page: expected exactly 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerRan then
            Error('Report.Run() opened the request page but never routed it to the declared [RequestPageHandler].');
        // Two rows are seeded. A confirmed request page runs the body over both.
        if LogRec.MarkerCount('rp-row') <> 2 then
            Error('Expected the report body to run over both seeded rows after the handler confirmed, got %1 rp-row log rows.',
                LogRec.MarkerCount('rp-row'));
    end;

    [Test]
    [HandlerFunctions('RunCancellingRequestPageHandler')]
    procedure Report_Run_CancelledRequestPageRunsNothingAndRaisesNoError()
    var
        Probe: Report "Test Rpt RunReqPage Report";
        LogRec: Record "Test Rpt RunReqPage Log";
    begin
        Initialize();
        Clear(Probe);

        // No asserterror: a cancelled request page is a normal outcome of Run(), not a failure.
        Probe.Run();

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('The request page never opened, so "cancelled" cannot be told apart from "never ran": expected 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerCancelled then
            Error('The cancelling [RequestPageHandler] never ran.');
        // The same two rows the confirming test iterates. Zero here is what makes that test
        // mean something: the handler, not the platform, decided whether the body executed.
        if LogRec.MarkerCount('rp-row') <> 0 then
            Error('A cancelled request page must leave the report body unexecuted, but %1 rp-row log rows were written.',
                LogRec.MarkerCount('rp-row'));
    end;

    [Test]
    [HandlerFunctions('RunPlainOKRequestPageHandler')]
    procedure Report_Run_NonProcessingOnlyRequestPageHasNoOKAction()
    var
        Probe: Report "Test Rpt RunReqPage Dataset";
    begin
        // "Test Rpt RunReqPage Dataset" has a rendering layout and is NOT ProcessingOnly, so
        // its request page offers output choices rather than a bare confirmation. Invoking OK
        // on it fails because that action is not there — not because BC ran and then objected.
        Initialize();
        Clear(Probe);

        asserterror Probe.Run();

        if not HandlerConfirmedPlainOK then
            Error('The [RequestPageHandler] never ran, so the error did not come from the OK it invoked: %1', GetLastErrorText());
        if StrPos(GetLastErrorText(), 'built-in action = OK is not found') = 0 then
            Error('Expected BC to report OK as a missing built-in action on a non-ProcessingOnly request page, got: %1', GetLastErrorText());
    end;

    [RequestPageHandler]
    procedure RunConfirmingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerRan := true;
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure RunCancellingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerCancelled := true;
        RequestPage.Cancel().Invoke();
    end;

    [RequestPageHandler]
    procedure RunPlainOKRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Dataset")
    begin
        HandlerConfirmedPlainOK := true;
        RequestPage.OK().Invoke();
    end;
}
