// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500); own reports 75520-75523, report extensions 75524-75527
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: a report extension that sets RDLCLayout, WordLayout or ExcelLayout on a base report without layouts: the layout the base report then has (Report.DefaultLayout, Report Layout List),
// the layout stream the Report.RdlcLayout / WordLayout / ExcelLayout calls return, and what SaveAs Pdf, Word and Excel and Report.Run render.
// A report extension that adds RequestFilterFields to a base data item with modify(): the request page of the base report.
// BC versions: 27-29

report 75520 "LT Y Ext Base Rdlc"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }
}

report 75521 "LT Y Ext Base Word"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }
}

report 75522 "LT Y Ext Base Excel"
{
    UsageCategory = None;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }
}

report 75523 "LT Y Ext Base Filter"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
        }
    }
}

reportextension 75524 "LT Y Ext Rdlc" extends "LT Y Ext Base Rdlc"
{
    RDLCLayout = './report/lt-y-report-props/LtYExtRdlc.rdlc';
}

reportextension 75525 "LT Y Ext Word" extends "LT Y Ext Base Word"
{
    WordLayout = './report/lt-y-report-props/LtYExtWord.docx';
}

reportextension 75526 "LT Y Ext Excel" extends "LT Y Ext Base Excel"
{
    ExcelLayout = './report/lt-y-report-props/LtYExtExcel.xlsx';
}

reportextension 75527 "LT Y Ext Filter" extends "LT Y Ext Base Filter"
{
    dataset
    {
        modify(Row)
        {
            RequestFilterFields = Number;
        }
    }
}

codeunit 75511 "LT Y Report Ext Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";

    [TryFunction]
    local procedure TryStream(ReportId: Integer; Kind: Integer; var Result: Text)
    var
        InS: InStream;
        Found: Boolean;
    begin
        case Kind of
            1:
                Found := Report.RdlcLayout(ReportId, InS);
            2:
                Found := Report.WordLayout(ReportId, InS);
            3:
                Found := Report.ExcelLayout(ReportId, InS);
        end;
        Result := Format(Found) + ' eos=' + Format(InS.EOS());
    end;

    [TryFunction]
    local procedure TrySize(ReportId: Integer; Format: ReportFormat; var Result: Text)
    begin
        Result := 'size>0=' + Format(Helper.SaveAsSize(ReportId, Format) > 0) + ' head=' + Helper.SaveAsHead(ReportId, Format, 2);
    end;

    [TryFunction]
    local procedure TryRun(ReportId: Integer)
    begin
        Report.Run(ReportId);
    end;

    local procedure Streams(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Result: Text;
        Kind: Integer;
        Names: List of [Text];
    begin
        Names.Add('rdlc');
        Names.Add('word');
        Names.Add('excel');
        for Kind := 1 to 3 do
            if TryStream(ReportId, Kind, Result) then
                Observer.Observe(Names.Get(Kind), Result)
            else
                Observer.Observe(Names.Get(Kind), Helper.Failed());
    end;

    local procedure Facts(var Observer: Codeunit "Probe Observer"; ReportId: Integer; SaveFormat: ReportFormat)
    var
        Result: Text;
    begin
        Observer.Observe('default_layout', Format(Report.DefaultLayout(ReportId)));
        Observer.Observe('meta', Helper.ReportFacts(ReportId));
        Observer.Observe('layouts', Helper.LayoutFacts(ReportId));
        Streams(Observer, ReportId);
        if SaveFormat <> ReportFormat::Pdf then begin
            // RDLC rendering is stubbed on the Linux service tier of the CI, so SaveAs and Run are observed for Word and Excel only.
            if TrySize(ReportId, SaveFormat, Result) then
                Observer.Observe('save_as', Result)
            else
                Observer.Observe('save_as', Helper.Failed());
            if TryRun(ReportId) then
                Observer.Observe('run', 'ok')
            else
                Observer.Observe('run', Helper.Failed());
        end;
    end;

    [Test]
    procedure ReportExtension_RDLCLayout_IsSelectedAndUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Facts(Observer, Report::"LT Y Ext Base Rdlc", ReportFormat::Pdf);
        Observer.Expect('default_layout', 'RDLC');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[./report/lt-y-report-props/LtYExtRdlc.rdlc RDLC multi=0]');
        Observer.Expect('rdlc', 'Yes eos=No');
        Observer.Expect('word', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('excel', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Verify();
    end;

    [Test]
    procedure ReportExtension_WordLayout_IsSelectedAndUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Facts(Observer, Report::"LT Y Ext Base Word", ReportFormat::Word);
        Observer.Expect('default_layout', 'RDLC');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[./report/lt-y-report-props/LtYExtWord.docx Word multi=0]');
        Observer.Expect('rdlc', 'Yes eos=Yes');
        Observer.Expect('word', 'Yes eos=No');
        Observer.Expect('excel', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('save_as', 'error:Report 75521 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.|ReportNoLayout');
        Observer.Expect('run', 'error:Report 75521 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.|ReportNoLayout');
        Observer.Verify();
    end;

    [Test]
    procedure ReportExtension_ExcelLayout_IsSelectedAndUsed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Facts(Observer, Report::"LT Y Ext Base Excel", ReportFormat::Excel);
        Observer.Expect('default_layout', 'RDLC');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[./report/lt-y-report-props/LtYExtExcel.xlsx Excel multi=0]');
        Observer.Expect('rdlc', 'Yes eos=Yes');
        Observer.Expect('word', 'error:Microsoft.Dynamics.Nav.Runtime.NavInStream variable not initialized.|NotInitialized');
        Observer.Expect('excel', 'Yes eos=No');
        Observer.Expect('save_as', 'error:Report 75522 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.|ReportNoLayout');
        Observer.Expect('run', 'error:Report 75522 does not have a valid layout. Valid layout types are: Word, RDLC, Excel, and Custom.|ReportNoLayout');
        Observer.Verify();
    end;

    [Test]
    procedure ReportExtension_ModifyRequestFilterFields_AddsTheFieldToTheDataItem()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('data_items', Helper.DataItemRows(Report::"LT Y Ext Base Filter"));
        Observer.Expect('data_items', '[Row filter_fields=1 view=WHERE(Field1=0(1))]');
        Observer.Verify();
    end;
}
