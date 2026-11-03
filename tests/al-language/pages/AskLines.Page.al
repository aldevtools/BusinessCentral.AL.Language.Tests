// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Line (60916), ASK Probe (60917), ASK Lines (60918)
//
// The editable line grid: AutoSplitKey = true, and no numbering AL of its own. The Probe
// action records what the current row looks like at the instant OnAction runs.
//
// "Line No." is deliberately NOT a control on this page, so no test can set it through the
// TestPage even by accident — any value it carries was assigned by the platform.

page 60918 "ASK Lines"
{
    PageType = ListPart;
    SourceTable = "ASK Line";
    ApplicationArea = All;
    AutoSplitKey = true;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Descr; Rec.Descr)
                {
                    ApplicationArea = All;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Probe)
            {
                ApplicationArea = All;
                Caption = 'Probe';

                trigger OnAction()
                var
                    AskProbe: Codeunit "ASK Probe";
                begin
                    AskProbe.Observe(Rec."No.", Rec."Line No.", Rec.Descr);
                end;
            }
        }
    }
}
