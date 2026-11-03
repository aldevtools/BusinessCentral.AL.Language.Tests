// Fixture for "PCN Tests" (60535). An editable ListPart numbered by AutoSplitKey -- the shape of
// a document's line grid -- linked to its host by SubPageLink, so a row it writes lands in
// "PCN Line" (60534) and outlives the page.
page 60534 "PCN Lines Part"
{
    PageType = ListPart;
    SourceTable = "PCN Line";
    AutoSplitKey = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field(Reference; Rec.Reference) { ApplicationArea = All; }
            }
        }
    }
}
