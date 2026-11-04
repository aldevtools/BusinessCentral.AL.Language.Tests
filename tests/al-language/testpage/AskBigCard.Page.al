// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Big Lines (60924), ASK Big Card (60925)
//
// Document shape for the BigInteger split-key grid, mirroring "ASK Card" (60920).

page 60925 "ASK Big Card"
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
            part(Lines; "ASK Big Lines")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
