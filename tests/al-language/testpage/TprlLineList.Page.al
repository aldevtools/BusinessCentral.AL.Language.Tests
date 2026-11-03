// Fixture RunObject target for TestPageActionRunPageLink.al: an ordinary List over the line
// table. Editable = false so the page carries no implicit new-row line, which would otherwise
// add a row to every count the handler takes and make "how many rows did the link select"
// unanswerable.
page 60465 "TPRL Line List"
{
    PageType = List;
    SourceTable = "TPRL Line";
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
                field("Head No."; Rec."Head No.") { ApplicationArea = All; }
                field("Line No."; Rec."Line No.") { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}
