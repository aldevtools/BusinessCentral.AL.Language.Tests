// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: page extension controls and modify blocks with ShowCaption, MultiLine, Style, StyleExpr, Importance, DecimalPlaces, Ellipsis and Visible (fields, groups, actions):
// what a TestPage exposes for the extended page (Visible, Caption, Value, Enabled). Groups are no TestPage members: only the fields inside them are observed.

page 71635 "LT P119 Ext Base"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(BaseGroup)
            {
                Caption = 'Base Group';
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(DecF; Rec.Dec)
                {
                    ApplicationArea = All;
                    Importance = Standard;
                    DecimalPlaces = 2 : 2;
                }
                field(StyleF; Rec.Level) { ApplicationArea = All; }
            }
            group(HideMeGroup)
            {
                Caption = 'Hide Me';
                field(HideNote; Rec.Note) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(BaseAct)
            {
                ApplicationArea = All;
                Caption = 'Base Act';
                trigger OnAction()
                begin
                end;
            }
            action(HideAct)
            {
                ApplicationArea = All;
                Caption = 'Hide Act';
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

pageextension 71636 "LT P119 Ext" extends "LT P119 Ext Base"
{
    layout
    {
        modify(DecF)
        {
            Importance = Additional;
        }
        modify(StyleF)
        {
            StyleExpr = ExtStyle;
        }
        modify(HideMeGroup)
        {
            Visible = false;
        }
        addlast(BaseGroup)
        {
            field(ExtNote; Rec.Note)
            {
                ApplicationArea = All;
                Caption = 'Ext Note';
                ShowCaption = false;
                MultiLine = true;
            }
            field(ExtStyled; Rec.Mail)
            {
                ApplicationArea = All;
                Style = Attention;
            }
            field(ExtStyleExpr; Rec.Phone)
            {
                ApplicationArea = All;
                StyleExpr = ExtStyle;
            }
        }
        addlast(Content)
        {
            group(ExtGroup)
            {
                Caption = 'Ext Group';
                ShowCaption = false;
                field(ExtLink; Rec.Link) { ApplicationArea = All; }
            }
            group(ExtGroupAs)
            {
                Caption = 'Ext Group As';
                field(ExtSecret; Rec.Secret) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        modify(HideAct)
        {
            Visible = false;
        }
        addlast(Processing)
        {
            action(ExtAct)
            {
                ApplicationArea = All;
                Caption = 'Ext Act';
                Ellipsis = true;
                trigger OnAction()
                begin
                end;
            }
        }
    }

    var
        ExtStyle: Text;

    trigger OnAfterGetRecord()
    begin
        ExtStyle := 'Favorable';
    end;
}

codeunit 71637 "LT P119 PageExt Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ExtFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Ext Base";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('extnote-visible', Format(TP.ExtNote.Visible()));
        Observer.Observe('extnote-caption', TP.ExtNote.Caption());
        Observer.Observe('extnote-value', TP.ExtNote.Value());
        Observer.Observe('extstyled-visible', Format(TP.ExtStyled.Visible()));
        Observer.Observe('extstyled-value', TP.ExtStyled.Value());
        Observer.Observe('extstyleexpr-value', TP.ExtStyleExpr.Value());
        Observer.Observe('stylef-value', TP.StyleF.Value());
        Observer.Observe('stylef-visible', Format(TP.StyleF.Visible()));
        Observer.Observe('decf-value', TP.DecF.Value());
        Observer.Observe('decf-visible', Format(TP.DecF.Visible()));
        TP.Close();
        Observer.Expect('extnote-visible', 'Yes');
        Observer.Expect('extnote-caption', 'Ext Note');
        Observer.Expect('extnote-value', 'N1');
        Observer.Expect('extstyled-visible', 'Yes');
        Observer.Expect('extstyled-value', 'a@b.example');
        Observer.Expect('extstyleexpr-value', '555');
        Observer.Expect('stylef-value', '1');
        Observer.Expect('stylef-visible', 'Yes');
        Observer.Expect('decf-value', '2.55');
        Observer.Expect('decf-visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtMultiLineSetValue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Ext Base";
    begin
        Seed();
        TP.OpenEdit();
        TP.ExtNote.SetValue('line one');
        Observer.Observe('extnote', TP.ExtNote.Value());
        asserterror Observer.Observe('same-source-field', TP.HideNote.Value());
        Observer.ObserveError('af181');
        TP.DecF.SetValue(1.2345);
        Observer.Observe('decf-after-set', TP.DecF.Value());
        TP.Close();
        Observer.Expect('extnote', 'line one');
        Observer.Expect('af181|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af181|code', 'TestFieldNotFound');
        Observer.Expect('decf-after-set', '1.23');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtGroupFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Ext Base";
    begin
        Seed();
        TP.OpenEdit();
        asserterror Observer.Observe('hidenote-visible', Format(TP.HideNote.Visible()));
        Observer.ObserveError('af197');
        Observer.Observe('extlink-visible', Format(TP.ExtLink.Visible()));
        Observer.Observe('extsecret-visible', Format(TP.ExtSecret.Visible()));
        TP.Close();
        Observer.Expect('af197|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af197|code', 'TestFieldNotFound');
        Observer.Expect('extlink-visible', 'Yes');
        Observer.Expect('extsecret-visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ExtActions()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Ext Base";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('baseact-visible', Format(TP.BaseAct.Visible()));
        Observer.Observe('hideact-visible', Format(TP.HideAct.Visible()));
        Observer.Observe('hideact-enabled', Format(TP.HideAct.Enabled()));
        Observer.Observe('extact-visible', Format(TP.ExtAct.Visible()));
        Observer.Observe('extact-enabled', Format(TP.ExtAct.Enabled()));
        TP.ExtAct.Invoke();
        Observer.Observe('extact-invoked', 'no error');
        TP.Close();
        Observer.Expect('baseact-visible', 'Yes');
        Observer.Expect('hideact-visible', 'No');
        Observer.Expect('hideact-enabled', 'Yes');
        Observer.Expect('extact-visible', 'Yes');
        Observer.Expect('extact-enabled', 'Yes');
        Observer.Expect('extact-invoked', 'no error');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Note := 'N1';
        Row.Mail := 'a@b.example';
        Row.Phone := '555';
        Row.Level := 1;
        Row.Dec := 2.55;
        Row.Insert();
    end;
}
