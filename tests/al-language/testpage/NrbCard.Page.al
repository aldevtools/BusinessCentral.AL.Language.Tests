// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: NRB Header (60649), NRB Lines (60651), NRB Card (60652)
//
// Document shape: a header card hosting the line grid, linked by SubPageLink -- the same
// shape as ASK Card / TSPL Card / PKFL Card. "No." is part of "NRB Line"'s primary key, so
// this link is exactly the one #148 measured as stamped by New(); this suite asks whether
// it is also validated.

page 60652 "NRB Card"
{
    PageType = Card;
    SourceTable = "NRB Header";
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
            part(Lines; "NRB Lines")
            {
                ApplicationArea = All;
                SubPageLink = "No." = field("No.");
            }
        }
    }
}
