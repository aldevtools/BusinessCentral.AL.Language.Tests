// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Lines No Split (60919), ASK Card No Split (60921)
//
// The same card over the same tables, hosting the part that does NOT declare AutoSplitKey.
// See ASK Lines No Split for why the suite needs both.

page 60921 "ASK Card No Split"
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
            part(Lines; "ASK Lines No Split")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
