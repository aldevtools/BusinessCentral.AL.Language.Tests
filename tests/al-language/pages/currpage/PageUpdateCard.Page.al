// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: ALT Page Update Row (60491), ALT Page Update Facts (60493), ALT Page Update Trace (60492)
//
// The CurrPage.Update arm. Two routes reach CurrPage.Update on ONE page, so the suite can ask
// whether the refresh follows the call or follows the kind of trigger that made it:
//
//   * the Amount field's OnValidate calls CurrPage.Update(true)
//   * the RefreshOnly action's OnAction calls CurrPage.Update(true) and touches nothing else
//
// Both bracket their call with a Note, so the trace records not just THAT the host's
// OnAfterGetCurrRecord ran but whether it ran before or after the calling trigger returned.

page 60494 "ALT Page Update Card"
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
                        CurrPage.Update(true);
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

    actions
    {
        area(Processing)
        {
            action(RefreshOnly)
            {
                ApplicationArea = All;
                Caption = 'Refresh Only';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    CurrPage.Update(true);
                    Trace.Note('ActionEnd');
                end;
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
