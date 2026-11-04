// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-object
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501), reports of YReports.al (75501-75519)
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: see YReports.al. GlobalLanguage is set back to the language the test started with.
// BC versions: 27-29

codeunit 75510 "LT Y Report Props Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Helper: Codeunit "LT Y Helper";

    [TryFunction]
    local procedure TryDataItemsXml(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.DataItemsXml(ReportId);
    end;

    local procedure Region(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Xml: Text;
    begin
        // The decimalformatter of a Decimal column follows General Ledger Setup "Amount Decimal Places" as the session first
        // read it: later changes in the session are not seen until SelectLatestVersion (diagnostic runs 39255002308 and
        // 39256045991, the same on BC 27.5, 28.5 and 29.0). Earlier tests set '2:5' and roll it back, so without this call the
        // value depends on the run order.
        SelectLatestVersion();
        if TryDataItemsXml(ReportId, Xml) then
            Observer.Observe('xml', Helper.AsciiOnly(Xml))
        else
            Observer.Observe('xml', Helper.Failed());
        Observer.Observe('meta', Helper.ReportFacts(ReportId));
    end;

    [Test]
    procedure FormatRegion_DeDE_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region De");
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="de-DE" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567,891</Column>|        <Column name="DayCol">31.01.2025</Column>|        <Column name="StampCol">31.01.2025 14:30:15</Column>|        <Column name="AmtText">1.234.567,891</Column>|        <Column name="DayText">31.01.25</Column>|        <Column name="StampText">31.01.25 14:30</Column>|        <Column name="LongDayText">31. January 2025</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=de-DE;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=de-DE;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_EnGB_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Gb");
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="en-GB" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567.891</Column>|        <Column name="DayCol">31/01/2025</Column>|        <Column name="StampCol">31/01/2025 14:30:15</Column>|        <Column name="AmtText">1,234,567.891</Column>|        <Column name="DayText">31/01/25</Column>|        <Column name="StampText">31/01/25 14:30</Column>|        <Column name="LongDayText">31 January 2025</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=en-GB;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=en-GB;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_FrFR_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Fr");
        // AmtText carries the fr-FR group separator U+00A0 (as escaped here: \u2019\u00E1), the value of Windows BC 27.5 and 28.5
        // (full corpus runs on the Windows containers, 2026-10-20) and of bc-linux dc007079 BC 27, 28 and 29 (bc-linux #174; the older image
        // gave U+202F on BC 27/28). The Windows BC 29.0 container gives \u00C2\u00A0 for the same U+00A0 (that container has another default
        // code page).
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="fr-FR" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567,891</Column>|        <Column name="DayCol">31/01/2025</Column>|        <Column name="StampCol">31/01/2025 14:30:15</Column>|        <Column name="AmtText">1\u2019\u00E1234\u2019\u00E1567,891</Column>|        <Column name="DayText">31/01/25</Column>|        <Column name="StampText">31/01/25 14:30</Column>|        <Column name="LongDayText">31 January 2025</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=fr-FR;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=fr-FR;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_JaJP_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Jp");
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="ja-JP" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567.891</Column>|        <Column name="DayCol">2025/01/31</Column>|        <Column name="StampCol">2025/01/31 14:30:15</Column>|        <Column name="AmtText">1,234,567.891</Column>|        <Column name="DayText">25/01/31</Column>|        <Column name="StampText">25/01/31 14:30</Column>|        <Column name="LongDayText">2025\u00CE\u2030\u201E1\u00B5\u00A3\u00EA31\u00B5\u00F9\u00D1</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=ja-JP;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=ja-JP;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_NotSet_XmlAndFormat()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region None");
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="en-US" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567.891</Column>|        <Column name="DayCol">1/31/2025</Column>|        <Column name="StampCol">1/31/2025 2:30:15 PM</Column>|        <Column name="AmtText">1,234,567.891</Column>|        <Column name="DayText">01/31/25</Column>|        <Column name="StampText">01/31/25 02:30 PM</Column>|        <Column name="LongDayText">January 31, 2025</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure FormatRegion_UnknownRegion_XmlOrError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Region(Observer, Report::"LT Y Rep Region Bad");
        // zz-ZZ (an unknown region): DayCol and StampCol are 01/31/2025, the value of Windows BC 27.5, 28.5 and 29.0 (full corpus runs on the
        // Windows containers, 2026-10-20) and of bc-linux bcc60c1c on all three. Older bc-linux images gave 1/31/2025.
        Observer.Expect('xml', '<DataItems>|    <DataItem language="en-US" formatRegion="zz-ZZ" name="Row">|      <Columns>|        <Column name="NumCol">1</Column>|        <Column name="AmtCol" decimalformatter="#,##0.00">1234567.891</Column>|        <Column name="DayCol">01/31/2025</Column>|        <Column name="StampCol">01/31/2025 14:30:15</Column>|        <Column name="AmtText">1,234,567.891</Column>|        <Column name="DayText">01/31/25</Column>|        <Column name="StampText">01/31/25 02:30 PM</Column>|        <Column name="LongDayText">January 31, 2025</Column>|        <Column name="IntText">1234567</Column>|      </Columns>|    </DataItem>|  </DataItems>|</ReportDataSet>|');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=zz-ZZ;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=No;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=RDLC;DefaultLayoutName=;FormatRegion=zz-ZZ;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure Props_Metadata_PaperSourcesExternalImagesMultiSheet()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.ReportFacts(Report::"LT Y Rep Props"));
        Observer.Observe('layouts', Helper.LayoutFacts(Report::"LT Y Rep Props"));
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=Yes;EnableExternalAssemblies=No;PaperSourceFirstPage=1;PaperSourceDefaultPage=2;PaperSourceLastPage=3;DefaultLayout=RDLC;DefaultLayoutName=PropsLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=Yes;EnableExternalAssemblies=No;PaperSourceFirstPage=1;PaperSourceDefaultPage=2;PaperSourceLastPage=3;DefaultLayout=RDLC;DefaultLayoutName=PropsLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[PropsLayout RDLC multi=0]');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Multi_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Multi");
        Observer.Expect('default_layout', 'Excel');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[XlLayout Excel multi=0]');
        Observer.Expect('excel_layout', 'Yes eos=No');
        Observer.Expect('workbook', 'worksheet_entries=5 sheets=TranslationData,CaptionData,Aggregated Metadata,First,Second,');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Single_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Single");
        Observer.Expect('default_layout', 'Excel');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[XlLayout Excel multi=0]');
        Observer.Expect('excel_layout', 'Yes eos=No');
        Observer.Expect('workbook', 'worksheet_entries=4 sheets=Data,TranslationData,CaptionData,Aggregated Metadata,');
        Observer.Verify();
    end;

    [Test]
    procedure ExcelLayoutMultipleDataSheets_Unset_Workbook()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ExcelFacts(Observer, Report::"LT Y Rep Excel Unset");
        Observer.Expect('default_layout', 'Excel');
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=No;EnableExternalAssemblies=No;PaperSourceFirstPage=0;PaperSourceDefaultPage=0;PaperSourceLastPage=0;DefaultLayout=Excel;DefaultLayoutName=XlLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=No;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Expect('layouts', '[XlLayout Excel multi=0]');
        Observer.Expect('excel_layout', 'Yes eos=No');
        Observer.Expect('workbook', 'worksheet_entries=4 sheets=Data,TranslationData,CaptionData,Aggregated Metadata,');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryWorkbookFacts(ReportId: Integer; var Result: Text)
    begin
        Result := Helper.WorkbookFacts(ReportId);
    end;

    [TryFunction]
    local procedure TryExcelLayout(ReportId: Integer; var Result: Text)
    var
        InS: InStream;
        Found: Boolean;
    begin
        Found := Report.ExcelLayout(ReportId, InS);
        Result := Format(Found) + ' eos=' + Format(InS.EOS());
    end;

    local procedure ExcelFacts(var Observer: Codeunit "Probe Observer"; ReportId: Integer)
    var
        Text1: Text;
    begin
        Observer.Observe('default_layout', Format(Report.DefaultLayout(ReportId)));
        Observer.Observe('meta', Helper.ReportFacts(ReportId));
        Observer.Observe('layouts', Helper.LayoutFacts(ReportId));
        if TryExcelLayout(ReportId, Text1) then
            Observer.Observe('excel_layout', Text1)
        else
            Observer.Observe('excel_layout', Helper.Failed());
        if TryWorkbookFacts(ReportId, Text1) then
            Observer.Observe('workbook', Text1)
        else
            Observer.Observe('workbook', Helper.Failed());
    end;

    [Test]
    procedure AdditionalSearchTermsML_Report_CompilesAndRuns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('meta', Helper.ReportFacts(Report::"LT Y Rep Props"));
#if BC29PLUS
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=Yes;EnableExternalAssemblies=No;PaperSourceFirstPage=1;PaperSourceDefaultPage=2;PaperSourceLastPage=3;DefaultLayout=RDLC;DefaultLayoutName=PropsLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=;DefaultThemePartName=;');
#else
        Observer.Expect('meta', 'UseRequestPage=Yes;ProcessingOnly=No;EnableExternalImages=Yes;EnableExternalAssemblies=No;PaperSourceFirstPage=1;PaperSourceDefaultPage=2;PaperSourceLastPage=3;DefaultLayout=RDLC;DefaultLayoutName=PropsLayout;FormatRegion=;ExcelLayoutMultipleDataSheets=Yes;DefaultHeaderFooterPartName=absent;DefaultThemePartName=absent;');
#endif
        Observer.Verify();
    end;

    // A data item filter tab has no caption member in TestRequestPage and the request page parameters text does not carry the heading, so the heading
    // itself is not observable from AL; the data item rows (Request Filter Fields) of the report with RequestFilterHeadingML are.
    [Test]
    procedure RequestFilterHeadingML_DataItem_CompilesAndListsFilterFields()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('data_items', Helper.DataItemRows(Report::"LT Y Rep Heading"));
        Observer.Expect('data_items', '[Rw filter_fields=1 view=][Rw3 filter_fields=1 view=][Rw2 filter_fields=1 view=]');
        Observer.Verify();
    end;

    local procedure LayoutsFor(LanguageId: Integer): Text
    var
        Original: Integer;
        Result: Text;
    begin
        Original := GlobalLanguage();
        GlobalLanguage(LanguageId);
        Result := Helper.LayoutSummaries(Report::"LT Y Rep Summary");
        GlobalLanguage(Original);
        exit(Result);
    end;

    [Test]
    procedure SummaryML_English()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1033));
        Observer.Expect('layouts', 'PlainLayout=Plain summary;SumLayout=English summary;');
        Observer.Verify();
    end;

    [Test]
    procedure SummaryML_German()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1031));
        Observer.Expect('layouts', 'PlainLayout=Plain summary;SumLayout=Deutsche Zusammenfassung;');
        Observer.Verify();
    end;

    [Test]
    procedure SummaryML_FrenchFallsBack()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('layouts', LayoutsFor(1036));
        Observer.Expect('layouts', 'PlainLayout=Plain summary;SumLayout=English summary;');
        Observer.Verify();
    end;
}
