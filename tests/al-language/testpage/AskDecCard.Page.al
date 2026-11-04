// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Dec Lines (60927), ASK Dec Card (60928)
//
// Document shape for the Decimal split-key grid, mirroring "ASK Card" (60920).

page 60928 "ASK Dec Card"
{
    PageType = Card;
    SourceTable = "ASK Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.")
            {
                ApplicationArea = All;
            }
            part(Lines; "ASK Dec Lines")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
