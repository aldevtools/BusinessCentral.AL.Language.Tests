// Second fixture RunObject target for TestPageActionRunPageLink.al, over the HOST's own table
// rather than the line table. It exists for the one action that declares RunPageLink and
// RunPageOnRec together -- RunPageOnRec hands the target the host's record, which is only
// expressible when the two share a source table.
page 60467 "TPRL Head List"
{
    PageType = List;
    SourceTable = "TPRL Head";
    ApplicationArea = All;
    UsageCategory = Lists;
    Editable = false;
    InsertAllowed = false;
    DeleteAllowed = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
