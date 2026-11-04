// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-request-pages
// Scope: in-scope
// Fixtures for codeunit 84549 "LT CH Report Leads" (ChReportLeads.al): report 84533 with a part (page 84534, ChReportFixtures.al) on its request page.
// Item 117 of corpus issue 667: RequestOptionsPage.<Part>.Page.<Procedure>() called from the request page OnOpenPage.
// The same call from a report trigger (OnPreReport) does not compile: AL0161, must-not-compile case 1656.

report 84533 "LT CH RP Part Host"
{
    ProcessingOnly = true;
    UsageCategory = None;

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(Opt; OptVal) { ApplicationArea = All; Caption = 'Opt'; }
                }
                part(ChPart; "LT CH RP Part")
                {
                    ApplicationArea = All;
                }
            }
        }

        trigger OnOpenPage()
        begin
            Log.Add('OnOpenPage ' + RequestOptionsPage.ChPart.Page.Ping());
        end;
    }

    var
        Log: Codeunit "LT CH R Log";
        OptVal: Integer;
}
