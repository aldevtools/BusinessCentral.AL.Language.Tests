// Fixture for "OKP Ok Part Row Tests" (60760). A card over "OKP Header" (60760) hosting
// "OKP Lines Part" (60761), linked by SubPageLink. No triggers: the suite measures what the
// platform itself saves when the card is closed.
page 60760 "OKP Header Card"
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
            part(Lines; "OKP Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
