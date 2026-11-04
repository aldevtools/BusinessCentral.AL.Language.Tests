// Fixture for TestPageBlankKeyInsert.al: a Card with DelayedInsert left at its default (false).
page 60574 "TPBK Card"
{
    PageType = Card;
    SourceTable = "TPBK Row";
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
