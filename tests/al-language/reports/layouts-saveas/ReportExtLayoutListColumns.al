// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); layout 'Y67StdExt.docx' that reportextension 93543 of Y67LayoutExtExport.al adds to report 1306 "Standard Sales - Invoice" (read only; a second extension
//   of report 1306 would change the row count of that report, which W5_TenantReportLayout_MicrosoftReport_WordLayout asserts); layout files LtRle*.rdl, .docx, .xlsx and .rlblayout in this folder (copies of the Y67 and report merger layout files)
// local object: the own report, its two report extensions and the test codeunit are the definition under test (the layouts, their properties, their names and their
//   captions are what the Report Layout List rows are read for); no shared fixture has an extension with a Custom layout, an obsolete layout or layout parts, and an
//   extra layout in a shared report would change the row counts other tests assert (report 69083 and its extension 69084 in TestEventSubscriptionColumnsReportLayoutListContracts.al).
// Probe (a partner suite reads the platform table "Report Layout List" (2000000234) in an install codeunit to set the default layout of a layout a report extension adds;
//   a runner that executes it has to know every column of such a row): the rows of the layouts a REPORT EXTENSION declares, every column, side by side with the same
//   shape in the report itself.
//   UgReportLayoutList.al pins every column for the RDLC and Word layouts of a report (and, in Y17_ReportLayoutList_UserDefinedRow, for a user-defined layout), AwTests.al
//   pins them for the Excel layouts of a report and for an obsolete one, and Y67LayoutExtExport.al and TestEventSubscriptionColumnsReportLayoutListContracts.al read only
//   Name, Layout Format, Caption, Description and Application ID of an extension's layout. Not pinned until this file: Report Name, Layout Publisher, ReportIsInstalled,
//   User Defined, IsObsolete, ExcelLayoutMultipleDataSheets, Custom Type, MIME Type, CaptionML, Layout Status, Layout Subtype, HeaderFooterPart and ThemePart of an extension's
//   layout, and every column of a Custom layout (of a report or of an extension) and of a layout part (BC 29).
// Matrix (area: Report Layout List rows by layout kind and by declaring object):
//   declaring object   | RDLC           | Word           | Excel               | Excel, obsolete | Custom           | layout parts (BC 29)
//   own report         | (UgReport...)  | (UgReport...)  | (AwTests.al)        | (AwTests.al)    | BaseCustom       | BasePHf, BasePTheme
//   extension of it    | ExtRdl         | ExtWord        | ExtXls              | ExtXlsOld       | ExtCustom        | ExtPBody, ExtPHf, ExtPTheme
//   extension of 1306  | -              | Y67StdExt.docx | -                   | -               | -                | -
//   control, 1306 own  | -              | StandardSalesInvoice.docx (a layout of the Base Application report itself)
//   Also: a filter on Layout Status (BC 28), User Defined and Application ID over the rows of the report with its extension, and the number of rows.
// Skipped on purpose: Excel, obsolete, Word and RDLC rows of a report (pinned in the files above); a layout with a CaptionML (the property syntax is not used anywhere in the corpus
//   yet, a compile error would block the whole app); a user-defined (Tenant Report Layout) layout of a report extension's report (Y17_ReportLayoutList_UserDefinedRow pins the shape);
//   the rows read in an install session (the Windows Language install cells show the pattern; the question here is the value of each column, not the session).
// How the values were taken: every Observe call is Observe('<label> <field number> <field name>', '<type> <value>'), as in UgReportLayoutList.al; the first runs used
//   Observer.Finish() and the values the BC 27.5, 28.5 and 29.0 legs reported went into the Expect calls.
// Measured on: BC 27.5, 28.5 and 29.0 in corpus CI (SaaS shards), the same on all three except that column 18 exists from BC 28 and columns 19 - 21 and the layout parts from BC 29.
//   The row of a layout a report extension declares (RDLC, Word, Excel, obsolete Excel, Custom, and the three layout parts) has the same columns as the row of the same layout in the
//   report itself: Report ID of the extended report, Name the layout's name, Runtime Package ID a guid other than this app's (the same as for the report's own layouts in UgReportLayoutList.al), Caption the
//   Caption or the name, Description the Summary or the name, Application ID this app (the app that declares the extension), Report Name the extended report's Caption (report 97784:
//   'LT RLE Caption Differs'; for the Y67 extension of report 1306 'Sales - Invoice'), Layout Publisher '<app name> by <publisher>' of the app that declares the extension (for the extension of report 1306 this app, not
//   Base Application), User Defined No, ReportIsInstalled Yes, IsObsolete Yes only for the obsolete layout, ExcelLayoutMultipleDataSheets Default, Layout Status Approved (also for the Custom
//   layout and the layout parts), Layout Subtype Default (Body for the layout that names parts, Header/Footer and Theme for the parts), HeaderFooterPart and ThemePart blank except
//   for the Body layout, which holds '<app id>::<layout name>' of the parts. A Custom layout reads Layout Format External (the Custom member of the option), MIME Type the layout's
//   MimeType, Custom Type the null guid, User Defined No. The Base Application's own layout of report 1306 reads Layout Publisher 'Base Application by Microsoft' and Application ID
//   another app.
//   The report with its extensions lists 7 rows (12 from BC 29: with the five layout parts), every one User Defined No, installed and of this app, one obsolete, two of Layout Format
//   External; a filter on Layout Status Approved finds every row, Retired none, a filter on a blank Layout Publisher none.
// BC versions: 27 - 29 (BC 28 adds column 18 Layout Status, BC 29 adds 19 - 21 and the layout parts)

report 97784 "LT RLE Base"
{
    UsageCategory = None;
    Caption = 'LT RLE Caption Differs';
    DefaultRenderingLayout = BaseRdl;

    dataset
    {
        dataitem(Item; Integer)
        {
            DataItemTableView = sorting(Number) where(Number = const(1));
            column(Num; Number) { }
            // the Excel layouts (copies of the Y67 files) hold a data table with the columns No_ and Name_, and alc refuses an Excel layout with a column the report does not have (AL0444)
            column(No_; Number) { }
            column(Name_; Number) { }
        }
    }

    rendering
    {
        layout(BaseRdl)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtRleBaseRdl.rdl';
            Caption = 'RLE base rdlc';
        }
        layout(BaseCustom)
        {
            Type = Custom;
            LayoutFile = './reports/layouts-saveas/LtRleBaseCustom.rlblayout';
            MimeType = 'application/x-rle-base-layout';
            Caption = 'RLE base custom';
            Summary = 'RLE base custom summary';
        }
#if BC29PLUS // layout Subtype, HeaderFooterPart and ThemePart compile from BC 29 (must-not-compile cases 0802 - 0804)
        layout(BasePHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './reports/layouts-saveas/LtRleBasePHf.docx';
        }
        layout(BasePTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './reports/layouts-saveas/LtRleBasePTheme.dotx';
        }
#endif
    }
}

reportextension 97785 "LT RLE Ext" extends "LT RLE Base"
{
    rendering
    {
        layout(ExtRdl)
        {
            Type = RDLC;
            LayoutFile = './reports/layouts-saveas/LtRleExtRdl.rdl';
            Caption = 'RLE ext rdlc';
            Summary = 'RLE ext rdlc summary';
        }
        layout(ExtWord)
        {
            Type = Word;
            LayoutFile = './reports/layouts-saveas/LtRleExtWord.docx';
        }
        layout(ExtXls)
        {
            Type = Excel;
            LayoutFile = './reports/layouts-saveas/LtRleExtXls.xlsx';
            Caption = 'RLE ext excel';
        }
        layout(ExtXlsOld)
        {
            Type = Excel;
            LayoutFile = './reports/layouts-saveas/LtRleExtXlsOld.xlsx';
            ObsoleteState = Pending;
            ObsoleteReason = 'Pending';
            ObsoleteTag = '1.0';
        }
        layout(ExtCustom)
        {
            Type = Custom;
            LayoutFile = './reports/layouts-saveas/LtRleExtCustom.rlblayout';
            MimeType = 'application/x-rle-ext-layout';
            Caption = 'RLE ext custom';
            Summary = 'RLE ext custom summary';
        }
    }
}

#if BC29PLUS // the layout parts of an extension: a Body layout that names a header/footer part and a theme part of the same extension
reportextension 97786 "LT RLE Parts Ext" extends "LT RLE Base"
{
    rendering
    {
        layout(ExtPBody)
        {
            Type = Word;
            Subtype = Body;
            LayoutFile = './reports/layouts-saveas/LtRleExtPBody.docx';
            HeaderFooterPart = ExtPHf;
            ThemePart = ExtPTheme;
        }
        layout(ExtPHf)
        {
            Type = Word;
            Subtype = HeaderFooter;
            LayoutFile = './reports/layouts-saveas/LtRleExtPHf.docx';
        }
        layout(ExtPTheme)
        {
            Type = Word;
            Subtype = Theme;
            LayoutFile = './reports/layouts-saveas/LtRleExtPTheme.dotx';
        }
    }
}
#endif

codeunit 97788 "LT RLE Layout List Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var FRef: FieldRef): Text
    var
        Info: ModuleInfo;
        Id: Guid;
    begin
        if FRef.Class = FieldClass::FlowField then
            FRef.CalcField();
        case FRef.Type of
            FieldType::Guid:
                begin
                    Id := FRef.Value;
                    NavApp.GetCurrentModuleInfo(Info);
                    if IsNullGuid(Id) then
                        exit('null guid');
                    if Id = Info.Id() then
                        exit('this app');
                    exit('other guid');
                end;
            FieldType::DateTime, FieldType::Date, FieldType::Time:
                if Format(FRef.Value) = '' then
                    exit('blank')
                else
                    exit('set');
            FieldType::Blob, FieldType::Media, FieldType::MediaSet:
                exit('not shown');
        end;
        exit('[' + Format(FRef.Value) + ']');
    end;

    // Observes the row column by column, in field index order, under the name "<Label> <field number> <field name>".
    // A part column (HeaderFooterPart, ThemePart) holds the id of the declaring app, so a value that starts with this app's id is shown as <this app>::<layout name>.
    local procedure Dump(var Observer: Codeunit "Probe Observer"; Label: Text; ReportId: Integer; LayoutName: Text)
    var
        RecRef: RecordRef;
        FRef: FieldRef;
        Info: ModuleInfo;
        Shown: Text;
        I: Integer;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        RecRef.Open(2000000234);
        RecRef.Field(1).SetRange(ReportId);
        RecRef.Field(2).SetRange(LayoutName);
        if not RecRef.FindFirst() then begin
            Observer.Observe(Label, 'no row, rows in report=' + CountOfReport(ReportId));
            exit;
        end;
        for I := 1 to RecRef.FieldCount() do begin
            FRef := RecRef.FieldIndex(I);
            Shown := Format(FRef.Type) + ' ' + Show(FRef);
            Shown := Shown.Replace(Format(Info.Id()).ToLower().Replace('{', '').Replace('}', ''), '<this app>');
            Shown := Shown.Replace(Format(Info.Id()).ToUpper().Replace('{', '').Replace('}', ''), '<this app>');
            Observer.Observe(Label + ' ' + Format(FRef.Number) + ' ' + FRef.Name, Shown);
        end;
    end;

    local procedure CountOfReport(ReportId: Integer): Text
    var
        Layouts: Record "Report Layout List";
    begin
        Layouts.SetRange("Report ID", ReportId);
        exit(Format(Layouts.Count()));
    end;

    [Test]
    procedure ReportLayoutList_ExtensionRdlcLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext rdlc', Report::"LT RLE Base", 'ExtRdl');
        Observer.Expect('ext rdlc 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext rdlc 2 Name', 'Text [ExtRdl]');
        Observer.Expect('ext rdlc 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext rdlc 3 Caption', 'Text [RLE ext rdlc]');
        Observer.Expect('ext rdlc 4 CaptionML', 'Text []');
        Observer.Expect('ext rdlc 6 Layout', 'Media not shown');
        Observer.Expect('ext rdlc 7 Layout Format', 'Option [RDLC]');
        Observer.Expect('ext rdlc 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext rdlc 9 MIME Type', 'Text []');
        Observer.Expect('ext rdlc 10 Description', 'Text [RLE ext rdlc summary]');
        Observer.Expect('ext rdlc 11 Application ID', 'GUID this app');
        Observer.Expect('ext rdlc 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext rdlc 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext rdlc 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext rdlc 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext rdlc 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext rdlc 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext rdlc 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext rdlc 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('ext rdlc 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext rdlc 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionWordLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext word', Report::"LT RLE Base", 'ExtWord');
        Observer.Expect('ext word 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext word 2 Name', 'Text [ExtWord]');
        Observer.Expect('ext word 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext word 3 Caption', 'Text [ExtWord]');
        Observer.Expect('ext word 4 CaptionML', 'Text []');
        Observer.Expect('ext word 6 Layout', 'Media not shown');
        Observer.Expect('ext word 7 Layout Format', 'Option [Word]');
        Observer.Expect('ext word 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext word 9 MIME Type', 'Text []');
        Observer.Expect('ext word 10 Description', 'Text [ExtWord]');
        Observer.Expect('ext word 11 Application ID', 'GUID this app');
        Observer.Expect('ext word 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext word 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext word 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext word 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext word 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext word 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext word 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext word 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('ext word 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext word 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionExcelLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext excel', Report::"LT RLE Base", 'ExtXls');
        Observer.Expect('ext excel 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext excel 2 Name', 'Text [ExtXls]');
        Observer.Expect('ext excel 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext excel 3 Caption', 'Text [RLE ext excel]');
        Observer.Expect('ext excel 4 CaptionML', 'Text []');
        Observer.Expect('ext excel 6 Layout', 'Media not shown');
        Observer.Expect('ext excel 7 Layout Format', 'Option [Excel]');
        Observer.Expect('ext excel 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext excel 9 MIME Type', 'Text []');
        Observer.Expect('ext excel 10 Description', 'Text [ExtXls]');
        Observer.Expect('ext excel 11 Application ID', 'GUID this app');
        Observer.Expect('ext excel 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext excel 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext excel 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext excel 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext excel 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext excel 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext excel 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext excel 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('ext excel 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext excel 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionObsoleteExcelLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext excel old', Report::"LT RLE Base", 'ExtXlsOld');
        Observer.Expect('ext excel old 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext excel old 2 Name', 'Text [ExtXlsOld]');
        Observer.Expect('ext excel old 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext excel old 3 Caption', 'Text [ExtXlsOld]');
        Observer.Expect('ext excel old 4 CaptionML', 'Text []');
        Observer.Expect('ext excel old 6 Layout', 'Media not shown');
        Observer.Expect('ext excel old 7 Layout Format', 'Option [Excel]');
        Observer.Expect('ext excel old 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext excel old 9 MIME Type', 'Text []');
        Observer.Expect('ext excel old 10 Description', 'Text [ExtXlsOld]');
        Observer.Expect('ext excel old 11 Application ID', 'GUID this app');
        Observer.Expect('ext excel old 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext excel old 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext excel old 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext excel old 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext excel old 16 IsObsolete', 'Boolean [Yes]');
        Observer.Expect('ext excel old 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext excel old 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext excel old 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('ext excel old 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext excel old 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionCustomLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext custom', Report::"LT RLE Base", 'ExtCustom');
        Observer.Expect('ext custom 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext custom 2 Name', 'Text [ExtCustom]');
        Observer.Expect('ext custom 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext custom 3 Caption', 'Text [RLE ext custom]');
        Observer.Expect('ext custom 4 CaptionML', 'Text []');
        Observer.Expect('ext custom 6 Layout', 'Media not shown');
        Observer.Expect('ext custom 7 Layout Format', 'Option [External]');
        Observer.Expect('ext custom 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext custom 9 MIME Type', 'Text [application/x-rle-ext-layout]');
        Observer.Expect('ext custom 10 Description', 'Text [RLE ext custom summary]');
        Observer.Expect('ext custom 11 Application ID', 'GUID this app');
        Observer.Expect('ext custom 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext custom 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext custom 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext custom 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext custom 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext custom 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext custom 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext custom 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('ext custom 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext custom 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ReportCustomLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'base custom', Report::"LT RLE Base", 'BaseCustom');
        Observer.Expect('base custom 1 Report ID', 'Integer [97784]');
        Observer.Expect('base custom 2 Name', 'Text [BaseCustom]');
        Observer.Expect('base custom 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('base custom 3 Caption', 'Text [RLE base custom]');
        Observer.Expect('base custom 4 CaptionML', 'Text []');
        Observer.Expect('base custom 6 Layout', 'Media not shown');
        Observer.Expect('base custom 7 Layout Format', 'Option [External]');
        Observer.Expect('base custom 8 Custom Type', 'GUID null guid');
        Observer.Expect('base custom 9 MIME Type', 'Text [application/x-rle-base-layout]');
        Observer.Expect('base custom 10 Description', 'Text [RLE base custom summary]');
        Observer.Expect('base custom 11 Application ID', 'GUID this app');
        Observer.Expect('base custom 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('base custom 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('base custom 14 User Defined', 'Boolean [No]');
        Observer.Expect('base custom 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('base custom 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('base custom 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('base custom 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('base custom 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('base custom 20 HeaderFooterPart', 'Text []');
        Observer.Expect('base custom 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionOfBaseApplicationReport_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'std ext', Report::"Standard Sales - Invoice", 'Y67StdExt.docx');
        Observer.Expect('std ext 1 Report ID', 'Integer [1306]');
        Observer.Expect('std ext 2 Name', 'Text [Y67StdExt.docx]');
        Observer.Expect('std ext 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('std ext 3 Caption', 'Text [Y67 std ext word]');
        Observer.Expect('std ext 4 CaptionML', 'Text []');
        Observer.Expect('std ext 6 Layout', 'Media not shown');
        Observer.Expect('std ext 7 Layout Format', 'Option [Word]');
        Observer.Expect('std ext 8 Custom Type', 'GUID null guid');
        Observer.Expect('std ext 9 MIME Type', 'Text []');
        Observer.Expect('std ext 10 Description', 'Text [Y67StdExt.docx]');
        Observer.Expect('std ext 11 Application ID', 'GUID this app');
        Observer.Expect('std ext 12 Report Name', 'Text [Sales - Invoice]');
        Observer.Expect('std ext 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('std ext 14 User Defined', 'Boolean [No]');
        Observer.Expect('std ext 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('std ext 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('std ext 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('std ext 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('std ext 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('std ext 20 HeaderFooterPart', 'Text []');
        Observer.Expect('std ext 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_BaseApplicationLayoutOfReport1306_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The control: a layout of the Base Application report itself, read the same way (name as in TestPrecompiledReportLayouts.al).
        Dump(Observer, 'std own', Report::"Standard Sales - Invoice", 'StandardSalesInvoice.docx');
        // Caption and Description are Microsoft's texts and may change with a BC release: recorded, not compared.
        Observer.Ignore('std own 3 Caption');
        Observer.Ignore('std own 10 Description');
        Observer.Expect('std own 1 Report ID', 'Integer [1306]');
        Observer.Expect('std own 2 Name', 'Text [StandardSalesInvoice.docx]');
        Observer.Expect('std own 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('std own 4 CaptionML', 'Text []');
        Observer.Expect('std own 6 Layout', 'Media not shown');
        Observer.Expect('std own 7 Layout Format', 'Option [Word]');
        Observer.Expect('std own 8 Custom Type', 'GUID null guid');
        Observer.Expect('std own 9 MIME Type', 'Text []');
        Observer.Expect('std own 11 Application ID', 'GUID other guid');
        Observer.Expect('std own 12 Report Name', 'Text [Sales - Invoice]');
        Observer.Expect('std own 13 Layout Publisher', 'Text [Base Application by Microsoft]');
        Observer.Expect('std own 14 User Defined', 'Boolean [No]');
        Observer.Expect('std own 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('std own 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('std own 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('std own 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('std own 19 Layout Subtype', 'Option [Default]');
        Observer.Expect('std own 20 HeaderFooterPart', 'Text []');
        Observer.Expect('std own 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

#if BC29PLUS // layout parts exist from BC 29
    [Test]
    procedure ReportLayoutList_ReportLayoutParts_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'base hf', Report::"LT RLE Base", 'BasePHf');
        Dump(Observer, 'base theme', Report::"LT RLE Base", 'BasePTheme');
        Observer.Expect('base hf 1 Report ID', 'Integer [97784]');
        Observer.Expect('base hf 2 Name', 'Text [BasePHf]');
        Observer.Expect('base hf 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('base hf 3 Caption', 'Text [BasePHf]');
        Observer.Expect('base hf 4 CaptionML', 'Text []');
        Observer.Expect('base hf 6 Layout', 'Media not shown');
        Observer.Expect('base hf 7 Layout Format', 'Option [Word]');
        Observer.Expect('base hf 8 Custom Type', 'GUID null guid');
        Observer.Expect('base hf 9 MIME Type', 'Text []');
        Observer.Expect('base hf 10 Description', 'Text [BasePHf]');
        Observer.Expect('base hf 11 Application ID', 'GUID this app');
        Observer.Expect('base hf 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('base hf 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('base hf 14 User Defined', 'Boolean [No]');
        Observer.Expect('base hf 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('base hf 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('base hf 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('base hf 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('base hf 19 Layout Subtype', 'Option [Header/Footer]');
        Observer.Expect('base hf 20 HeaderFooterPart', 'Text []');
        Observer.Expect('base hf 21 ThemePart', 'Text []');
#endif
        Observer.Expect('base theme 1 Report ID', 'Integer [97784]');
        Observer.Expect('base theme 2 Name', 'Text [BasePTheme]');
        Observer.Expect('base theme 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('base theme 3 Caption', 'Text [BasePTheme]');
        Observer.Expect('base theme 4 CaptionML', 'Text []');
        Observer.Expect('base theme 6 Layout', 'Media not shown');
        Observer.Expect('base theme 7 Layout Format', 'Option [Word]');
        Observer.Expect('base theme 8 Custom Type', 'GUID null guid');
        Observer.Expect('base theme 9 MIME Type', 'Text []');
        Observer.Expect('base theme 10 Description', 'Text [BasePTheme]');
        Observer.Expect('base theme 11 Application ID', 'GUID this app');
        Observer.Expect('base theme 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('base theme 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('base theme 14 User Defined', 'Boolean [No]');
        Observer.Expect('base theme 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('base theme 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('base theme 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('base theme 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('base theme 19 Layout Subtype', 'Option [Theme]');
        Observer.Expect('base theme 20 HeaderFooterPart', 'Text []');
        Observer.Expect('base theme 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionLayoutParts_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext body', Report::"LT RLE Base", 'ExtPBody');
        Observer.Expect('ext body 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext body 2 Name', 'Text [ExtPBody]');
        Observer.Expect('ext body 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext body 3 Caption', 'Text [ExtPBody]');
        Observer.Expect('ext body 4 CaptionML', 'Text []');
        Observer.Expect('ext body 6 Layout', 'Media not shown');
        Observer.Expect('ext body 7 Layout Format', 'Option [Word]');
        Observer.Expect('ext body 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext body 9 MIME Type', 'Text []');
        Observer.Expect('ext body 10 Description', 'Text [ExtPBody]');
        Observer.Expect('ext body 11 Application ID', 'GUID this app');
        Observer.Expect('ext body 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext body 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext body 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext body 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext body 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext body 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext body 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext body 19 Layout Subtype', 'Option [Body]');
        Observer.Expect('ext body 20 HeaderFooterPart', 'Text [<this app>::ExtPHf]');
        Observer.Expect('ext body 21 ThemePart', 'Text [<this app>::ExtPTheme]');
#endif
        Observer.Verify();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionLayoutParts_HeaderFooterAndTheme()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext hf', Report::"LT RLE Base", 'ExtPHf');
        Dump(Observer, 'ext theme', Report::"LT RLE Base", 'ExtPTheme');
        Observer.Expect('ext hf 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext hf 2 Name', 'Text [ExtPHf]');
        Observer.Expect('ext hf 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext hf 3 Caption', 'Text [ExtPHf]');
        Observer.Expect('ext hf 4 CaptionML', 'Text []');
        Observer.Expect('ext hf 6 Layout', 'Media not shown');
        Observer.Expect('ext hf 7 Layout Format', 'Option [Word]');
        Observer.Expect('ext hf 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext hf 9 MIME Type', 'Text []');
        Observer.Expect('ext hf 10 Description', 'Text [ExtPHf]');
        Observer.Expect('ext hf 11 Application ID', 'GUID this app');
        Observer.Expect('ext hf 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext hf 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext hf 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext hf 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext hf 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext hf 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext hf 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext hf 19 Layout Subtype', 'Option [Header/Footer]');
        Observer.Expect('ext hf 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext hf 21 ThemePart', 'Text []');
#endif
        Observer.Expect('ext theme 1 Report ID', 'Integer [97784]');
        Observer.Expect('ext theme 2 Name', 'Text [ExtPTheme]');
        Observer.Expect('ext theme 5 Runtime Package ID', 'GUID other guid');
        Observer.Expect('ext theme 3 Caption', 'Text [ExtPTheme]');
        Observer.Expect('ext theme 4 CaptionML', 'Text []');
        Observer.Expect('ext theme 6 Layout', 'Media not shown');
        Observer.Expect('ext theme 7 Layout Format', 'Option [Word]');
        Observer.Expect('ext theme 8 Custom Type', 'GUID null guid');
        Observer.Expect('ext theme 9 MIME Type', 'Text []');
        Observer.Expect('ext theme 10 Description', 'Text [ExtPTheme]');
        Observer.Expect('ext theme 11 Application ID', 'GUID this app');
        Observer.Expect('ext theme 12 Report Name', 'Text [LT RLE Caption Differs]');
        Observer.Expect('ext theme 13 Layout Publisher', 'Text [AL Language Coverage Tests by AL Language]');
        Observer.Expect('ext theme 14 User Defined', 'Boolean [No]');
        Observer.Expect('ext theme 15 ReportIsInstalled', 'Boolean [Yes]');
        Observer.Expect('ext theme 16 IsObsolete', 'Boolean [No]');
        Observer.Expect('ext theme 17 ExcelLayoutMultipleDataSheets', 'Option [Default]');
#if BC28PLUS
        Observer.Expect('ext theme 18 Layout Status', 'Option [Approved]');
#endif
#if BC29PLUS
        Observer.Expect('ext theme 19 Layout Subtype', 'Option [Theme]');
        Observer.Expect('ext theme 20 HeaderFooterPart', 'Text []');
        Observer.Expect('ext theme 21 ThemePart', 'Text []');
#endif
        Observer.Verify();
    end;
#endif

    // The rows of the report with its extensions and what a filter on the columns finds (the rows a default-layout codeunit of a partner suite looks through).
    [Test]
    procedure ReportLayoutList_ReportWithExtensions_FiltersOnColumns()
    var
        Layouts: Record "Report Layout List";
        Info: ModuleInfo;
        Observer: Codeunit "Probe Observer";
        Names: Text;
    begin
        NavApp.GetCurrentModuleInfo(Info);
        Layouts.SetRange("Report ID", Report::"LT RLE Base");
        Observer.Observe('rows', Format(Layouts.Count()));
        if Layouts.FindSet() then
            repeat
                Names += Layouts.Name + ',';
            until Layouts.Next() = 0;
        Observer.Observe('names', Names);
        Layouts.SetRange("User Defined", false);
        Observer.Observe('user defined = No', Format(Layouts.Count()));
        Layouts.SetRange("User Defined");
        Layouts.SetRange("Application ID", Info.Id());
        Observer.Observe('application id = this app', Format(Layouts.Count()));
        Layouts.SetRange("Application ID");
        Layouts.SetRange(ReportIsInstalled, true);
        Observer.Observe('installed', Format(Layouts.Count()));
        Layouts.SetRange(ReportIsInstalled);
        Layouts.SetRange(IsObsolete, true);
        Observer.Observe('obsolete', Format(Layouts.Count()));
        Layouts.SetRange(IsObsolete);
        Layouts.SetRange("Layout Format", Layouts."Layout Format"::Custom);
        Observer.Observe('custom format', Format(Layouts.Count()));
        Layouts.SetRange("Layout Format");
        Layouts.SetFilter(Name, 'Ext*');
        Observer.Observe('name Ext*', Format(Layouts.Count()));
        Layouts.SetRange(Name);
#if BC28PLUS // Layout Status is a column from BC 28
        Layouts.SetRange("Layout Status", Layouts."Layout Status"::Approved);
        Observer.Observe('status Approved', Format(Layouts.Count()));
        Layouts.SetRange("Layout Status", Layouts."Layout Status"::Retired);
        Observer.Observe('status Retired', Format(Layouts.Count()));
        Layouts.SetRange("Layout Status");
#endif
        Layouts.SetRange("Layout Publisher", '');
        Observer.Observe('publisher blank', Format(Layouts.Count()));
#if BC29PLUS // the layout parts (2 in the report, 3 in the extension) exist from BC 29: 12 rows, else 7
        Observer.Expect('rows', '12');
        Observer.Expect('names', 'BaseCustom,BasePHf,BasePTheme,BaseRdl,ExtCustom,ExtPBody,ExtPHf,ExtPTheme,ExtRdl,ExtWord,ExtXls,ExtXlsOld,');
        Observer.Expect('user defined = No', '12');
        Observer.Expect('application id = this app', '12');
        Observer.Expect('installed', '12');
#else
        Observer.Expect('rows', '7');
        Observer.Expect('names', 'BaseCustom,BaseRdl,ExtCustom,ExtRdl,ExtWord,ExtXls,ExtXlsOld,');
        Observer.Expect('user defined = No', '7');
        Observer.Expect('application id = this app', '7');
        Observer.Expect('installed', '7');
#endif
        Observer.Expect('obsolete', '1');
        Observer.Expect('custom format', '2');
#if BC29PLUS
        Observer.Expect('name Ext*', '8');
#else
        Observer.Expect('name Ext*', '5');
#endif
#if BC29PLUS
        Observer.Expect('status Approved', '12');
        Observer.Expect('status Retired', '0');
#elif BC28PLUS
        Observer.Expect('status Approved', '7');
        Observer.Expect('status Retired', '0');
#endif
        Observer.Expect('publisher blank', '0');
        Observer.Verify();
    end;
}
