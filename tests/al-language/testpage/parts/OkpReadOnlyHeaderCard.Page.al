// Fixture for "OKP Part Next Tests" (60229). The same card as "OKP Header Card" (60760), but
// hosting "OKP Read-Only Lines Part" (60014) -- a part page declared Editable = false, the
// shape of Base Application page 133 "Posted Sales Invoice Subform".
page 60013 "OKP Read-Only Header Card"
{
    PageType = Card;
    SourceTable = "OKP Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code") { ApplicationArea = All; }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "OKP Read-Only Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
