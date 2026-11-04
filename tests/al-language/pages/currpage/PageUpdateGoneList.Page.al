// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Trace (67301)
//
// "ALT Page Update Gone Card" (67300) as a List, so the suite can tell whether what happens to a
// page whose current row is gone depends on the page type.

page 67301 "ALT Page Update Gone List"
{
    PageType = List;
    SourceTable = "ALT Page Update Gone Row";
    DelayedInsert = true;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeField; Rec.Code)
                {
                    ApplicationArea = All;
                }
                field(NameField; Rec.Name)
                {
                    ApplicationArea = All;

                    trigger OnValidate()
                    begin
                        Trace.Note('Validate');
                        CurrPage.Update(false);
                    end;
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAndUpdate)
            {
                ApplicationArea = All;
                Caption = 'Delete And Update';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    Rec.Delete();
                    CurrPage.Update(false);
                    Trace.Note('ActionEnd');
                end;
            }
            action(DeleteOnly)
            {
                ApplicationArea = All;
                Caption = 'Delete Only';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    Rec.Delete();
                    Trace.Note('ActionEnd');
                end;
            }
            action(UpdateOnly)
            {
                ApplicationArea = All;
                Caption = 'Update Only';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    CurrPage.Update(false);
                    Trace.Note('ActionEnd');
                end;
            }
        }
    }

    trigger OnAfterGetRecord()
    begin
        Trace.Note('AGR:' + Rec.Code);
    end;

    trigger OnAfterGetCurrRecord()
    begin
        Trace.Note('AGCR:' + Rec.Code);
    end;

    var
        Trace: Codeunit "ALT Page Update Gone Trace";
}
