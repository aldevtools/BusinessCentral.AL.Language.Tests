// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: repeater property Visible = false: whether TestPage still reaches the fields of the repeater and what Visible reports for them.

page 71640 "LT P119 RepVis List"
{
    PageType = List;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                Visible = false;
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
            group(Other)
            {
                field(LevelF; Rec.Level) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 71641 "LT P119 RepVis Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_HiddenRepeaterFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 RepVis List";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'One';
        Row.Note := 'n1';
        Row.Level := 4;
        Row.Insert();
        TP.OpenView();
        Observer.Observe('first', Format(TP.First()));
        asserterror Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.ObserveError('af53');
        asserterror Observer.Observe('note-visible', Format(TP.NoteF.Visible()));
        Observer.ObserveError('af55');
        Observer.Observe('level-visible', Format(TP.LevelF.Visible()));
        asserterror Observer.Observe('name-value', TP.NameF.Value());
        Observer.ObserveError('af58');
        Observer.Observe('level-value', TP.LevelF.Value());
        TP.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('af53|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af53|code', 'TestFieldNotFound');
        Observer.Expect('af55|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af55|code', 'TestFieldNotFound');
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('af58|text', 'The field with ID = n is not found on the page.');
        Observer.Expect('af58|code', 'TestFieldNotFound');
        Observer.Expect('level-value', '4');
        Observer.Verify();
    end;
}
