// Fixture for "OKP Part Next Tests" (60229). "OKP Lines Part" (60761) declared Editable = false,
// the shape of Base Application page 133 "Posted Sales Invoice Subform".
page 60014 "OKP Read-Only Lines Part"
{
    PageType = ListPart;
    SourceTable = "OKP Line";
    AutoSplitKey = true;
    Editable = false;
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
