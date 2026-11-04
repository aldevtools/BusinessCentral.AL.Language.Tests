// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope
// Fixtures used: TPD Dec Row (69931)

page 69931 "TPD Dec Card"
{
    PageType = Card;
    SourceTable = "TPD Dec Row";
    ApplicationArea = All;
    UsageCategory = Administration;
    Caption = 'TPD Dec Card';

    layout
    {
        area(Content)
        {
            field(Amount; Rec.Amount) { ApplicationArea = All; Caption = 'Amount'; DecimalPlaces = 2 : 2; }
        }
    }
}
