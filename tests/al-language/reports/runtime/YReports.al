// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-formatregion-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), LT Y Helper (75500), LT Y Seen (75501); own reports 75502-75519
// Probe: observed values; every literal asserted below is what the BC tiers of the corpus matrix produced.
// Facts: report properties with an observable effect. FormatRegion (SaveAs Xml dataset: formatRegion attribute, Format() of a decimal, a date and a date time inside the report triggers),
// PaperSourceFirstPage/DefaultPage/LastPage, EnableExternalImages and ExcelLayoutMultipleDataSheets through the Report Metadata row, PdfFontEmbedding (SaveAs Pdf),
// AdditionalSearchTermsML, data item RequestFilterHeadingML (TestRequestPage caption per language), layout SummaryML (Report Layout List per language).
// EnableExternalAssemblies is Scope OnPrem (must-not-compile case 0806); DefaultHeaderFooterPart, DefaultThemePart, HeaderFooterPart, ThemePart and layout Subtype exist from runtime 18 only (cases 0800-0805).
// BC versions: 27-29

report 75502 "LT Y Rep Region De"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;
    FormatRegion = 'de-DE';
    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75503 "LT Y Rep Region Gb"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;
    FormatRegion = 'en-GB';
    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75504 "LT Y Rep Region Fr"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;
    FormatRegion = 'fr-FR';
    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75505 "LT Y Rep Region Jp"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;
    FormatRegion = 'ja-JP';
    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75506 "LT Y Rep Region None"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75507 "LT Y Rep Region Bad"
{
    UsageCategory = None;
    ProcessingOnly = false;
    UseRequestPage = false;
    FormatRegion = 'zz-ZZ';
    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
            column(AmtCol; Amt) { }
            column(DayCol; DayVal) { }
            column(StampCol; Stamp) { }
            column(AmtText; AmtText) { }
            column(DayText; DayText) { }
            column(StampText; StampText) { }
            column(LongDayText; LongDayText) { }
            column(IntText; IntText) { }

            trigger OnAfterGetRecord()
            begin
                AmtText := Format(Amt);
                DayText := Format(DayVal);
                StampText := Format(Stamp);
                LongDayText := Format(DayVal, 0, 4);
                IntText := Format(1234567);
            end;
        }
    }

    trigger OnInitReport()
    begin
        Amt := 1234567.891;
        DayVal := DMY2Date(31, 1, 2025);
        Stamp := CreateDateTime(DayVal, 143015T);
    end;

    var
        Amt: Decimal;
        DayVal: Date;
        Stamp: DateTime;
        AmtText: Text;
        DayText: Text;
        StampText: Text;
        LongDayText: Text;
        IntText: Text;
}

report 75501 "LT Y Rep Props"
{
    UsageCategory = None;
    Caption = 'LT Y props';
    DefaultRenderingLayout = PropsLayout;
    PaperSourceFirstPage = Upper;
    PaperSourceDefaultPage = Lower;
    PaperSourceLastPage = Middle;
    EnableExternalImages = true;
    ExcelLayoutMultipleDataSheets = true;
    PdfFontEmbedding = Yes;
    AdditionalSearchTermsML = ENU = 'alpha,beta', DEU = 'gamma,delta', FRA = 'epsilon';

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(PropsLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYProps.rdlc';
            Caption = 'LT Y props layout';
        }
    }
}


report 75513 "LT Y Rep Pdf Yes"
{
    UsageCategory = None;
    DefaultRenderingLayout = PdfLayout;
    PdfFontEmbedding = Yes;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(PdfLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYPdfYes.rdlc';
        }
    }
}


report 75514 "LT Y Rep Pdf No"
{
    UsageCategory = None;
    DefaultRenderingLayout = PdfLayout;
    PdfFontEmbedding = No;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(PdfLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYPdfNo.rdlc';
        }
    }
}


report 75515 "LT Y Rep Pdf Default"
{
    UsageCategory = None;
    DefaultRenderingLayout = PdfLayout;
    PdfFontEmbedding = Default;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(PdfLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYPdfDefault.rdlc';
        }
    }
}


report 75510 "LT Y Rep Excel Multi"
{
    UsageCategory = None;
    DefaultRenderingLayout = XlLayout;
    ExcelLayoutMultipleDataSheets = true;

    dataset
    {
        dataitem(First; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(FirstNum; Number) { }
        }
        dataitem(Second; Integer)
        {
            DataItemTableView = where(Number = const(2));
            column(SecondNum; Number) { }
        }
    }

    rendering
    {
        layout(XlLayout)
        {
            Type = Excel;
            LayoutFile = './reports/runtime/LtYExcelA.xlsx';
            Caption = 'LT Y excel Multi';
        }
    }
}


report 75511 "LT Y Rep Excel Single"
{
    UsageCategory = None;
    DefaultRenderingLayout = XlLayout;
    ExcelLayoutMultipleDataSheets = false;

    dataset
    {
        dataitem(First; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(FirstNum; Number) { }
        }
        dataitem(Second; Integer)
        {
            DataItemTableView = where(Number = const(2));
            column(SecondNum; Number) { }
        }
    }

    rendering
    {
        layout(XlLayout)
        {
            Type = Excel;
            LayoutFile = './reports/runtime/LtYExcelB.xlsx';
            Caption = 'LT Y excel Single';
        }
    }
}


report 75512 "LT Y Rep Excel Unset"
{
    UsageCategory = None;
    DefaultRenderingLayout = XlLayout;
    

    dataset
    {
        dataitem(First; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(FirstNum; Number) { }
        }
        dataitem(Second; Integer)
        {
            DataItemTableView = where(Number = const(2));
            column(SecondNum; Number) { }
        }
    }

    rendering
    {
        layout(XlLayout)
        {
            Type = Excel;
            LayoutFile = './reports/runtime/LtYExcelC.xlsx';
            Caption = 'LT Y excel Unset';
        }
    }
}


report 75517 "LT Y Rep Heading"
{
    UsageCategory = None;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rw; Integer)
        {
            RequestFilterFields = Number;
            RequestFilterHeadingML = ENU = 'English heading', DEU = 'Deutsche Ueberschrift';
        }
        dataitem(Rw2; Integer)
        {
            RequestFilterFields = Number;
            RequestFilterHeading = 'Plain heading';
        }
        dataitem(Rw3; Integer)
        {
            RequestFilterFields = Number;
        }
    }
}

report 75518 "LT Y Rep Summary"
{
    UsageCategory = None;
    DefaultRenderingLayout = SumLayout;

    dataset
    {
        dataitem(Row; Integer)
        {
            DataItemTableView = where(Number = const(1));
            column(NumCol; Number) { }
        }
    }

    rendering
    {
        layout(SumLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYSummary.rdlc';
            Caption = 'LT Y summary layout';
            SummaryML = ENU = 'English summary', DEU = 'Deutsche Zusammenfassung';
        }
        layout(PlainLayout)
        {
            Type = RDLC;
            LayoutFile = './reports/runtime/LtYSummaryPlain.rdlc';
            Caption = 'LT Y plain layout';
            Summary = 'Plain summary';
        }
    }
}

