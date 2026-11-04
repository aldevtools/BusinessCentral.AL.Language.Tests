// Fixture for codeunit 69143 "PVD Provider Move Tests": a host whose part has a SubPageLink and NO
// Provider, and which no other part names as a Provider.
page 69143 "PVD Plain Card"
{
    PageType = Card;
    SourceTable = "PVD Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "PVD Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
