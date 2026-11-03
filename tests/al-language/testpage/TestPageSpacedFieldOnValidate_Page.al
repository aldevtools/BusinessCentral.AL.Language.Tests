// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-field-setvalue-method
// Scope: in-scope
// Fixtures used: Spaced Field Row (60247), Spaced Field Card (60248)
//
// A card page whose two Payload controls differ only in whether the control NAME
// contains a space. Each control's page OnValidate writes a distinct marker, so a
// test can tell "the trigger ran" apart from "the value was applied" — the failure
// this suite pins is exactly the split between those two.

page 60248 "Spaced Field Card"
{
    PageType = Card;
    SourceTable = "Spaced Field Row";
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
                field(MarkerUnspaced; Rec.Payload)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Marker := 'UNSPACED-RAN';
                    end;
                }
                field("Marker Spaced"; Rec.Payload)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Rec.Marker := 'SPACED-RAN';
                    end;
                }
                field("Always Fails Spaced"; Rec.Payload)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Error('Spaced Field Card control refused deliberately');
                    end;
                }
                field(Marker; Rec.Marker)
                {
                    ApplicationArea = All;
                }
            }
        }
    }
}
