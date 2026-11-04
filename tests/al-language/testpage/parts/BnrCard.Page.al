// Fixture for codeunit 69940 "BNR Blank Part Tests": a host whose part is linked by SubPageLink.
page 69941 "BNR Card"
{
    PageType = Card;
    SourceTable = "BNR Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "BNR Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
