// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: grid (GridLayout, ShowCaption) and field ColumnSpan / RowSpan in a card page. A grid is no TestPage member (TestPageLabelControlContracts.al), so the fields inside it are observed (Visible, Value, Caption).

page 71648 "LT P119 Grid Card"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            grid(MainGrid)
            {
                GridLayout = Rows;
                ShowCaption = false;
                group(RowOne)
                {
                    ShowCaption = false;
                    field(NameF; Rec.Name)
                    {
                        ApplicationArea = All;
                        ColumnSpan = 2;
                        RowSpan = 1;
                    }
                    field(NoteF; Rec.Note) { ApplicationArea = All; }
                }
                group(RowTwo)
                {
                    ShowCaption = false;
                    field(LevelF; Rec.Level)
                    {
                        ApplicationArea = All;
                        ColumnSpan = 3;
                        RowSpan = 2;
                    }
                }
            }
            grid(ColGrid)
            {
                GridLayout = Columns;
                ShowCaption = true;
                Caption = 'Col Grid';
                group(ColOne)
                {
                    field(PhoneF; Rec.Phone) { ApplicationArea = All; }
                }
            }
        }
    }
}

codeunit 71649 "LT P119 Grid Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_GridFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Grid Card";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Grid';
        Row.Note := 'note';
        Row.Level := 3;
        Row.Phone := '555';
        Row.Insert();
        TP.OpenEdit();
        Observer.Observe('name-visible', Format(TP.NameF.Visible()));
        Observer.Observe('name-value', TP.NameF.Value());
        Observer.Observe('name-caption', TP.NameF.Caption());
        Observer.Observe('note-visible', Format(TP.NoteF.Visible()));
        Observer.Observe('note-value', TP.NoteF.Value());
        Observer.Observe('level-value', TP.LevelF.Value());
        Observer.Observe('level-editable', Format(TP.LevelF.Editable()));
        Observer.Observe('phone-visible', Format(TP.PhoneF.Visible()));
        Observer.Observe('phone-value', TP.PhoneF.Value());
        TP.LevelF.SetValue(8);
        Observer.Observe('level-after', TP.LevelF.Value());
        TP.Close();
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-value', 'Grid');
        Observer.Expect('name-caption', 'Name');
        Observer.Expect('note-visible', 'Yes');
        Observer.Expect('note-value', 'note');
        Observer.Expect('level-value', '3');
        Observer.Expect('level-editable', 'Yes');
        Observer.Expect('phone-visible', 'Yes');
        Observer.Expect('phone-value', '555');
        Observer.Expect('level-after', '8');
        Observer.Verify();
    end;
}
