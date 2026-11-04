// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: Test Page OnValidate Row (60711), Test Page OnValidate Card (60712)

page 60712 "Test Page OnValidate Card"
{
    PageType = Card;
    SourceTable = "Test Page OnValidate Row";
    ApplicationArea = All;
    UsageCategory = Administration;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Source; Rec.Source) { ApplicationArea = All; }
                field(Derived; Rec.Derived) { ApplicationArea = All; }
                field(Manual; Rec.Manual) { ApplicationArea = All; }
                field(Guarded; Rec.Guarded) { ApplicationArea = All; }
                field(PageEcho; Rec.PageEcho) { ApplicationArea = All; }

                // A control's own OnValidate is a second, independent trigger from the table
                // field's, and a runner can wire one without the other. Bound to the SAME field
                // as the plain Manual control above, so the only difference between the two is
                // this trigger — which is exactly what the test needs to attribute the effect to.
                field(Watched; Rec.Manual)
                {
                    ApplicationArea = All;
                    Caption = 'Watched';

                    trigger OnValidate()
                    begin
                        Rec.PageEcho := 'control-saw-' + Rec.Manual;
                    end;
                }
            }
        }
    }
}
