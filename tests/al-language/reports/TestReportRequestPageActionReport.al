// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-test-requestpage
// Scope: in-scope
// Fixtures used: Test Rpt RunReqPage Row (60541), Test Rpt RunReqPage Log (60542)
//
// A report whose request page declares its own ACTIONS, next to one control bound to a report
// global. Each action's OnAction trigger writes report globals and the data item logs what it
// reads back, so the log shows whether any OnAction ran before the body.
//
// ProcessingOnly so no part of the claim depends on rendering.

report 60398 "Test Rpt ReqPage Action"
{
    Caption = 'Test Rpt ReqPage Action';
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
                LogRec.Log(CopyStr('body-text:' + EchoText, 1, 50));
                LogRec.Log(CopyStr(StrSubstNo('body-actions:%1', ActionRuns), 1, 50));
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
                        ToolTip = 'Text the actions write; the body logs what it reads back.';
                    }
                }
            }
        }

        actions
        {
            area(Processing)
            {
                action(StampText)
                {
                    ApplicationArea = All;
                    Caption = 'Stamp Text';
                    ToolTip = 'Overwrites the Echo Text global.';

                    trigger OnAction()
                    begin
                        EchoText := 'set-by-action';
                        ActionRuns += 1;
                    end;
                }
                action(AppendText)
                {
                    ApplicationArea = All;
                    Caption = 'Append Text';
                    ToolTip = 'Appends to the Echo Text global, so two invocations are distinguishable from one.';

                    trigger OnAction()
                    begin
                        EchoText := CopyStr(EchoText + '+a', 1, MaxStrLen(EchoText));
                        ActionRuns += 1;
                    end;
                }
                action(RefuseAction)
                {
                    ApplicationArea = All;
                    Caption = 'Refuse Action';
                    ToolTip = 'Raises an error, so a handler can observe that OnAction ran.';

                    trigger OnAction()
                    begin
                        Error(RefusedErr);
                    end;
                }
            }
        }
    }

    trigger OnInitReport()
    begin
        EchoText := 'from-report';
        ActionRuns := 0;
    end;

    var
        EchoText: Text[50];
        ActionRuns: Integer;
        RefusedErr: Label 'refused-by-request-page-action';
}
