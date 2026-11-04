// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT RptMrg Capture (70831), LT RptMrg Helper (70835), LT RptMrg Row (70826); own report 70885 (same Custom layout file as report 70883)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// and with which ReportAction Report.Run of a report WITH a request page (closed with OK by a RequestPageHandler) calls it. Handlers are declared only for tests that surely open the page.
// Risky: Report.RunRequestPage and request page handlers; the whole file is one unit.
// BC versions: 29 (the final facts get added later)

report 70885 "LT RptMrg ReqPage Report"
{
    Caption = 'LT Merger ReqPage';
    DefaultRenderingLayout = CustomA;

    dataset
    {
        dataitem(Rows; "LT RptMrg Row")
        {
            column(RowId; Id) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(Mode; Mode)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    rendering
    {
        layout(CustomA)
        {
            Type = Custom;
            LayoutFile = './_fixtures/layouts/ReportMergerLayoutA.rlblayout';
            MimeType = 'application/x-lmc-layout';
            Caption = 'Merger layout A';
        }
    }

    var
        Mode: Integer;
}

