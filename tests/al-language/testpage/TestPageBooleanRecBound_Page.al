// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: TP Boolean Rec Bound Row (60994)
//
// RecFlag is bound directly to the source table field (field(RecFlag; Rec.Flag)), as opposed to
// a page variable — see TestPageVariableControl_Page.al for the variable-bound counterpart. The
// two look identical in AL but round-trip through different runtime plumbing, which is exactly
// why a runner emulating this can pass one and fail the other.

page 60993 "TP Boolean Rec Bound Card"
{
    PageType = Card;
    SourceTable = "TP Boolean Rec Bound Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP Boolean Rec Bound Card';

    layout
    {
        area(Content)
        {
            field(RecValue; Rec.Value)
            {
                ApplicationArea = All;
                Caption = 'Rec Value';
            }

            field(RecFlag; Rec.Flag)
            {
                ApplicationArea = All;
                Caption = 'Rec Flag';
            }
        }
    }
}
