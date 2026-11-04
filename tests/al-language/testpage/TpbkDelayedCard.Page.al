// Fixture for TestPageBlankKeyInsert.al: the same Card with DelayedInsert = true.
page 60575 "TPBK Delayed Card"
{
    PageType = Card;
    SourceTable = "TPBK Row";
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
