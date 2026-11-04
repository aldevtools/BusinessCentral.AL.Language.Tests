// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: fixed control with ShowCaption = false inside a ListPlus page. A fixed control is no TestPage member; the fields inside it and in the repeater are observed.

page 71652 "LT P119 Fixed ListPlus"
{
    PageType = ListPlus;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NameF; Rec.Name) { ApplicationArea = All; }
            }
            fixed(FixedBox)
            {
                ShowCaption = false;
                group(Totals)
                {
                    Caption = 'Totals';
                    field(LevelF; Rec.Level) { ApplicationArea = All; }
                }
            }
        }
    }
}

codeunit 71653 "LT P119 Fixed Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_FixedFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Fixed ListPlus";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Fixed';
        Row.Level := 7;
        Row.Insert();
        TP.OpenView();
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('name-value', TP.NameF.Value());
        Observer.Observe('level-visible', Format(TP.LevelF.Visible()));
        Observer.Observe('level-value', TP.LevelF.Value());
        Observer.Observe('level-caption', TP.LevelF.Caption());
        TP.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('name-value', 'Fixed');
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('level-value', '7');
        Observer.Expect('level-caption', 'Level');
        Observer.Verify();
    end;
}
