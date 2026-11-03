// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-triggers
// Scope: in-scope
// Fixtures used: ALT Page Find Record Row (60671)
//
// The control arm. Identical to "ALT Page Find Record List" in source table, sort and layout,
// and different in exactly one respect: it declares neither OnFindRecord nor OnNextRecord. So
// it says what the same navigation answers when the page does NOT override the rowset, which
// is what makes the other page's answers attributable to the triggers rather than to the
// descending SourceTableView or to the filters.

page 60674 "ALT Page Find Record Plain"
{
    PageType = List;
    SourceTable = "ALT Page Find Record Row";
    SourceTableView = sorting("No.") order(descending);
    Editable = false;
    ApplicationArea = All;

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
