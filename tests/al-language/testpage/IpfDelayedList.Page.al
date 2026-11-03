// Fixture for TestPageFailedInsert.al: an editable List with DelayedInsert = true, so a new line
// is inserted only when the cursor leaves it (New, Next, Close).
page 60026 "IPF Delayed List"
{
    PageType = List;
    SourceTable = "IPF Row";
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = Lists;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Description; Rec.Description) { ApplicationArea = All; }
            }
        }
    }
}
