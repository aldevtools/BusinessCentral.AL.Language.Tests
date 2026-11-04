// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542),
//                 Test Rpt RunReqPage Report (60543), Test Rpt RunReqPage Dataset (60544)
//
// Report.RunRequestPage under test must reach the test's own [RequestPageHandler].
//
// Running a request page for a HUMAN needs a client; running one under test does not — BC's
// test-execution path consults the declared handler first and only falls through to a client
// callback when no handler matched. AL that calls RunRequestPage to capture a report's
// RequestPageParameters XML is therefore ordinary in-scope AL.
//
// Both directions are pinned:
//   * handler confirms with OK  -> the handler body ran, the request page really
//     opened (its OnOpenPage logged), and the data-item filter the handler set survives
//     into the returned parameters XML;
//   * handler cancels           -> BC returns an empty parameters string, while the page
//     still opened and the handler still ran, so "cancelled" is distinguishable from
//     "never ran".

codeunit 60545 "Test Report RunRequestPage"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // [RequestPageHandler] callbacks execute in a read-only negotiation context —
    // real BC raises "A transaction must be started before changes can be made to the
    // database" for any database write attempted from inside one. The report's own
    // OnOpenPage trigger runs in the report's real execution scope and can write fine
    // (see 'rp-open' via the Log table below), but the handler itself cannot, so proof
    // that the handler ran is carried through this codeunit-global instead — the
    // handler and the [Test] procedure that declares it run on the same codeunit
    // instance for the duration of one test, so this is ordinary AL state sharing.
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
        // Report.RunRequestPage opens its own execution/UI scope, same as RunModal —
        // real BC refuses to do that while this transaction still has the writes above
        // pending. Commit first, like Base App code does before calling into anything
        // that manages its own transaction/session scope.
        Commit();
    end;

    [Test]
    [HandlerFunctions('ConfirmingRequestPageHandler')]
    procedure TestReport_RunRequestPage_RunsTheHandlerAndReturnsTheFilterItSet()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
        Parameters: Text;
    begin
        Initialize();

        Parameters := Report.RunRequestPage(Report::"Test Rpt RunReqPage Report");

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('The request page never opened, so its OnOpenPage never ran: expected exactly 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerRan then
            Error('The [RequestPageHandler] never ran.');
        if Parameters = '' then
            Error('RunRequestPage returned an empty parameters string after the handler confirmed with OK.');
        if StrPos(Parameters, 'ReportParameters') = 0 then
            Error('Expected a ReportParameters document, got: %1', Parameters);
        // BC serialises a data item's view with useCaptions:false, so the handler's filter on
        // "Entry No." (field 1) appears as WHERE(Field1=1(1)) — the field NUMBER, not its caption.
        if StrPos(Parameters, 'DataItem name="Rows"') = 0 then
            Error('The Rows data item is missing from the parameters: %1', Parameters);
        if StrPos(Parameters, 'WHERE(Field1=1') = 0 then
            Error('The filter the handler set did not survive into the parameters: %1', Parameters);
    end;

    [Test]
    [HandlerFunctions('CancellingRequestPageHandler')]
    procedure TestReport_RunRequestPage_CancelledHandlerReturnsNoParameters()
    var
        LogRec: Record "Test Rpt RunReqPage Log";
        Parameters: Text;
    begin
        Initialize();

        Parameters := Report.RunRequestPage(Report::"Test Rpt RunReqPage Report");

        if LogRec.MarkerCount('rp-open') <> 1 then
            Error('The request page never opened, so its OnOpenPage never ran: expected exactly 1 rp-open log row, got %1.',
                LogRec.MarkerCount('rp-open'));
        if not HandlerCancelled then
            Error('The cancelling [RequestPageHandler] never ran.');
        if Parameters <> '' then
            Error('A cancelled request page must yield no parameters, got: %1', Parameters);
    end;

    [RequestPageHandler]
    procedure ConfirmingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerRan := true;
        // Stands in for the user narrowing the report: filter the Rows data item to a single
        // entry. BC serialises every data item's record view into the parameters XML, so this
        // filter is exactly what the caller of RunRequestPage must get back.
        RequestPage.Rows.SetFilter("Entry No.", '1');
        RequestPage.OK().Invoke();
    end;

    [RequestPageHandler]
    procedure CancellingRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Report")
    begin
        HandlerCancelled := true;
        RequestPage.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('DatasetReportRequestPageHandler')]
    procedure TestReport_CapturedParameters_ReplayThroughSaveAs_FilterTheDataset()
    var
        Parameters: Text;
        TempBlob: Codeunit "Temp Blob";
        DatasetOutStream: OutStream;
        DatasetInStream: InStream;
        Dataset: Text;
        Line: Text;
        Ok: Boolean;
    begin
        // The whole point of capturing parameters: hand them back to Report.SaveAs so the
        // report runs headlessly under the filter the handler chose. Pinning the round trip
        // here rather than only the capture, because a parameters string that SaveAs then
        // refuses (or silently ignores) is worth exactly nothing to a caller.
        Initialize();

        Parameters := Report.RunRequestPage(Report::"Test Rpt RunReqPage Dataset");
        if Parameters = '' then
            Error('RunRequestPage returned no parameters to replay.');

        TempBlob.CreateOutStream(DatasetOutStream);
        Ok := Report.SaveAs(Report::"Test Rpt RunReqPage Dataset", Parameters, ReportFormat::Xml, DatasetOutStream);
        if not Ok then
            Error('Report.SaveAs refused to run the report with the captured parameters: %1', Parameters);

        TempBlob.CreateInStream(DatasetInStream);
        while not DatasetInStream.EOS() do begin
            DatasetInStream.ReadText(Line);
            Dataset += Line;
        end;

        if Dataset = '' then
            Error('Report.SaveAs wrote an empty dataset even though it reported success.');
        if StrPos(Dataset, 'first') = 0 then
            Error('The filtered-in row "first" is missing from the dataset: %1', CopyStr(Dataset, 1, 400));
        if StrPos(Dataset, 'second') > 0 then
            Error('The row "second" should have been filtered OUT by the replayed parameters, but the dataset contains it: %1', CopyStr(Dataset, 1, 400));
    end;

    [RequestPageHandler]
    procedure DatasetReportRequestPageHandler(var RequestPage: TestRequestPage "Test Rpt RunReqPage Dataset")
    begin
        RequestPage.Rows.SetFilter("Entry No.", '1');
        RequestPage.OK().Invoke();
    end;
}
