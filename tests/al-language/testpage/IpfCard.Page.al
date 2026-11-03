// Fixture for TestPageFailedInsert.al: a Card with DelayedInsert left at its default (false), so a
// new row is inserted when focus moves to a non-key control.
page 60027 "IPF Card"
{
    PageType = Card;
    SourceTable = "IPF Row";
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
