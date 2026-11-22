// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-layout-list-table
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); reports "LT AM Word Rpt" and "LT AM Excel Rpt" (reports/layouts-saveas/AMReports.al, a
//   Word and an Excel layout); platform tables Tenant Report Layout and Report Layout List; own codeunit 96670.
// Probe: from the trial report al-runner 6924 (a user-defined layout that is not RDLC). The RDLC row is pinned
//   (metadata/platform-tables/UgReportLayoutList.al:287 Y17_ReportLayoutList_UserDefinedRow). The expected values are what the corpus CI legs (BC 27.5, 28.5, 29.0) returned.
// Area: a Tenant Report Layout row of Layout Format Word, and one of Layout Format Excel, stored for a report of the app; the columns of
//   its Report Layout List row, and the number of rows of that report.
// BC versions: 27.5, 28.5, 29.0 (to be measured by the corpus CI)

codeunit 96670 "LT UDL Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Columns(var Observer: Codeunit "Probe Observer"; Name: Text; ReportId: Integer; LayoutName: Text)
    var
        List: Record "Report Layout List";
        Rows: Integer;
    begin
        List.SetRange("Report ID", ReportId);
        Rows := List.Count();
        Observer.Observe(Name + ' rows in report', Format(Rows));
        List.SetRange(Name, LayoutName);
        if not List.FindFirst() then begin
            Observer.Observe(Name + ' found', 'No');
            exit;
        end;
        Observer.Observe(Name + ' caption', List.Caption);
        Observer.Observe(Name + ' format', Format(List."Layout Format"));
        Observer.Observe(Name + ' mime', List."MIME Type");
        Observer.Observe(Name + ' description', List.Description);
        Observer.Observe(Name + ' application id', Format(List."Application ID"));
        Observer.Observe(Name + ' runtime package id', Format(List."Runtime Package ID"));
        Observer.Observe(Name + ' custom type', Format(List."Custom Type"));
        Observer.Observe(Name + ' report name', List."Report Name");
        Observer.Observe(Name + ' publisher', List."Layout Publisher");
        Observer.Observe(Name + ' user defined', Format(List."User Defined"));
        Observer.Observe(Name + ' installed', Format(List.ReportIsInstalled));
        Observer.Observe(Name + ' obsolete', Format(List.IsObsolete));
        Observer.Observe(Name + ' multiple sheets', Format(List.ExcelLayoutMultipleDataSheets));
        Observer.Observe(Name + ' has layout', Format(List.Layout.HasValue()));
    end;

    [Test]
    procedure UDL_UserDefinedWordLayout_ReportLayoutListRow()
    var
        Layout: Record "Tenant Report Layout";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
    begin
        Layout.SetRange("Report ID", Report::"LT AM Word Rpt");
        Layout.DeleteAll();
        Layout.Reset();
        Layout.Init();
        Layout."Report ID" := Report::"LT AM Word Rpt";
        Layout.Name := 'LT UDL Word';
        Layout."Layout Format" := Layout."Layout Format"::Word;
        Layout.Description := 'UDL word layout';
        Report.WordLayout(Report::"LT AM Word Rpt", InS);
        Layout.Layout.ImportStream(InS, 'UDL word layout');
        Observer.Observe('insert', Format(Layout.Insert()));
        Columns(Observer, 'word', Report::"LT AM Word Rpt", 'LT UDL Word');
        Layout.SetRange("Report ID", Report::"LT AM Word Rpt");
        Layout.DeleteAll();
        Observer.Expect('insert', 'Yes');
        Observer.Expect('word rows in report', '2');
        Observer.Expect('word caption', 'LT UDL Word');
        Observer.Expect('word format', 'Word');
        Observer.Expect('word mime', '');
        Observer.Expect('word description', 'UDL word layout');
        Observer.Expect('word application id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('word runtime package id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('word custom type', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('word report name', 'LT AM Word Rpt');
        Observer.Expect('word publisher', '');
        Observer.Expect('word user defined', 'Yes');
        Observer.Expect('word installed', 'Yes');
        Observer.Expect('word obsolete', 'No');
        Observer.Expect('word multiple sheets', 'Default');
        Observer.Expect('word has layout', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure UDL_UserDefinedExcelLayout_ReportLayoutListRow()
    var
        Layout: Record "Tenant Report Layout";
        Observer: Codeunit "Probe Observer";
        InS: InStream;
    begin
        Layout.SetRange("Report ID", Report::"LT AM Excel Rpt");
        Layout.DeleteAll();
        Layout.Reset();
        Layout.Init();
        Layout."Report ID" := Report::"LT AM Excel Rpt";
        Layout.Name := 'LT UDL Excel';
        Layout."Layout Format" := Layout."Layout Format"::Excel;
        Layout.Description := 'UDL excel layout';
        Report.ExcelLayout(Report::"LT AM Excel Rpt", InS);
        Layout.Layout.ImportStream(InS, 'UDL excel layout');
        Observer.Observe('insert', Format(Layout.Insert()));
        Columns(Observer, 'excel', Report::"LT AM Excel Rpt", 'LT UDL Excel');
        Layout.SetRange("Report ID", Report::"LT AM Excel Rpt");
        Layout.DeleteAll();
        Observer.Expect('insert', 'Yes');
        Observer.Expect('excel rows in report', '2');
        Observer.Expect('excel caption', 'LT UDL Excel');
        Observer.Expect('excel format', 'Excel');
        Observer.Expect('excel mime', '');
        Observer.Expect('excel description', 'UDL excel layout');
        Observer.Expect('excel application id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('excel runtime package id', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('excel custom type', '{00000000-0000-0000-0000-000000000000}');
        Observer.Expect('excel report name', 'LT AM Excel Rpt');
        Observer.Expect('excel publisher', '');
        Observer.Expect('excel user defined', 'Yes');
        Observer.Expect('excel installed', 'Yes');
        Observer.Expect('excel obsolete', 'No');
        Observer.Expect('excel multiple sheets', 'Default');
        Observer.Expect('excel has layout', 'Yes');
        Observer.Verify();
    end;
}
