// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-runrequestpage-method
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542)
//
// A report driven through a REPORT VARIABLE rather than by id, so the instance form of
// RunRequestPage is exercised: `MyReport.RunRequestPage()` and
// `MyReport.RunRequestPage(parameters)`. The by-id form has its own report (60543); this one
// exists because the instance form carries the report's own state across the call — the
// handler writes a request-page control, and the caller reads the report global afterwards,
// which is only observable on an instance the caller still holds.
//
// The report writes a marker row in OnOpenPage of its request page, so "the page opened" is
// distinguishable from "the handler was consulted without the page ever running".

report 60319 "Test Rpt InstRunReqPage"
{
    Caption = 'Test Rpt InstRunReqPage';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "Test Rpt RunReqPage Row")
        {
            column(EntryNo; "Entry No.") { }
            column(RowName; Name) { }
        }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                group(Options)
                {
                    field(EchoText; EchoText)
                    {
                        ApplicationArea = All;
                        Caption = 'Echo Text';
                        ToolTip = 'The handler writes this; the caller reads it back off the instance.';
                    }
                }
            }
        }

        trigger OnOpenPage()
        var
            LogRec: Record "Test Rpt RunReqPage Log";
        begin
            // Runs in the report's own execution scope, which may write — unlike the
            // [RequestPageHandler] body itself. See codeunit 60545's note.
            LogRec.Log('inst-rp-open');
        end;
    }

    var
        EchoText: Text[80];

    procedure GetEchoText(): Text[80]
    begin
        exit(EchoText);
    end;
}
