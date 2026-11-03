// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: cuegroup ShowCaption on a CardPart hosted in a card page: what TestPart exposes for the cue fields (Visible, Caption, Value, SetValue).

page 71654 "LT P119 Cue Part"
{
    PageType = CardPart;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            cuegroup(CuesNoCaption)
            {
                Caption = 'Cues No Caption';
                ShowCaption = false;
                field(LevelCue; Rec.Level)
                {
                    ApplicationArea = All;
                    Caption = 'Level Cue';
                }
            }
            cuegroup(CuesCaption)
            {
                Caption = 'Cues With Caption';
                ShowCaption = true;
                field(IdCue; Rec.Id)
                {
                    ApplicationArea = All;
                    Caption = 'Id Cue';
                }
            }
        }
    }
}

page 71655 "LT P119 Cue Host"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            field(NameF; Rec.Name) { ApplicationArea = All; }
            part(CuePart; "LT P119 Cue Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

codeunit 71656 "LT P119 Cue Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_CueFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 Cue Host";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 5;
        Row.Name := 'Cue';
        Row.Level := 9;
        Row.Insert();
        TP.OpenView();
        Observer.Observe('level-visible', Format(TP.CuePart.LevelCue.Visible()));
        Observer.Observe('level-caption', TP.CuePart.LevelCue.Caption());
        Observer.Observe('level-value', TP.CuePart.LevelCue.Value());
        Observer.Observe('id-visible', Format(TP.CuePart.IdCue.Visible()));
        Observer.Observe('id-caption', TP.CuePart.IdCue.Caption());
        Observer.Observe('id-value', TP.CuePart.IdCue.Value());
        TP.Close();
        Observer.Expect('level-visible', 'Yes');
        Observer.Expect('level-caption', 'Level Cue');
        Observer.Expect('level-value', '9');
        Observer.Expect('id-visible', 'Yes');
        Observer.Expect('id-caption', 'Id Cue');
        Observer.Expect('id-value', '5');
        Observer.Verify();
    end;
}
