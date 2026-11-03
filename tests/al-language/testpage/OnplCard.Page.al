// Fixture for codeunit 60868 "ONPL Tests": a card over "ONPL Header" whose lines part,
// "ONPL Lines" (60869), is linked on the header's number.
page 60868 "ONPL Card"
{
    PageType = Card;
    SourceTable = "ONPL Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "ONPL Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
