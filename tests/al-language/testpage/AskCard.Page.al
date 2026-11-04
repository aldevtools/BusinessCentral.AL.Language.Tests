// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Lines (60918), ASK Card (60920)
//
// Document shape: a header card hosting the AutoSplitKey line grid, linked by SubPageLink.
// The lines are reachable only through the part, which is how an AL test drives them.

page 60920 "ASK Card"
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
            part(Lines; "ASK Lines")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
