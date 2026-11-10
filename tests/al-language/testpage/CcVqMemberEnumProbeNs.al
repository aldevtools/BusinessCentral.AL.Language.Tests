// Fixture for CcVqMemberEnumProbe.al V11: an enum in a one-segment namespace and a page of that namespace that names it in its
// control expressions as LTVQProbe."LT VQP Ns Kind"::Beta.

namespace LTVQProbe;

enum 97290 "LT VQP Ns Kind"
{
    Extensible = false;

    value(0; Alpha) { }
    value(1; Beta) { }
}

page 97298 "LT VQP Page V11"
{
    PageType = Card;
    SourceTable = "LT VQP Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Id; Rec.Id) { ApplicationArea = All; }
            field(VisCtl; Rec.Name)
            {
                ApplicationArea = All;
                Visible = Dir = LTVQProbe."LT VQP Ns Kind"::Beta;
            }
            field(EdtCtl; Rec.Name)
            {
                ApplicationArea = All;
                Editable = Dir = LTVQProbe."LT VQP Ns Kind"::Beta;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActCtl)
            {
                ApplicationArea = All;
                Enabled = Dir = LTVQProbe."LT VQP Ns Kind"::Beta;

                trigger OnAction()
                begin
                end;
            }
            action(FlipCtl)
            {
                ApplicationArea = All;

                trigger OnAction()
                begin
                    Dir := Dir::Alpha;
                end;
            }
        }
    }

    trigger OnOpenPage()
    begin
        Dir := Dir::Beta;
    end;

    var
        Dir: Enum LTVQProbe."LT VQP Ns Kind";
}
