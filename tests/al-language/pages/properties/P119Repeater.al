// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: repeater properties ShowCaption, IndentationColumn, IndentationControls and FreezeColumn: what a TestPage list exposes (rows, values, field Visible and Caption).

page 71638 "LT P119 Repeater List"
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
                ShowCaption = false;
                IndentationColumn = Rec.Level;
                IndentationControls = NameF;
                FreezeColumn = NameF;
                field(NameF; Rec.Name) { ApplicationArea = All; }
                field(LevelF; Rec.Level) { ApplicationArea = All; }
                field(NoteF; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}

codeunit 71639 "LT P119 Repeater Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_RowsAndValues()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Repeater List";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('first', Format(TP.First()));
        Observer.Observe('r1-name', TP.NameF.Value());
        Observer.Observe('r1-level', TP.LevelF.Value());
        Observer.Observe('next-1', Format(TP.Next()));
        Observer.Observe('r2-name', TP.NameF.Value());
        Observer.Observe('r2-level', TP.LevelF.Value());
        Observer.Observe('next-2', Format(TP.Next()));
        Observer.Observe('r3-name', TP.NameF.Value());
        Observer.Observe('r3-level', TP.LevelF.Value());
        Observer.Observe('next-3', Format(TP.Next()));
        TP.Close();
        Observer.Expect('first', 'Yes');
        Observer.Expect('r1-name', 'Top');
        Observer.Expect('r1-level', '0');
        Observer.Expect('next-1', 'Yes');
        Observer.Expect('r2-name', 'Child');
        Observer.Expect('r2-level', '1');
        Observer.Expect('next-2', 'Yes');
        Observer.Expect('r3-name', 'Grandchild');
        Observer.Expect('r3-level', '2');
        Observer.Expect('next-3', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P119_FieldsOfRepeater()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Repeater List";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.Observe('name-editable', Format(TP.NameF.Editable()));
        Observer.Observe('level-visible', Format(TP.LevelF.Visible()));
        Observer.Observe('note-visible', Format(TP.NoteF.Visible()));
        TP.Close();
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-editable', 'No');
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('note-visible', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P119_FieldCaptions()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Repeater List";
    begin
        Seed();
        TP.OpenView();
        Observer.Observe('name-caption', TP.NameF.Caption());
        Observer.Observe('level-caption', TP.LevelF.Caption());
        Observer.Observe('note-caption', TP.NoteF.Caption());
        TP.Close();
        Observer.Expect('name-caption', 'Name');
        Observer.Expect('level-caption', 'Level');
        Observer.Expect('note-caption', 'Note');
        Observer.Verify();
    end;

    [Test]
    procedure P119_EditRowOfIndented()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Repeater List";
        Row: Record "LT P119 Row";
    begin
        Seed();
        TP.OpenEdit();
        TP.GoToKey(2);
        TP.NoteF.SetValue('changed');
        TP.Close();
        Row.Get(2);
        Observer.Observe('row2-note', Row.Note);
        Row.Get(1);
        Observer.Observe('row1-note', Row.Note);
        Observer.Expect('row2-note', 'changed');
        Observer.Expect('row1-note', '');
        Observer.Verify();
    end;

    local procedure Seed()
    var
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Top';
        Row.Level := 0;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'Child';
        Row.Level := 1;
        Row.Insert();
        Row.Id := 3;
        Row.Name := 'Grandchild';
        Row.Level := 2;
        Row.Insert();
    end;
}
