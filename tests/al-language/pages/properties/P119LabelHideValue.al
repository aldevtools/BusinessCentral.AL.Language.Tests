// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: HideValue on a label (declared; label members are observed) and on a field bound to a record field.

page 71662 "LT P119 HideValue Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            label(LabelHide)
            {
                ApplicationArea = All;
                Caption = 'Hide value label';
                HideValue = true;
            }
            field(NameF; Rec.Name)
            {
                ApplicationArea = All;
                HideValue = HideName;
            }
            field(LevelF; Rec.Level)
            {
                ApplicationArea = All;
                HideValue = true;
            }
        }
    }

    var
        HideName: Boolean;

    trigger OnAfterGetRecord()
    begin
        HideName := Rec.Id = 1;
    end;
}

codeunit 71663 "LT P119 HideValue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_HideValue()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 HideValue Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Shown?';
        Row.Level := 4;
        Row.Insert();
        TP.OpenView();
        Observer.Observe('label-visible', Format(TP.LabelHide.Visible()));
        Observer.Observe('label-value', TP.LabelHide.Value());
        Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.Observe('name-value', TP.NameF.Value());
        Observer.Observe('level-visible', Format(TP.LevelF.Visible()));
        Observer.Observe('level-value', TP.LevelF.Value());
        TP.Close();
        Observer.Expect('label-visible', 'Yes');
        Observer.Expect('label-value', 'Hide value label');
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-value', '');
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('level-value', '');
        Observer.Verify();
    end;
}
