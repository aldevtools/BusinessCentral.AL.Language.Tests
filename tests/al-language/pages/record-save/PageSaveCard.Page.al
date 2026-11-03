// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Page Save Row (60560)
//
// A DelayedInsert card whose only editable field validates into CurrPage.Update(). That is the
// shape Base Application's own "User Card" uses, and it is what makes the platform SAVE the row
// from inside the field's OnValidate rather than when the cursor leaves the record: the page's
// own save path writes the row, not Record.Insert and not Record.Modify.
//
// The page assigns nothing itself. Every value the suite reads off the saved row -- the
// AutoIncrement key and the four system fields -- can therefore only have come from the
// platform's data layer.

page 60561 "ALT Page Save Card"
{
    PageType = Card;
    SourceTable = "ALT Page Save Row";
    DelayedInsert = true;
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(DescriptionField; Rec.Description)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update();
                    end;
                }
            }
        }
    }
}
