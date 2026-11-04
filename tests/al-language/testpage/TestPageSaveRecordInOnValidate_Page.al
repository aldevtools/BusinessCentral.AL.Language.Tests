// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: Save Record Row (60250), Save Record Card (60251)
//
// A card page whose three Description controls differ only in how the edit gets
// saved: DescSave's page OnValidate calls CurrPage.SaveRecord() (the pattern BC
// docs give for persisting mid-validate), DescUpdate's calls CurrPage.Update(true),
// DescPlain has no trigger and relies on the implicit save when the page closes.
// All three must MODIFY the existing row the page is positioned on — a save path
// that misclassifies the write as an Insert dies on the primary key.

page 60251 "Save Record Card"
{
    PageType = Card;
    SourceTable = "Save Record Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.")
                {
                    ApplicationArea = All;
                }
                field(DescSave; Rec.Description)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field(DescUpdate; Rec.Description)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.Update(true);
                    end;
                }
                field(DescPlain; Rec.Description)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
