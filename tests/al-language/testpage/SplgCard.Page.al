// Fixture for "SPLG Tests" (60232): the host card carrying both SPLG parts.
page 60231 "SPLG Card"
{
    PageType = Card;
    SourceTable = "SPLG Header";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field("Sel Line No."; Rec."Sel Line No.") { ApplicationArea = All; }
            part(LinkPart; "SPLG Link Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code"), "Line No." = field("Sel Line No.");
            }
            part(OwnPart; "SPLG Own Filter Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
