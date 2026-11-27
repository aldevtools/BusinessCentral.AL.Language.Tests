// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-report-extension-object
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-system-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); layout files LtRle*.rdl, .docx, .xlsx and .rlblayout in this folder (copies of the Y67 and report merger layout files)
// local object: the own report, the three report extensions and the test codeunit are the definition under test (the layouts, their properties, their names and their
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
//   extension of 1306  | -              | LtRleStdLay    | -                   | -               | -                | -
//   control, 1306 own  | -              | StandardSalesInvoice.docx (a layout of the Base Application report itself)
//   Also: a filter on Layout Status (BC 28), User Defined and Application ID over the rows of the report with its extension, and the number of rows.
// Skipped on purpose: Excel, obsolete, Word and RDLC rows of a report (pinned in the files above); a layout with a CaptionML (the property syntax is not used anywhere in the corpus
//   yet, a compile error would block the whole app); a user-defined (Tenant Report Layout) layout of a report extension's report (Y17_ReportLayoutList_UserDefinedRow pins the shape);
//   the rows read in an install session (the Windows Language install cells show the pattern; the question here is the value of each column, not the session).
// The observation form: every Observe call below is in the form Observe('<label> <field number> <field name>', '<type> <value>'), as in UgReportLayoutList.al. The first run of this
//   file used Observer.Finish() and the values of the BC 27.5, 28.5 and 29.0 legs went into the Expect calls (see "Measured on").
// Measured on: not yet (first push: Finish() in every test).
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

reportextension 97787 "LT RLE Std Ext" extends "Standard Sales - Invoice"
{
    rendering
    {
        layout(LtRleStdLay)
        {
            Type = Word;
            LayoutFile = './reports/layouts-saveas/LtRleStdLay.docx';
            Caption = 'RLE std ext word';
        }
    }
}

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
            Observer.Observe(Label + ' ' + Format(FRef.Number), Shown); // names omitted while measuring: the failure message keeps about 2000 characters
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
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionWordLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext word', Report::"LT RLE Base", 'ExtWord');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionExcelLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext excel', Report::"LT RLE Base", 'ExtXls');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionObsoleteExcelLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext excel old', Report::"LT RLE Base", 'ExtXlsOld');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionCustomLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext custom', Report::"LT RLE Base", 'ExtCustom');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ReportCustomLayout_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'base custom', Report::"LT RLE Base", 'BaseCustom');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionOfBaseApplicationReport_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'std ext', Report::"Standard Sales - Invoice", 'LtRleStdLay');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_BaseApplicationLayoutOfReport1306_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // The control: a layout of the Base Application report itself, read the same way (name as in TestPrecompiledReportLayouts.al).
        Dump(Observer, 'std own', Report::"Standard Sales - Invoice", 'StandardSalesInvoice.docx');
        Observer.Finish();
    end;

#if BC29PLUS // layout parts exist from BC 29
    [Test]
    procedure ReportLayoutList_ReportLayoutParts_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'base hf', Report::"LT RLE Base", 'BasePHf');
        Dump(Observer, 'base theme', Report::"LT RLE Base", 'BasePTheme');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionLayoutParts_AllColumns()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext body', Report::"LT RLE Base", 'ExtPBody');
        Observer.Finish();
    end;

    [Test]
    procedure ReportLayoutList_ExtensionLayoutParts_HeaderFooterAndTheme()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dump(Observer, 'ext hf', Report::"LT RLE Base", 'ExtPHf');
        Dump(Observer, 'ext theme', Report::"LT RLE Base", 'ExtPTheme');
        Observer.Finish();
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
        Observer.Finish();
    end;
}
