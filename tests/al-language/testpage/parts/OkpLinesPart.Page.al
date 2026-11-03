// Fixture for "OKP Ok Part Row Tests" (60760). An editable ListPart numbered by AutoSplitKey --
// the shape of a document's line grid, and of page 8619 "Config. Template Subform".
page 60761 "OKP Lines Part"
{
    PageType = ListPart;
    SourceTable = "OKP Line";
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
