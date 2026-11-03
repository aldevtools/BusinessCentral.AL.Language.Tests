// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-properties
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table "LT P119 Row" (71625, P119Table.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 71657 "LT P119 ShowAs Part"
{
    PageType = CardPart;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(CardGroup)
            {
                Caption = 'Card Group';
                field(NameC; Rec.Name) { ApplicationArea = All; }
                field(NoteC; Rec.Note) { ApplicationArea = All; }
            }
        }
    }
}

page 71658 "LT P119 ShowAs Host"
{
    PageType = Card;
    SourceTable = "LT P119 Row";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            part(CardPart; "LT P119 ShowAs Part")
            {
                ApplicationArea = All;
                SubPageLink = Id = field(Id);
            }
        }
    }
}

codeunit 71659 "LT P119 ShowAs Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P119_ShowAsCardFields()
    var
        Observer: Codeunit "Probe Observer";
        TP: TestPage "LT P119 ShowAs Host";
        Row: Record "LT P119 Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'Card';
        Row.Note := 'note';
        Row.Insert();
        TP.OpenView();
        Observer.Observe('name-visible', Format(TP.CardPart.NameC.Visible()));
        Observer.Observe('name-value', TP.CardPart.NameC.Value());
        Observer.Observe('name-caption', TP.CardPart.NameC.Caption());
        Observer.Observe('note-value', TP.CardPart.NoteC.Value());
        Observer.Observe('name-editable', Format(TP.CardPart.NameC.Editable()));
        TP.Close();
        Observer.Expect('name-visible', 'Yes');
        Observer.Expect('name-value', 'Card');
        Observer.Expect('name-caption', 'Name');
        Observer.Expect('note-value', 'note');
        Observer.Expect('name-editable', 'No');
        Observer.Verify();
    end;
}
