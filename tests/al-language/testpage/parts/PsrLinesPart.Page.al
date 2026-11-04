// Fixture for "PSR Page Saved Row Tests" (60412). A DelayedInsert line grid, like a sales or
// purchase order subform, whose first field saves the row from its own OnValidate — the shape of
// "Sales Order Subform".QuantityOnAfterValidate calling CurrPage.SaveRecord().
page 60413 "PSR Lines Part"
{
    PageType = ListPart;
    SourceTable = "PSR Line";
    AutoSplitKey = true;
    DelayedInsert = true;
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Lines)
            {
                field("Saved Field"; Rec."Saved Field")
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        CurrPage.SaveRecord();
                    end;
                }
                field("Later Field"; Rec."Later Field") { ApplicationArea = All; }
            }
        }
    }
}
