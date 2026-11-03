// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Line (60916), ASK Probe (60917), ASK Lines No Split (60919)
//
// Byte-for-byte "ASK Lines" WITHOUT AutoSplitKey. It exists so the suite can separate two
// things that would otherwise be indistinguishable: "invoking an action saves the current
// row" and "the platform numbers the row". A page that always numbered its lines would pass
// every AutoSplitKey assertion in the suite and fail here.

page 60919 "ASK Lines No Split"
{
    PageType = ListPart;
    SourceTable = "ASK Line";
    ApplicationArea = All;

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
