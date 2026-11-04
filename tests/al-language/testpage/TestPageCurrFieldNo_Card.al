// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: TP CurrFieldNo Row (60388)

page 60389 "TP CurrFieldNo Card"
{
    PageType = Card;
    SourceTable = "TP CurrFieldNo Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TP CurrFieldNo Card';

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            field(Amount; Rec.Amount)
            {
                ApplicationArea = All;
            }
            field(ValidateFieldNo; Rec.ValidateFieldNo)
            {
                ApplicationArea = All;
            }
        }
    }
}
