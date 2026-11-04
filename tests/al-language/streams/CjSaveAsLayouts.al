// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-saveas-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table, log and helper of CjFix.al; own reports 84644 (Word layout only) and 84645 (Excel layout only), test codeunit 84646
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts (corpus issue 667, items 145, 146, 148, 156): Report.SaveAs to Pdf, Word, Excel, Html and Xml of a report whose only layout is Word, and of one whose
//   only layout is Excel: whether the call raises or returns false when its return value is used, the last error, and what the stream holds.
//   The Custom Report Layout table (9650) and the Report Layout List for a report with an extension layout.
// RDLC rendering is stubbed on the Linux service tier of the CI, so the RDLC layout cases of items 145/146 are not observed here.
// BC versions: 27-29

report 84644 "LT CJ Word Only"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = CjWordLayout;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            column(RowId; Id) { }
            column(RowName; Name) { }
        }
    }

    rendering
    {
        layout(CjWordLayout)
        {
            Type = Word;
            LayoutFile = './streams/LtCjWordOnly.docx';
        }
    }
}

report 84645 "LT CJ Excel Only"
{
    UsageCategory = None;
    UseRequestPage = false;
    DefaultRenderingLayout = CjExcelLayout;

    dataset
    {
        dataitem(Row; "LT CJ Row")
        {
            column(RowId; Id) { }
            column(RowName; Name) { }
        }
    }

    rendering
    {
        layout(CjExcelLayout)
        {
            Type = Excel;
            LayoutFile = './streams/LtCjExcelOnly.xlsx';
        }
    }
}

codeunit 84646 "LT CJ SaveAs Layout Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT CJ Helper";

    [TryFunction]
    local procedure TrySave(ReportId: Integer; Fmt: ReportFormat; var TempBlob: Codeunit "Temp Blob"; var Ok: Boolean)
    var
        OutS: OutStream;
    begin
        TempBlob.CreateOutStream(OutS);
        Ok := Report.SaveAs(ReportId, '', Fmt, OutS);
    end;

    local procedure One(var Observer: Codeunit "Probe Observer"; ReportId: Integer; Name: Text; Fmt: ReportFormat)
    var
        TempBlob: Codeunit "Temp Blob";
        Ok: Boolean;
        Completed: Boolean;
    begin
        Helper.Seed();
        ClearLastError();
        Completed := TrySave(ReportId, Fmt, TempBlob, Ok);
        Observer.Observe(Name + ' completed', Format(Completed));
        Observer.Observe(Name + ' returned', Format(Ok));
        Observer.ObserveError(Name + ' err');
        Observer.Observe(Name + ' head', Helper.Head(TempBlob));
    end;

    [Test]
    procedure WordOnly_SaveAs_EachFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, Report::"LT CJ Word Only", 'Pdf', ReportFormat::Pdf);
        One(Observer, Report::"LT CJ Word Only", 'Word', ReportFormat::Word);
        One(Observer, Report::"LT CJ Word Only", 'Excel', ReportFormat::Excel);
        One(Observer, Report::"LT CJ Word Only", 'Html', ReportFormat::Html);
        One(Observer, Report::"LT CJ Word Only", 'Xml', ReportFormat::Xml);
        Observer.Expect('Pdf completed', 'Yes');
        Observer.Expect('Pdf returned', 'Yes');
        Observer.Expect('Pdf err|text', '');
        Observer.Expect('Pdf err|code', '');
        Observer.Expect('Pdf head', '37,80,68,70,');
        Observer.Expect('Word completed', 'Yes');
        Observer.Expect('Word returned', 'Yes');
        Observer.Expect('Word err|text', '');
        Observer.Expect('Word err|code', '');
        Observer.Expect('Word head', '80,75,3,4,');
        Observer.Expect('Excel completed', 'Yes');
        Observer.Expect('Excel returned', 'No');
        Observer.Expect('Excel err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('Excel err|code', 'ReportUnsupportedFormat');
        Observer.Expect('Excel head', 'empty');
        Observer.Expect('Html completed', 'Yes');
        Observer.Expect('Html returned', 'Yes');
        Observer.Expect('Html err|text', '');
        Observer.Expect('Html err|code', '');
        Observer.Expect('Html head', '60,104,116,109,');
        Observer.Expect('Xml completed', 'Yes');
        Observer.Expect('Xml returned', 'Yes');
        Observer.Expect('Xml err|text', '');
        Observer.Expect('Xml err|code', '');
        Observer.Expect('Xml head', '239,187,191,60,');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelOnly_SaveAs_EachFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        One(Observer, Report::"LT CJ Excel Only", 'Pdf', ReportFormat::Pdf);
        One(Observer, Report::"LT CJ Excel Only", 'Word', ReportFormat::Word);
        One(Observer, Report::"LT CJ Excel Only", 'Excel', ReportFormat::Excel);
        One(Observer, Report::"LT CJ Excel Only", 'Html', ReportFormat::Html);
        One(Observer, Report::"LT CJ Excel Only", 'Xml', ReportFormat::Xml);
        Observer.Expect('Pdf completed', 'Yes');
        Observer.Expect('Pdf returned', 'No');
        Observer.Expect('Pdf err|text', 'The Pdf output format is not supported by the current report layout format.');
        Observer.Expect('Pdf err|code', 'ReportUnsupportedFormat');
        Observer.Expect('Pdf head', 'empty');
        Observer.Expect('Word completed', 'Yes');
        Observer.Expect('Word returned', 'No');
        Observer.Expect('Word err|text', 'The Word output format is not supported by the current report layout format.');
        Observer.Expect('Word err|code', 'ReportUnsupportedFormat');
        Observer.Expect('Word head', 'empty');
        Observer.Expect('Excel completed', 'Yes');
        Observer.Expect('Excel returned', 'Yes');
        Observer.Expect('Excel err|text', '');
        Observer.Expect('Excel err|code', '');
        Observer.Expect('Excel head', '80,75,3,4,');
        Observer.Expect('Html completed', 'Yes');
        Observer.Expect('Html returned', 'No');
        Observer.Expect('Html err|text', 'The Html output format is not supported by the current report layout format.');
        Observer.Expect('Html err|code', 'ReportUnsupportedFormat');
        Observer.Expect('Html head', 'empty');
        Observer.Expect('Xml completed', 'Yes');
        Observer.Expect('Xml returned', 'Yes');
        Observer.Expect('Xml err|text', '');
        Observer.Expect('Xml err|code', '');
        Observer.Expect('Xml head', '239,187,191,60,');
        Observer.Verify();
    end;

    [Test]
    procedure WordOnly_SaveAsExcel_IfNot_Statement()
    var
        Observer: Codeunit "Probe Observer";
        TempBlob: Codeunit "Temp Blob";
        OutS: OutStream;
        Result: Text;
    begin
        // Item 145: the return value is used in an if not; BC answers false instead of raising.
        Helper.Seed();
        ClearLastError();
        TempBlob.CreateOutStream(OutS);
        if not Report.SaveAs(Report::"LT CJ Word Only", '', ReportFormat::Excel, OutS) then
            Result := 'false'
        else
            Result := 'true';
        Observer.Observe('if not', Result);
        Observer.ObserveError('if not err');
        Observer.Expect('if not', 'false');
        Observer.Expect('if not err|text', 'The Excel output format is not supported by the current report layout format.');
        Observer.Expect('if not err|code', 'ReportUnsupportedFormat');
        Observer.Verify();
    end;

    [Test]
    procedure ExtensionLayout_CustomReportLayout_And_LayoutList()
    var
        Observer: Codeunit "Probe Observer";
        CustomLayout: Record "Custom Report Layout";
        LayoutList: Record "Report Layout List";
        Rows: Text;
    begin
        // Item 148: does installing an app with a report layout insert a Custom Report Layout row (Built-In = true)?
        CustomLayout.SetRange("Report ID", Report::"LT CJ Word Only");
        Observer.Observe('custom layouts', Format(CustomLayout.Count()));
        CustomLayout.SetRange("Built-In", true);
        Observer.Observe('custom built-in layouts', Format(CustomLayout.Count()));
        LayoutList.SetRange("Report ID", Report::"LT CJ Word Only");
        if LayoutList.FindSet() then
            repeat
                Rows += LayoutList.Name + ' ' + Format(LayoutList."Layout Format") + ';';
            until LayoutList.Next() = 0;
        Observer.Observe('layout list', Rows);
        Observer.Observe('default layout', Format(Report.DefaultLayout(Report::"LT CJ Word Only")));
        Observer.Expect('custom layouts', '0');
        Observer.Expect('custom built-in layouts', '0');
        Observer.Expect('layout list', 'CjWordLayout Word;');
        Observer.Expect('default layout', 'Word');
        Observer.Verify();
    end;
}
