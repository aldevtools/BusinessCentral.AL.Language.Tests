// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-drilldown-property
// Scope: in-scope
// Fixtures used: tables 81660, 81661, page 81662 and log codeunit 81665 of BjRequestDrillDown.al; the test is in codeunit 81666 (PX_*)
// Probe (writer PX, al-runtime-rs probes-needed "TestRequestPage.DrillDown"): DrillDown = false on request page controls, with and
//   without an OnDrillDown trigger, over a plain variable, a FlowField and a control with DrillDownPageId; one control with only an
//   OnDrillDown trigger for comparison. Not a test codeunit.
// BC versions: 27, 28, 29

report 86223 "LT PX Dd Off Report"
{
    ProcessingOnly = true;
    UsageCategory = None;

    dataset
    {
        dataitem(HeadItem; "LT BJ Dd Head") { }
    }

    requestpage
    {
        layout
        {
            area(Content)
            {
                field(OffPlain; PlainValue)
                {
                    ApplicationArea = All;
                    DrillDown = false;
                }
                field(OffTrigger; PlainValue)
                {
                    ApplicationArea = All;
                    DrillDown = false;

                    trigger OnDrillDown()
                    begin
                        DdLog.Add('off trigger ran');
                    end;
                }
                field(OnTrigger; PlainValue)
                {
                    ApplicationArea = All;

                    trigger OnDrillDown()
                    begin
                        DdLog.Add('on trigger ran');
                    end;
                }
                field(OffFlow; Head."Line Count")
                {
                    ApplicationArea = All;
                    DrillDown = false;
                }
                field(OffPageId; PlainValue)
                {
                    ApplicationArea = All;
                    DrillDown = false;
                    DrillDownPageId = "LT BJ Dd Lines A";
                }
            }
        }

        trigger OnOpenPage()
        begin
            Head.Get('H1');
            Head.CalcFields("Line Count");
            PlainValue := 7;
        end;
    }

    var
        Head: Record "LT BJ Dd Head";
        DdLog: Codeunit "LT BJ Dd Log";
        PlainValue: Integer;
}
