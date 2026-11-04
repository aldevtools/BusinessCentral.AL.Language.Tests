// Fixture for TestPageFailedInsert.al: the same Card with DelayedInsert = true, so a new row is
// inserted only when the page leaves it (Close, OK).
page 60025 "IPF Delayed Card"
{
    PageType = Card;
    SourceTable = "IPF Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
