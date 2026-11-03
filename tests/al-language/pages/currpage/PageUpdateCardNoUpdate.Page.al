// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: ALT Page Update Row (60491), ALT Page Update Facts (60493), ALT Page Update Trace (60492)
//
// The CONTROL arm, and it carries the suite's weight rather than decorating it. This page is
// identical to "ALT Page Update Card" except that its OnValidate calls no CurrPage.Update at
// all. Pairing the two is what makes the measurement a statement about CurrPage.Update: an
// implementation that raised OnAfterGetCurrRecord after every SetValue, or after every page
// trigger, would pass the Update arm and fail here.

page 60495 "ALT Page Update Card No Upd"
{
    PageType = Card;
    SourceTable = "ALT Page Update Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }
                field(Amount; Rec.Amount)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Trace.Note('ValidateBegin');
                        Trace.Note('ValidateEnd');
                    end;
                }
            }
        }
        area(FactBoxes)
        {
            part(Facts; "ALT Page Update Facts")
            {
                ApplicationArea = All;
            }
        }
    }

    trigger OnAfterGetCurrRecord()
    begin
        Trace.Note('HostAGCR');
        CurrPage.Facts.Page.SetHeader(Rec."No.");
    end;

    var
        Trace: Codeunit "ALT Page Update Trace";
}
