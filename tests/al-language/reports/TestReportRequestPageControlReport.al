// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542)
//
// A report whose request page carries two controls bound to REPORT GLOBALS — the ordinary
// shape for report options ("Show amounts in LCY", "Print unapplied entries"). Nothing here
// is bound to a source table, which is the whole point: the controls exist to let a
// [RequestPageHandler] choose report options, and the only way those choices matter is if
// the report BODY reads them back off the same globals.
//
// ProcessingOnly so no part of the claim depends on rendering.

report 60751 "Test Rpt ReqPage Ctrl"
{
    Caption = 'Test Rpt ReqPage Ctrl';
    UsageCategory = ReportsAndAnalysis;
    ApplicationArea = All;
    ProcessingOnly = true;

    dataset
    {
        dataitem(Rows; "Test Rpt RunReqPage Row")
        {
            trigger OnAfterGetRecord()
            var
                LogRec: Record "Test Rpt RunReqPage Log";
            begin
                // What the body actually sees, logged verbatim. If a handler's SetValue were
                // held anywhere other than the report's own global, this row would carry the
                // report's default instead of the handler's value.
                LogRec.Log(CopyStr('body-text:' + EchoText, 1, 50));
                if IncludeAll then
                    LogRec.Log('body-flag:on')
                else
                    LogRec.Log('body-flag:off');
            end;
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
                        ToolTip = 'Text option the handler sets; the body logs what it reads back.';
                    }
                    field(IncludeAll; IncludeAll)
                    {
                        ApplicationArea = All;
                        Caption = 'Include All';
                        ToolTip = 'Boolean option the handler sets; the body logs which branch it took.';
                    }
                }
            }
        }
    }

    // Seeded before the request page opens, so a handler that reads a control without
    // writing it sees the report's own value rather than a blank — which is what makes
    // "the control reads the global" a testable claim in both directions.
    trigger OnInitReport()
    begin
        EchoText := 'from-report';
        IncludeAll := false;
    end;

    var
        EchoText: Text[50];
        IncludeAll: Boolean;
}
