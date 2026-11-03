// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currreport/currreport-language-property
// Scope: in-scope
// Fixtures used: CurrReport Language Row (60527)
//
// A report that switches language per row, the way the Base App's document reports do
// (Standard Sales - Invoice sets CurrReport.Language from the customer's language code in
// its Header data item's OnAfterGetRecord).

report 60528 "CurrReport Language Report"
{
    Caption = 'CurrReport Language Report';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    DefaultRenderingLayout = CurrReportLanguageLayout;

    dataset
    {
        dataitem(Rows; "CurrReport Language Row")
        {
            column(EntryNo; "Entry No.") { }
            column(LangId; LanguageId) { }

            trigger OnAfterGetRecord()
            begin
                CurrReport.Language := Rows.LanguageId;
                LanguageAfterSet := CurrReport.Language;
                RowsSeen += 1;
            end;
        }
    }

    rendering
    {
        layout(CurrReportLanguageLayout)
        {
            Type = RDLC;
            LayoutFile = './_fixtures/layouts/TestReportCurrReportLanguageReport.rdl';
            Caption = 'CurrReport Language layout';
        }
    }

    var
        RowsSeen: Integer;
        LanguageAfterSet: Integer;
        FormatRegionAfterSet: Text;

    trigger OnPreReport()
    begin
        CurrReport.FormatRegion := 'en-US';
        FormatRegionAfterSet := CurrReport.FormatRegion;
    end;

    procedure RowsProcessed(): Integer
    begin
        exit(RowsSeen);
    end;

    procedure LanguageSeen(): Integer
    begin
        exit(LanguageAfterSet);
    end;

    procedure FormatRegionSeen(): Text
    begin
        exit(FormatRegionAfterSet);
    end;
}
