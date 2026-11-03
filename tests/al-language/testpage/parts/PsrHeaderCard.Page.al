// Fixture for "PSR Page Saved Row Tests" (60412). A card over "PSR Header" (60412) hosting
// "PSR Lines Part" (60413). Its key field saves the new row from its own OnValidate.
page 60412 "PSR Header Card"
{
    PageType = Card;
    SourceTable = "PSR Header";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("Code"; Rec."Code")
            {
                ApplicationArea = All;

                trigger OnValidate()
                begin
                    CurrPage.SaveRecord();
                end;
            }
            field(Descr; Rec.Descr) { ApplicationArea = All; }
            part(Lines; "PSR Lines Part")
            {
                ApplicationArea = All;
                SubPageLink = "Header Code" = field("Code");
            }
        }
    }
}
