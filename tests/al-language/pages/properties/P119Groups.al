// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: group properties ShowCaption, ShowAs (SplitButton in an action group) and Visible. A group is no TestPage member (TestPageLabelControlContracts.al), so what is observed is
// what the controls inside the groups report (field Visible and Value, action Visible and Enabled).

page 71634 "LT P119 Groups Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(CaptionShown)
            {
                Caption = 'Shown Group';
                ShowCaption = true;
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            group(CaptionHidden)
            {
                Caption = 'Hidden Caption Group';
                ShowCaption = false;
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            group(InvisibleGroup)
            {
                Caption = 'Invisible Group';
                Visible = false;
                field(PhoneF; Rec.Phone) { ApplicationArea = All; }
            }
            group(CardGroup)
            {
                Caption = 'Card Group';
                field(MailF; Rec.Mail) { ApplicationArea = All; }
            }
        }
    }

    actions
    {
        area(Processing)
        {
            group(SplitGroup)
            {
                Caption = 'Split Group';
                action(SplitMain)
                {
                    ApplicationArea = All;
                    Caption = 'Split Main';
                    trigger OnAction()
                    begin
                    end;
                }
                action(SplitSecond)
                {
                    ApplicationArea = All;
                    Caption = 'Split Second';
                    trigger OnAction()
                    begin
                    end;
                }
                action(SplitHidden)
                {
                    ApplicationArea = All;
                    Caption = 'Split Hidden';
                    Visible = false;
                    trigger OnAction()
                    begin
                    end;
                }
            }
        }
    }
}

codeunit 71689 "LT P119 Groups Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_GroupFieldsInside()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Groups Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.Observe('note-visible', Format(TP.NoteF.Visible()));
        asserterror Observer.Observe('phone-visible', Format(TP.PhoneF.Visible()));
        Observer.ObserveError('af97');
        Observer.Observe('mail-visible', Format(TP.MailF.Visible()));
        Observer.Observe('note-value', TP.NoteF.Value());
        asserterror Observer.Observe('phone-value', TP.PhoneF.Value());
        Observer.ObserveError('af101');
        TP.Close();
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('note-visible', 'Yes');
        Observer.Expect('af97|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af97|code', 'TestFieldNotFound');
        Observer.Expect('mail-visible', 'Yes');
        Observer.Expect('note-value', 'N1');
        Observer.Expect('af101|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af101|code', 'TestFieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P119_SplitButtonActions()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Groups Card";
    begin
        Seed();
        TP.OpenEdit();
        Observer.Observe('main-visible', Format(TP.SplitMain.Visible()));
        Observer.Observe('main-enabled', Format(TP.SplitMain.Enabled()));
        Observer.Observe('second-visible', Format(TP.SplitSecond.Visible()));
        Observer.Observe('hidden-visible', Format(TP.SplitHidden.Visible()));
        TP.SplitMain.Invoke();
        TP.SplitSecond.Invoke();
        Observer.Observe('invoked', 'no error');
        TP.Close();
        Observer.Expect('main-visible', 'Yes');
        Observer.Expect('main-enabled', 'Yes');
        Observer.Expect('second-visible', 'Yes');
        Observer.Expect('hidden-visible', 'No');
        Observer.Expect('invoked', 'no error');
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
        Row.Phone := '555';
        Row.Mail := 'a@b.example';
        Row.Insert();
    end;
}
