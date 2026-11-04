// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/reportinstance-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects of CiReportFixtures.al (84580-84591); Base Application tables G/L Account and Report Layout Selection
// Probe: corpus issue 667 items 129-144 (odd AL behavior leads, reports). Every literal asserted below is what a local BC 29.0.54011.55816 tier produced;
// 27 and 28 are checked by the corpus CI legs. One test codeunit only: the SingleInstance log 84581 is shared by every report of this folder.
// Facts: UI and report calls in OnPostReport (microsoft/AL#5938); Run/RunModal/Execute/Print/SaveAs with an Excel layout, also one picked by name
// (microsoft/AL#8067); the variable after Run, RunModal and Execute; variable Execute(Parameters) against Report.Execute(Id, Parameters)
// (microsoft/AL#5710); RunRequestPage of a report without a layout; Execute and Print with text that is not XML; Report.Run with a request page
// after a write (microsoft/AL#7944); SetTableView with a record of another table; CurrReport.TargetFormat and PageNo under SaveAs of each format;
// an invalid CurrReport.FormatRegion; SaveAs of an unknown report id; SaveAs formats without a matching layout; SaveAs of a G/L Account data item
// filtered on a decimal FlowField (microsoft/AL#7224).
// BC versions: 27, 28, 29

codeunit 84592 "LT CI Report Run Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        L: Codeunit "LT CI Log";

    local procedure Start(Mode: Integer)
    begin
        L.Take();
        L.SetMode(Mode);
    end;

    local procedure Outcome(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name, Format(Ok));
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', L.Take());
    end;

    [TryFunction]
    local procedure TryRunPostUi()
    begin
        Report.Run(Report::"LT CI PostUi Rpt");
    end;

    [TryFunction]
    local procedure TryRunId(ReportId: Integer)
    begin
        Report.Run(ReportId);
    end;

    [TryFunction]
    local procedure TryRunModalId(ReportId: Integer)
    begin
        Report.RunModal(ReportId);
    end;

    [TryFunction]
    local procedure TryExecuteId(ReportId: Integer; Parameters: Text)
    begin
        Report.Execute(ReportId, Parameters);
    end;

    [TryFunction]
    local procedure TryPrintId(ReportId: Integer; Parameters: Text)
    begin
        Report.Print(ReportId, Parameters, '');
    end;

    [TryFunction]
    local procedure TrySaveAsId(ReportId: Integer; Fmt: ReportFormat; var Result: Text)
    var
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Result := Format(Report.SaveAs(ReportId, '', Fmt, OutS)) + ' length>0=' + Format(TempBlob.Length() > 0);
    end;

    [TryFunction]
    local procedure TryRequestPage(ReportId: Integer; var Parameters: Text)
    begin
        Parameters := Report.RunRequestPage(ReportId);
    end;

    // Item 131: Page.Run in OnPostReport, with a page handler.
    [Test]
    [HandlerFunctions('CardHandler')]
    procedure PostReport_PageRun_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(1);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'post begin;page OnOpenPage;page handler;post end;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_PageRun_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(1);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'Unhandled UI: Page 84582');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('run log', 'post begin;');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure PostReport_PageRunModal_WithHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'post begin;page OnOpenPage;modal handler;runmodal=LookupCancel;post end;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_PageRunModal_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(2);
        Outcome(Observer, 'run', TryRunPostUi());
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'Unhandled UI: ModalPage 84582');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Expect('run log', 'post begin;');
        Observer.Verify();
    end;

    [Test]
    procedure PostReport_ReportRun_ReportRunModal_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(3);
        Outcome(Observer, 'report run', TryRunPostUi());
        L.SetMode(4);
        Outcome(Observer, 'report runmodal', TryRunPostUi());
        L.SetMode(5);
        Outcome(Observer, 'report saveas', TryRunPostUi());
        Observer.Expect('report run', 'Yes');
        Observer.Expect('report run|text', '');
        Observer.Expect('report run|code', '');
        Observer.Expect('report run log', 'post begin;plain pre;post end;');
        Observer.Expect('report runmodal', 'Yes');
        Observer.Expect('report runmodal|text', '');
        Observer.Expect('report runmodal|code', '');
        Observer.Expect('report runmodal log', 'post begin;plain pre;post end;');
        Observer.Expect('report saveas', 'Yes');
        Observer.Expect('report saveas|text', '');
        Observer.Expect('report saveas|code', '');
        Observer.Expect('report saveas log', 'post begin;pre targetformat=Xml;post;saveas=Yes length>0=Yes;post end;');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT CI Row Card")
    begin
        L.Add('page handler');
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Card: TestPage "LT CI Row Card")
    begin
        L.Add('modal handler');
    end;

    // Item 133: an Excel layout picked by name through Report Layout Selection, on a report whose default layout is Word.
    [Test]
    procedure ExcelLayoutByName_Run_RunModal_Execute_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        ReportLayoutSelection: Record "Report Layout Selection";
        Result: Text;
    begin
        Start(0);
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'run', TryRunId(Report::"LT CI Layouts Rpt"));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'runmodal', TryRunModalId(Report::"LT CI Layouts Rpt"));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI Layouts Rpt", ''));
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Outcome(Observer, 'saveas excel', TrySaveAsId(Report::"LT CI Layouts Rpt", ReportFormat::Excel, Result));
        Observer.Observe('saveas excel result', Result);
        ReportLayoutSelection.SetTempLayoutSelectedName('LtCiLayoutsExcel');
        Result := '';
        Outcome(Observer, 'saveas pdf', TrySaveAsId(Report::"LT CI Layouts Rpt", ReportFormat::Pdf, Result));
        Observer.Observe('saveas pdf result', Result);
        Observer.Observe('selected after', ReportLayoutSelection.GetTempSelectedLayoutName());
        ReportLayoutSelection.ClearTempLayoutSelected();
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('run|code', 'ReportUnsupportedOperation');
        Observer.Expect('run log', '');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('runmodal|code', 'ReportUnsupportedOperation');
        Observer.Expect('runmodal log', '');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('execute|code', 'ReportUnsupportedOperation');
        Observer.Expect('execute log', '');
        Observer.Expect('saveas excel', 'Yes');
        Observer.Expect('saveas excel|text', '');
        Observer.Expect('saveas excel|code', '');
        Observer.Expect('saveas excel log', 'pre targetformat=Excel;post pagenos=1,;');
        Observer.Expect('saveas excel result', 'Yes length>0=Yes');
        Observer.Expect('saveas pdf', 'Yes');
        Observer.Expect('saveas pdf|text', 'The Pdf output format is not supported by the current report layout format.');
        Observer.Expect('saveas pdf|code', 'ReportUnsupportedFormat');
        Observer.Expect('saveas pdf log', '');
        Observer.Expect('saveas pdf result', 'No length>0=No');
        Observer.Expect('selected after', '');
        Observer.Verify();
    end;

    // Items 133 and 139: a report whose only layout is Excel.
    [Test]
    procedure ExcelOnly_Run_RunModal_Execute_Print_SaveAs()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Start(0);
        Outcome(Observer, 'run', TryRunId(Report::"LT CI ExcelOnly Rpt"));
        Outcome(Observer, 'runmodal', TryRunModalId(Report::"LT CI ExcelOnly Rpt"));
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI ExcelOnly Rpt", ''));
        Outcome(Observer, 'print', TryPrintId(Report::"LT CI ExcelOnly Rpt", ''));
        Outcome(Observer, 'saveas excel', TrySaveAsId(Report::"LT CI ExcelOnly Rpt", ReportFormat::Excel, Result));
        Observer.Observe('saveas excel result', Result);
        Result := '';
        Outcome(Observer, 'saveas word', TrySaveAsId(Report::"LT CI ExcelOnly Rpt", ReportFormat::Word, Result));
        Observer.Observe('saveas word result', Result);
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('run|code', 'ReportUnsupportedOperation');
        Observer.Expect('run log', '');
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('runmodal|code', 'ReportUnsupportedOperation');
        Observer.Expect('runmodal log', '');
        Observer.Expect('execute', 'No');
        Observer.Expect('execute|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('execute|code', 'ReportUnsupportedOperation');
        Observer.Expect('execute log', '');
        Observer.Expect('print', 'No');
        Observer.Expect('print|text', 'The current report operation is not supported for Excel Layout reports.');
        Observer.Expect('print|code', 'ReportUnsupportedOperation');
        Observer.Expect('print log', '');
        Observer.Expect('saveas excel', 'Yes');
        Observer.Expect('saveas excel|text', '');
        Observer.Expect('saveas excel|code', '');
        Observer.Expect('saveas excel log', 'excel pre targetformat=Excel;');
        Observer.Expect('saveas excel result', 'Yes length>0=Yes');
        Observer.Expect('saveas word', 'Yes');
        Observer.Expect('saveas word|text', 'The Word output format is not supported by the current report layout format.');
        Observer.Expect('saveas word|code', 'ReportUnsupportedFormat');
        Observer.Expect('saveas word log', '');
        Observer.Expect('saveas word result', 'No length>0=No');
        Observer.Verify();
    end;

    // Item 139: Execute and Print with parameters that are not XML.
    [Test]
    procedure Execute_Print_ParametersNotXml()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        Outcome(Observer, 'execute', TryExecuteId(Report::"LT CI Plain Rpt", 'this is not xml'));
        Outcome(Observer, 'print', TryPrintId(Report::"LT CI Plain Rpt", 'this is not xml'));
        Outcome(Observer, 'execute unknown', TryExecuteId(71999, 'this is not xml'));
        Observer.Expect('execute', 'Yes');
        Observer.Expect('execute|text', '');
        Observer.Expect('execute|code', '');
        Observer.Expect('execute log', 'plain pre;');
        Observer.Expect('print', 'Yes');
        Observer.Expect('print|text', '');
        Observer.Expect('print|code', '');
        Observer.Expect('print log', 'plain pre;');
        Observer.Expect('execute unknown', 'No');
        Observer.Expect('execute unknown|text', 'You tried to invoke the Report object with the ID 71999 from the object LT CI Report Run Leads. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('execute unknown|code', 'AL:MetadataNotFound');
        Observer.Expect('execute unknown log', '');
        Observer.Verify();
    end;

    // Item 138: RunRequestPage of a report that has no layout and UseRequestPage = false (no handler).
    [Test]
    procedure NoLayout_RunRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Parameters: Text;
    begin
        Start(0);
        Outcome(Observer, 'requestpage', TryRequestPage(Report::"LT CI NoLayout Rpt", Parameters));
        Observer.Observe('parameters', Parameters);
        Observer.Expect('requestpage', 'No');
        Observer.Expect('requestpage|text', 'Unhandled UI: RequestPage 84583');
        Observer.Expect('requestpage|code', 'MissingUIHandler');
        Observer.Expect('requestpage log', '');
        Observer.Expect('parameters', '');
        Observer.Verify();
    end;

    // Item 136: the variable after RunModal, Run and Execute (globals set by a procedure and by the request page handler).
    [Test]
    procedure Variable_AfterRunModal_Run_Execute_NoRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        RunModalRpt: Report "LT CI Opt Rpt";
        RunRpt: Report "LT CI Opt Rpt";
        ExecuteRpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        RunModalRpt.SetOpt('o1');
        RunModalRpt.SetMarker('m1');
        RunModalRpt.UseRequestPage(false);
        RunModalRpt.RunModal();
        Observer.Observe('runmodal after', 'opt=[' + RunModalRpt.GetOpt() + '] marker=[' + RunModalRpt.GetMarker() + ']');
        Observer.Observe('runmodal log', L.Take());
        RunRpt.SetOpt('o2');
        RunRpt.SetMarker('m2');
        RunRpt.UseRequestPage(false);
        RunRpt.Run();
        Observer.Observe('run after', 'opt=[' + RunRpt.GetOpt() + '] marker=[' + RunRpt.GetMarker() + ']');
        Observer.Observe('run log', L.Take());
        ExecuteRpt.SetOpt('o3');
        ExecuteRpt.SetMarker('m3');
        ExecuteRpt.Execute('');
        Observer.Observe('execute after', 'opt=[' + ExecuteRpt.GetOpt() + '] marker=[' + ExecuteRpt.GetMarker() + ']');
        Observer.Observe('execute log', L.Take());
        Observer.Expect('runmodal after', 'opt=[o1] marker=[m1]');
        Observer.Expect('runmodal log', 'pre opt=[o1] marker=[m1];');
        Observer.Expect('run after', 'opt=[] marker=[]');
        Observer.Expect('run log', 'pre opt=[o2] marker=[m2];');
        Observer.Expect('execute after', 'opt=[o3] marker=[m3]');
        Observer.Expect('execute log', 'pre opt=[o3] marker=[m3];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Variable_AfterRunModal_WithRequestPageValue()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        Rpt.SetMarker('m1');
        Rpt.RunModal();
        Observer.Observe('runmodal after', 'opt=[' + Rpt.GetOpt() + '] marker=[' + Rpt.GetMarker() + ']');
        Observer.Observe('runmodal log', L.Take());
        Observer.Expect('runmodal after', 'opt=[typed] marker=[m1]');
        Observer.Expect('runmodal log', 'handler opt=[];pre opt=[typed] marker=[m1];');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Variable_AfterRun_WithRequestPageValue()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
    begin
        Start(0);
        Rpt.SetMarker('m1');
        Rpt.Run();
        Observer.Observe('run after', 'opt=[' + Rpt.GetOpt() + '] marker=[' + Rpt.GetMarker() + ']');
        Observer.Observe('run log', L.Take());
        Observer.Expect('run after', 'opt=[] marker=[]');
        Observer.Expect('run log', 'handler opt=[];pre opt=[typed] marker=[m1];');
        Observer.Verify();
    end;

    // Item 137: parameters from RunRequestPage passed to Report.Execute(Id, Parameters) and to a variable's Execute(Parameters).
    [Test]
    [HandlerFunctions('OptTypedHandler')]
    procedure Execute_Parameters_StaticAndVariable()
    var
        Observer: Codeunit "Probe Observer";
        Rpt: Report "LT CI Opt Rpt";
        Preset: Report "LT CI Opt Rpt";
        Parameters: Text;
    begin
        Start(0);
        Parameters := Report.RunRequestPage(Report::"LT CI Opt Rpt");
        Observer.Observe('requestpage log', L.Take());
        Report.Execute(Report::"LT CI Opt Rpt", Parameters);
        Observer.Observe('static log', L.Take());
        Rpt.Execute(Parameters);
        Observer.Observe('variable log', L.Take());
        Observer.Observe('variable after', Rpt.GetOpt());
        Preset.SetOpt('preset');
        Preset.Execute(Parameters);
        Observer.Observe('preset log', L.Take());
        Observer.Expect('requestpage log', 'handler opt=[];');
        Observer.Expect('static log', 'pre opt=[typed] marker=[];');
        Observer.Expect('variable log', 'pre opt=[typed] marker=[];');
        Observer.Expect('variable after', 'typed');
        Observer.Expect('preset log', 'pre opt=[typed] marker=[];');
        Observer.Verify();
    end;

    [RequestPageHandler]
    procedure OptTypedHandler(var RP: TestRequestPage "LT CI Opt Rpt")
    begin
        L.Add('handler opt=[' + RP.OptTextCtl.Value() + ']');
        RP.OptTextCtl.SetValue('typed');
        RP.OK().Invoke();
    end;

    // Item 143: Report.Run with and without a request page while the test has an uncommitted write. With the request page the call fails before
    // the page opens: a request page handler is never called (the test runner then reports it as not executed), so these tests declare none.
    [Test]
    procedure PendingWrite_ReportRun_WithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'run', TryRunTx(true, Row));
        Observer.Expect('run', 'No');
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('run log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_ReportRun_WithRequestPage_AssertError()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        asserterror Report.Run(Report::"LT CI Tx Rpt", true, false, Row);
        Observer.ObserveError('run');
        Observer.Observe('run log', L.Take());
        Observer.Expect('run|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('run|code', 'DB:Ok');
        Observer.Expect('run log', '');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_ReportRun_WithoutRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'run', TryRunTx(false, Row));
        Outcome(Observer, 'runmodal', TryRunModalTx(false, Row));
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'pre filter=[1];row 1;');
        Observer.Expect('runmodal', 'Yes');
        Observer.Expect('runmodal|text', '');
        Observer.Expect('runmodal|code', '');
        Observer.Expect('runmodal log', 'pre filter=[1];row 1;');
        Observer.Verify();
    end;

    [Test]
    procedure PendingWrite_ReportRunModal_WithRequestPage()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
    begin
        Start(0);
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.SetRange(Id, 1);
        Outcome(Observer, 'runmodal', TryRunModalTx(true, Row));
        Observer.Expect('runmodal', 'No');
        Observer.Expect('runmodal|text', 'An error occurred and the transaction is stopped. Contact your administrator or partner for further assistance.');
        Observer.Expect('runmodal|code', 'DB:Ok');
        Observer.Expect('runmodal log', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunTx(RequestWindow: Boolean; var Row: Record "LT CI Row")
    begin
        Report.Run(Report::"LT CI Tx Rpt", RequestWindow, false, Row);
    end;

    [TryFunction]
    local procedure TryRunModalTx(RequestWindow: Boolean; var Row: Record "LT CI Row")
    begin
        Report.RunModal(Report::"LT CI Tx Rpt", RequestWindow, false, Row);
    end;


    // Item 135: SetTableView with a record of a table that is no data item of the report.
    [Test]
    procedure SetTableView_RecordOfAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CI Row";
        Other: Record "Report Layout Selection";
        Rpt: Report "LT CI Tx Rpt";
    begin
        Start(0);
        Other.SetRange("Report ID", 1);
        asserterror Rpt.SetTableView(Other);
        Observer.ObserveError('settableview');
        // The rows are inserted after asserterror, which rolls back the writes made before it.
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Insert();
        Rpt.UseRequestPage(false);
        Outcome(Observer, 'run', TryRunVariable(Rpt));
        Observer.Expect('settableview|text', 'The LT CI Tx Rpt report does not have a DataItem that uses the table (Table 9651 Report Layout Selection) specified in the function SetTableView.');
        Observer.Expect('settableview|code', 'ReportNoDataItem');
        Observer.Expect('run', 'Yes');
        Observer.Expect('run|text', '');
        Observer.Expect('run|code', '');
        Observer.Expect('run log', 'pre filter=[];row 1;row 2;');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryRunVariable(var Rpt: Report "LT CI Tx Rpt")
    begin
        Rpt.RunModal();
    end;

    local procedure SaveAs(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; Fmt: ReportFormat)
    var
        Result: Text;
    begin
        Observer.Observe(Name, Format(TrySaveAsId(ReportId, Fmt, Result)));
        Observer.Observe(Name + ' result', Result);
        Observer.ObserveError(Name);
        Observer.Observe(Name + ' log', L.Take());
    end;

    local procedure SeedRows(Count: Integer)
    var
        Row: Record "LT CI Row";
        i: Integer;
    begin
        Row.DeleteAll();
        for i := 1 to Count do begin
            Row.Id := i;
            Row.Insert();
        end;
    end;

    // Items 134 and 140: TargetFormat and PageNo under SaveAs, per format.
    [Test]
    procedure TargetFormat_PageNo_WordDefaultLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SaveAs(Observer, 'pdf', Report::"LT CI Layouts Rpt", ReportFormat::Pdf);
        SaveAs(Observer, 'word', Report::"LT CI Layouts Rpt", ReportFormat::Word);
        SaveAs(Observer, 'excel', Report::"LT CI Layouts Rpt", ReportFormat::Excel);
        SaveAs(Observer, 'html', Report::"LT CI Layouts Rpt", ReportFormat::Html);
        SaveAs(Observer, 'xml', Report::"LT CI Layouts Rpt", ReportFormat::Xml);
        Observer.Expect('pdf', 'Yes');
        Observer.Expect('pdf result', 'Yes length>0=Yes');
        Observer.Expect('pdf|text', '');
        Observer.Expect('pdf|code', '');
        Observer.Expect('pdf log', 'pre targetformat=Pdf;post pagenos=1,;');
        Observer.Expect('word', 'Yes');
        Observer.Expect('word result', 'Yes length>0=Yes');
        Observer.Expect('word|text', '');
        Observer.Expect('word|code', '');
        Observer.Expect('word log', 'pre targetformat=Word;post pagenos=1,;');
        Observer.Expect('excel', 'Yes');
        Observer.Expect('excel result', 'No length>0=No');
        Observer.Expect('excel|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('excel|code', 'ReportUnsupportedFormat');
        Observer.Expect('excel log', '');
        Observer.Expect('html', 'Yes');
        Observer.Expect('html result', 'Yes length>0=Yes');
        Observer.Expect('html|text', '');
        Observer.Expect('html|code', '');
        Observer.Expect('html log', 'pre targetformat=Html;post pagenos=1,;');
        Observer.Expect('xml', 'Yes');
        Observer.Expect('xml result', 'Yes length>0=Yes');
        Observer.Expect('xml|text', '');
        Observer.Expect('xml|code', '');
        Observer.Expect('xml log', 'pre targetformat=Xml;post pagenos=1,;');
        Observer.Verify();
    end;

    [Test]
    procedure TargetFormat_PageNo_NoLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SeedRows(3);
        SaveAs(Observer, 'xml', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        SaveAs(Observer, 'pdf', Report::"LT CI NoLayout Rpt", ReportFormat::Pdf);
        Observer.Expect('xml', 'Yes');
        Observer.Expect('xml result', 'Yes length>0=Yes');
        Observer.Expect('xml|text', '');
        Observer.Expect('xml|code', '');
        Observer.Expect('xml log', 'pre targetformat=Xml;row 1 pageno=1;row 2 pageno=1;row 3 pageno=1;post;');
        Observer.Expect('pdf', 'Yes');
        Observer.Expect('pdf result', 'No length>0=No');
        Observer.Expect('pdf|text', 'Report 84583 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.');
        Observer.Expect('pdf|code', 'ReportNoLayout');
        Observer.Expect('pdf log', '');
        Observer.Verify();
    end;

    // Item 144: SaveAs Html of an RDLC-only report, SaveAs Pdf and Html of an Excel-only report.
    [Test]
    procedure SaveAs_FormatsWithoutMatchingLayout()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        // SaveAs Word and Excel of the RDLC-only report: SaveAs_RdlcOnly_WordExcel below (held on Linux).
        SaveAs(Observer, 'rdlc html', Report::"LT CI Rdlc Rpt", ReportFormat::Html);
        SaveAs(Observer, 'excelonly pdf', Report::"LT CI ExcelOnly Rpt", ReportFormat::Pdf);
        SaveAs(Observer, 'excelonly html', Report::"LT CI ExcelOnly Rpt", ReportFormat::Html);
        Observer.Expect('rdlc html', 'Yes');
        Observer.Expect('rdlc html result', 'No length>0=No');
        Observer.Expect('rdlc html|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('rdlc html|code', 'ReportUnsupportedFormat');
        Observer.Expect('rdlc html log', '');
        Observer.Expect('excelonly pdf', 'Yes');
        Observer.Expect('excelonly pdf result', 'No length>0=No');
        Observer.Expect('excelonly pdf|text', 'The Pdf output format is not supported by the current report layout format.');
        Observer.Expect('excelonly pdf|code', 'ReportUnsupportedFormat');
        Observer.Expect('excelonly pdf log', '');
        Observer.Expect('excelonly html', 'Yes');
        Observer.Expect('excelonly html result', 'No length>0=No');
        Observer.Expect('excelonly html|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('excelonly html|code', 'ReportUnsupportedFormat');
        Observer.Expect('excelonly html log', '');
        Observer.Verify();
    end;

    // Item 144: SaveAs Word and Excel of the RDLC-only report render the RDLC layout. Windows BC 27.5/28.5/29.0 (Windows checks 2026-10-20;
    // 29.0 gives the same values); before the bc-linux fixes the Linux image failed RDLC to Word/Excel (bc-linux #144; BC 29.0: renderer off at boot,
    // bc-linux #143).
    [Test]
    procedure SaveAs_RdlcOnly_WordExcel()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Start(0);
        SaveAs(Observer, 'rdlc word', Report::"LT CI Rdlc Rpt", ReportFormat::Word);
        SaveAs(Observer, 'rdlc excel', Report::"LT CI Rdlc Rpt", ReportFormat::Excel);
        Observer.Expect('rdlc word', 'Yes');
        Observer.Expect('rdlc word result', 'Yes length>0=Yes');
        Observer.Expect('rdlc word|text', '');
        Observer.Expect('rdlc word|code', '');
        Observer.Expect('rdlc word log', 'rdlc pre targetformat=Word;');
        Observer.Expect('rdlc excel', 'Yes');
        Observer.Expect('rdlc excel result', 'Yes length>0=Yes');
        Observer.Expect('rdlc excel|text', '');
        Observer.Expect('rdlc excel|code', '');
        Observer.Expect('rdlc excel log', 'rdlc pre targetformat=Excel;');
        Observer.Verify();
    end;

    // Item 140: CurrReport.FormatRegion set to an unknown name, to empty, and to de-DE in OnPreReport.
    [Test]
    procedure FormatRegion_Invalid_Empty_Valid()
    var
        Observer: Codeunit "Probe Observer";
    begin
        SeedRows(1);
        Start(1);
        SaveAs(Observer, 'invalid', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Start(2);
        SaveAs(Observer, 'empty', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Start(3);
        SaveAs(Observer, 'de-DE', Report::"LT CI NoLayout Rpt", ReportFormat::Xml);
        Observer.Expect('invalid', 'Yes');
        Observer.Expect('invalid result', 'No length>0=No');
        Observer.Expect('invalid|text', 'An unsupported language was selected (''xx-NOPE'' - ''Requested culture is not supported by the current platform'').');
        Observer.Expect('invalid|code', 'ReportFormatCultureNotFound');
        Observer.Expect('invalid log', 'pre targetformat=Xml;');
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty result', 'No length>0=No');
        Observer.Expect('empty|text', 'Invalid language ID supplied: 0.');
        Observer.Expect('empty|code', 'Argument');
        Observer.Expect('empty log', 'pre targetformat=Xml;');
        Observer.Expect('de-DE', 'Yes');
        Observer.Expect('de-DE result', 'Yes length>0=Yes');
        Observer.Expect('de-DE|text', '');
        Observer.Expect('de-DE|code', '');
        Observer.Expect('de-DE log', 'pre targetformat=Xml;region=[de-DE] dec=1.234,5;row 1 pageno=1;post;');
        Observer.Verify();
    end;

    // Item 144: SaveAs of a report id that does not exist, caught by a TryFunction and by asserterror.
    [Test]
    procedure SaveAs_UnknownId()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
    begin
        Start(0);
        Observer.Observe('try', Format(TrySaveAsId(71999, ReportFormat::Xml, Result)));
        Observer.Observe('try result', Result);
        // The text starts and ends with line breaks and indentation: only its first sentence is asserted.
        Observer.Observe('try text has', Format(GetLastErrorText().Contains('The metadata object Report 71999 was not found.')));
        Observer.Observe('try code', GetLastErrorCode());
        ClearLastError();
        TempBlob.CreateOutStream(OutS);
        asserterror Report.SaveAs(71999, '', ReportFormat::Pdf, OutS);
        // The object named after 'from the object' is the test codeunit or Test Runner - Mgt, depending on the run (seen on BC 27.5 and 29.0): not asserted.
        Observer.Observe('asserterror text starts', Format(GetLastErrorText().StartsWith('You tried to invoke the Report object with the ID 71999 from the object ')));
        Observer.ObserveError('asserterror');
        Observer.Expect('try', 'Yes');
        Observer.Expect('try result', 'No length>0=No');
        Observer.Expect('try text has', 'Yes');
        Observer.Expect('try code', 'MetadataNotFound');
        Observer.Expect('asserterror text starts', 'Yes');
        Observer.Ignore('asserterror|text');
        Observer.Expect('asserterror|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    // Item 132: SaveAs of a G/L Account data item with a filter on a decimal FlowField.
    [Test]
    procedure GLAccount_FilterOnDecimalFlowField()
    var
        Observer: Codeunit "Probe Observer";
        GLAccount: Record "G/L Account";
        TempBlob: Codeunit "Temp Blob";
        InS: InStream;
        OutS: OutStream;
        Xml: Text;
        Ok: Boolean;
    begin
        Start(0);
        GLAccount.Init();
        GLAccount."No." := 'LTCI-1';
        GLAccount.Name := 'LT CI';
        GLAccount.Insert(false);
        GLAccount.Reset();
        GLAccount.SetRange("No.", 'LTCI-1');
        GLAccount.SetFilter("Net Change", '0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('net change = 0', Format(Ok));
        Observer.ObserveError('net change = 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('net change = 0 has row', Format(Xml.Contains('LTCI-1')));
        Clear(TempBlob);
        Xml := '';
        GLAccount.SetFilter("Net Change", '<>0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('net change <> 0', Format(Ok));
        Observer.ObserveError('net change <> 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('net change <> 0 has row', Format(Xml.Contains('LTCI-1')));
        Clear(TempBlob);
        Xml := '';
        GLAccount.SetRange("Net Change");
        GLAccount.SetFilter(Balance, '0');
        TempBlob.CreateOutStream(OutS);
        Ok := TrySaveAsGL(GLAccount, OutS);
        Observer.Observe('balance = 0', Format(Ok));
        Observer.ObserveError('balance = 0');
        TempBlob.CreateInStream(InS);
        InS.Read(Xml);
        Observer.Observe('balance = 0 has row', Format(Xml.Contains('LTCI-1')));
        Observer.Expect('net change = 0', 'Yes');
        Observer.Expect('net change = 0|text', '');
        Observer.Expect('net change = 0|code', '');
        Observer.Expect('net change = 0 has row', 'Yes');
        Observer.Expect('net change <> 0', 'Yes');
        Observer.Expect('net change <> 0|text', '');
        Observer.Expect('net change <> 0|code', '');
        Observer.Expect('net change <> 0 has row', 'No');
        Observer.Expect('balance = 0', 'Yes');
        Observer.Expect('balance = 0|text', '');
        Observer.Expect('balance = 0|code', '');
        Observer.Expect('balance = 0 has row', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TrySaveAsGL(var GLAccount: Record "G/L Account"; var OutS: OutStream)
    var
        RecRef: RecordRef;
    begin
        RecRef.GetTable(GLAccount);
        Report.SaveAs(Report::"LT CI GL Rpt", '', ReportFormat::Xml, OutS, RecRef);
    end;
}
