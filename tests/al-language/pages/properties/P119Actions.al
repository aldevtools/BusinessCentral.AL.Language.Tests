// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: page action property Ellipsis (declared; TestAction exposes Visible and Enabled, the caption is observed in P119ActionsCaption.al) next to Visible and Enabled.

page 71631 "LT P119 Actions Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name) { ApplicationArea = All; }
        }
    }

    actions
    {
        area(Processing)
        {
            action(ActPlain)
            {
                ApplicationArea = All;
                Caption = 'Plain Action';
                trigger OnAction()
                begin
                end;
            }
            action(ActEllipsis)
            {
                ApplicationArea = All;
                Caption = 'Post';
                Ellipsis = true;
                trigger OnAction()
                begin
                end;
            }
            action(ActEllipsisOff)
            {
                ApplicationArea = All;
                Caption = 'Send...';
                Ellipsis = false;
                trigger OnAction()
                begin
                end;
            }
            action(ActEllipsisHidden)
            {
                ApplicationArea = All;
                Caption = 'Hidden';
                Ellipsis = true;
                Visible = false;
                trigger OnAction()
                begin
                end;
            }
            action(ActEllipsisDisabled)
            {
                ApplicationArea = All;
                Caption = 'Disabled';
                Ellipsis = true;
                Enabled = false;
                trigger OnAction()
                begin
                end;
            }
        }
    }
}

codeunit 71632 "LT P119 Actions Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ActionState()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Actions Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('plain-visible', Format(TP.ActPlain.Visible()));
        Observer.Observe('plain-enabled', Format(TP.ActPlain.Enabled()));
        Observer.Observe('ellipsis-visible', Format(TP.ActEllipsis.Visible()));
        Observer.Observe('ellipsis-enabled', Format(TP.ActEllipsis.Enabled()));
        Observer.Observe('ellipsisoff-visible', Format(TP.ActEllipsisOff.Visible()));
        Observer.Observe('hidden-visible', Format(TP.ActEllipsisHidden.Visible()));
        Observer.Observe('hidden-enabled', Format(TP.ActEllipsisHidden.Enabled()));
        Observer.Observe('disabled-visible', Format(TP.ActEllipsisDisabled.Visible()));
        Observer.Observe('disabled-enabled', Format(TP.ActEllipsisDisabled.Enabled()));
        TP.Close();
        Observer.Expect('plain-visible', 'Yes');
        Observer.Expect('plain-enabled', 'Yes');
        Observer.Expect('ellipsis-visible', 'Yes');
        Observer.Expect('ellipsis-enabled', 'Yes');
        Observer.Expect('ellipsisoff-visible', 'Yes');
        Observer.Expect('hidden-visible', 'No');
        Observer.Expect('hidden-enabled', 'Yes');
        Observer.Expect('disabled-visible', 'Yes');
        Observer.Expect('disabled-enabled', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P119_ActionInvoke()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Actions Card";
    begin
        Seed();
        TP.OpenEdit();
        TP.ActEllipsis.Invoke();
        Observer.Observe('ellipsis-invoked', 'no error');
        TP.ActEllipsisDisabled.Invoke();
        Observer.Observe('disabled-invoke', 'no error');
        TP.Close();
        Observer.Expect('ellipsis-invoked', 'no error');
        Observer.Expect('disabled-invoke', 'no error');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'First';
        Row.Insert();
    end;
}
