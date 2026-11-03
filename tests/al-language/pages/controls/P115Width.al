// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-width-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P115 Item (P115Fixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 70219 "LT P115 Width Card"
{
    PageType = Card;
    SourceTable = "LT P115 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(Narrow; Rec.Name)
            {
                ApplicationArea = All;
                Width = 5;
            }
            field(Wide; Rec.Note)
            {
                ApplicationArea = All;
                Width = 60;
            }
            field(NoWidth; Rec.Other) { ApplicationArea = All; }
        }
    }
}

page 70220 "LT P115 Width List"
{
    PageType = List;
    SourceTable = "LT P115 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(NoR; Rec."No.")
                {
                    ApplicationArea = All;
                    Width = 8;
                }
                field(NameR; Rec.Name)
                {
                    ApplicationArea = All;
                    Width = 30;
                }
            }
        }
    }
}

codeunit 70221 "LT P115 Width"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT P115 Item";
    begin
        Item.DeleteAll();
        Item."No." := 'W1';
        Item.Name := 'A name longer than five characters';
        Item.Note := 'note';
        Item.Insert();
    end;

    [Test]
    procedure P115_Width_Card_ValuesNotTruncated()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P115 Width Card";
        Item: Record "LT P115 Item";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('W1');
        Observer.Observe('narrow-value', Card.Narrow.Value());
        Observer.Observe('wide-value', Card.Wide.Value());
        Observer.Observe('narrow-editable', Format(Card.Narrow.Editable()));
        Observer.Observe('narrow-visible', Format(Card.Narrow.Visible()));
        Card.Narrow.SetValue('Typed value far beyond width five');
        Observer.Observe('narrow-after-set', Card.Narrow.Value());
        Card.Close();
        Item.Get('W1');
        Observer.Observe('saved', Item.Name);
        Observer.Expect('narrow-value', 'A name longer than five characters');
        Observer.Expect('wide-value', 'note');
        Observer.Expect('narrow-editable', 'Yes');
        Observer.Expect('narrow-visible', 'Yes');
        Observer.Expect('narrow-after-set', 'Typed value far beyond width five');
        Observer.Expect('saved', 'Typed value far beyond width five');
        Observer.Verify();
    end;

    [Test]
    procedure P115_Width_List()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT P115 Width List";
    begin
        Seed();
        List.OpenView();
        List.GoToKey('W1');
        Observer.Observe('no-value', List.NoR.Value());
        Observer.Observe('name-value', List.NameR.Value());
        Observer.Observe('name-visible', Format(List.NameR.Visible()));
        List.Close();
        Observer.Expect('no-value', 'W1');
        Observer.Expect('name-value', 'A name longer than five characters');
        Observer.Expect('name-visible', 'Yes');
        Observer.Verify();
    end;
}
