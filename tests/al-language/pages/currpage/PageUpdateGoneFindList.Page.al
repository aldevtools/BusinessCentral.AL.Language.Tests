// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-onfindrecord-page-trigger
// Scope: in-scope
// Fixtures used: ALT Page Update Gone Row (67300), ALT Page Update Gone Trace (67301)
//
// "ALT Page Update Gone List" (67301) with an OnFindRecord trigger, so the suite can tell whether
// the client's re-read of a List whose current row is gone goes through that trigger, and with
// which Which string. The DeleteAndPickFirst action makes the trigger answer the first row, which
// the default re-read would not land on when a middle row is deleted. DeletePassThrough leaves the
// trigger a plain Rec.Find(Which), the common shape, which answers false on the deleted key.

page 67302 "ALT Page Update Gone Find List"
{
    PageType = List;
    SourceTable = "ALT Page Update Gone Row";
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
                }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(DeleteAndPickFirst)
            {
                ApplicationArea = All;
                Caption = 'Delete And Pick First';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    PickFirst := true;
                    Rec.Delete();
                    Trace.Note('ActionEnd');
                end;
            }
            action(DeletePassThrough)
            {
                ApplicationArea = All;
                Caption = 'Delete Pass Through';

                trigger OnAction()
                begin
                    Trace.Note('ActionBegin');
                    Rec.Delete();
                    Trace.Note('ActionEnd');
                end;
            }
        }
    }

    trigger OnFindRecord(Which: Text): Boolean
    begin
        Trace.Note('Find:' + Which);
        if PickFirst then
            exit(Rec.FindFirst());
        exit(Rec.Find(Which));
    end;

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
        PickFirst: Boolean;
}
