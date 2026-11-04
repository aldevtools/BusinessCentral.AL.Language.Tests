// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: label control properties MultiLine, ShowCaption, Style, StyleExpr, Importance and Visible. A label is a TestPage member (TestPageLabelControlContracts.al):
// Visible, Caption and Value are observed.

page 71660 "LT P119 Labels Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                label(LabelMulti)
                {
                    ApplicationArea = All;
                    Caption = 'Multi line label';
                    MultiLine = true;
                    Importance = Promoted;
                }
                label(LabelStyled)
                {
                    ApplicationArea = All;
                    Caption = 'Styled label';
                    Style = Strong;
                }
                label(LabelExpr)
                {
                    ApplicationArea = All;
                    Caption = 'Expr label';
                    StyleExpr = StyleTxt;
                }
                label(LabelNoCaption)
                {
                    ApplicationArea = All;
                    Caption = 'No caption label';
                    ShowCaption = false;
                }
                label(LabelHidden)
                {
                    ApplicationArea = All;
                    Caption = 'Hidden label';
                    Visible = false;
                }
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    var
        StyleTxt: Text;

    trigger OnAfterGetRecord()
    begin
        StyleTxt := 'Unfavorable';
    end;
}

codeunit 71661 "LT P119 Labels Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_LabelVisible()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Labels Card";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('multi-visible', Format(TP.LabelMulti.Visible()));
        Observer.Observe('styled-visible', Format(TP.LabelStyled.Visible()));
        Observer.Observe('expr-visible', Format(TP.LabelExpr.Visible()));
        Observer.Observe('nocaption-visible', Format(TP.LabelNoCaption.Visible()));
        asserterror Observer.Observe('hidden-visible', Format(TP.LabelHidden.Visible()));
        Observer.ObserveError('af83');
        Observer.Observe('multi-enabled', Format(TP.LabelMulti.Enabled()));
        Observer.Observe('multi-editable', Format(TP.LabelMulti.Editable()));
        TP.Close();
        Observer.Expect('multi-visible', 'Yes');
        Observer.Expect('styled-visible', 'Yes');
        Observer.Expect('expr-visible', 'Yes');
        Observer.Expect('nocaption-visible', 'Yes');
        Observer.Expect('af83|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af83|code', 'TestFieldNotFound');
        Observer.Expect('multi-enabled', 'Yes');
        Observer.Expect('multi-editable', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P119_LabelCaptionAndValue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Labels Card";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('multi-caption', TP.LabelMulti.Caption());
        Observer.Observe('multi-value', TP.LabelMulti.Value());
        Observer.Observe('styled-caption', TP.LabelStyled.Caption());
        Observer.Observe('styled-value', TP.LabelStyled.Value());
        Observer.Observe('expr-caption', TP.LabelExpr.Caption());
        Observer.Observe('nocaption-caption', TP.LabelNoCaption.Caption());
        Observer.Observe('nocaption-value', TP.LabelNoCaption.Value());
        asserterror Observer.Observe('hidden-caption', TP.LabelHidden.Caption());
        Observer.ObserveError('af106');
        asserterror Observer.Observe('hidden-value', TP.LabelHidden.Value());
        Observer.ObserveError('af108');
        TP.Close();
        Observer.Expect('multi-caption', 'Multi line label');
        Observer.Expect('multi-value', 'Multi line label');
        Observer.Expect('styled-caption', 'Styled label');
        Observer.Expect('styled-value', 'Styled label');
        Observer.Expect('expr-caption', 'Expr label');
        Observer.Expect('nocaption-caption', 'No caption label');
        Observer.Expect('nocaption-value', 'No caption label');
        Observer.Expect('af106|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af106|code', 'TestFieldNotFound');
        Observer.Expect('af108|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af108|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Lab';
        Row.Insert();
    end;
}
