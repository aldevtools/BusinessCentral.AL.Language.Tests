// Fixture host card for TestPagePartOnNewRecordCount.al: one part, linked on the line table's
// first primary-key field -- the shape of every document card in the Base Application.
page 60357 "ONRC Card"
{
    PageType = Card;
    SourceTable = "ONRC Header";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            part(Lines; "ONRC Lines")
            {
                ApplicationArea = All;
                SubPageLink = "Header No." = field("No.");
            }
        }
    }
}
