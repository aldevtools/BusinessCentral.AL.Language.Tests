// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-data-type
// Scope: in-scope
// Fixtures used: ALT DateFormula Row (60604)
//
// Four controls, chosen so that no arm can pass by accident:
//
//   RecPeriod   — a DateFormula control bound to a TABLE FIELD. This is the binding a report
//                 request page uses for a DateFormula request-page field.
//   VarPeriod   — a DateFormula control bound to a PAGE VARIABLE. Same declared type, different
//                 binding; BC's TestPage write path reaches it by a different route, so a
//                 platform that handled only one of the two would pass one arm and fail the
//                 other.
//   RecText     — a Text control on the same page. The control arm: it pins that a control
//                 whose type is NOT DateFormula still takes a text value unchanged, so an
//                 implementation that sent every control through DateFormula evaluation would
//                 fail here while passing every DateFormula arm.
//   VarText     — the page-variable sibling of RecText, for the same reason on the other
//                 binding.
//
// SetValue is string-typed on AL's TestPage surface for every control, so what this suite asks
// is what a real BC tier does when that string names a date formula and the control's declared
// type is DateFormula.

page 60605 "ALT DateFormula Card"
{
    PageType = Card;
    SourceTable = "ALT DateFormula Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field("No."; Rec."No.") { ApplicationArea = All; }

                field(RecPeriod; Rec."Period Length")
                {
                    ApplicationArea = All;
                    Caption = 'RecPeriod';
                }

                field(RecText; Rec.Description)
                {
                    ApplicationArea = All;
                    Caption = 'RecText';
                }

                field(VarPeriod; VarPeriodLength)
                {
                    ApplicationArea = All;
                    Caption = 'VarPeriod';
                }

                field(VarText; VarDescription)
                {
                    ApplicationArea = All;
                    Caption = 'VarText';
                }
            }
        }
    }

    var
        VarPeriodLength: DateFormula;
        VarDescription: Text[50];
}
