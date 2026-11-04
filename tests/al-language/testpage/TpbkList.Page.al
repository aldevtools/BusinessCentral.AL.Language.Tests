// Fixture for TestPageBlankKeyInsert.al: an editable List over the same table, DelayedInsert false.
page 60580 "TPBK List"
{
    PageType = List;
    SourceTable = "TPBK Row";
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
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
