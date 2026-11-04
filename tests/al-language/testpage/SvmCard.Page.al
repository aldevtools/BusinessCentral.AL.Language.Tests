// Scope: in-scope
// Card page over "SVM Row" for the same-value SetValue suite. Deliberately plain: no record
// triggers of its own, so the only thing that can bump the tally is the table's OnModify,
// reached through the page's own save path.
page 60410 "SVM Card"
{
    PageType = Card;
    SourceTable = "SVM Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Note; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}
