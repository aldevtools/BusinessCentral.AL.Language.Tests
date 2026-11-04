// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P115 Item (P115Fixtures.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

page 70299 "LT P115 Grid Label"
{
    PageType = Card;
    SourceTable = "LT P115 Item";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            label(RoLabel)
            {
                ApplicationArea = All;
                Caption = 'Read only label';
                Editable = false;
            }
            label(OnLabel)
            {
                ApplicationArea = All;
                Caption = 'Editable label';
                Editable = true;
            }
            field(AfterLabel; Rec.Name) { ApplicationArea = All; }
            grid(RoGrid)
            {
                Editable = false;
                GridLayout = Rows;
                group(Row1)
                {
                    field(GridF; Rec.Note) { ApplicationArea = All; }
                }
            }
            grid(OnGrid)
            {
                Editable = true;
                GridLayout = Rows;
                group(Row2)
                {
                    field(GridOn; Rec.Other) { ApplicationArea = All; }
                }
            }
        }
    }
}

codeunit 70298 "LT P115 Grid Label Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P115_GridAndLabel_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P115 Item";
        Card: TestPage "LT P115 Grid Label";
    begin
        Item.DeleteAll();
        Item."No." := 'X1';
        Item.Insert();
        Card.OpenEdit();
        Card.GoToKey('X1');
        Observer.Observe('after-label-editable', Format(Card.AfterLabel.Editable()));
        Observer.Observe('ro-grid-field-editable', Format(Card.GridF.Editable()));
        Observer.Observe('on-grid-field-editable', Format(Card.GridOn.Editable()));
        Card.GridF.SetValue('x');
        Observer.Observe('ro-grid-setvalue', 'no error');
        Card.GridOn.SetValue('y');
        Observer.Observe('on-grid-value', Card.GridOn.Value());
        Card.Close();
        Observer.Expect('after-label-editable', 'Yes');
        Observer.Expect('ro-grid-field-editable', 'No');
        Observer.Expect('on-grid-field-editable', 'Yes');
        Observer.Expect('ro-grid-setvalue', 'no error');
        Observer.Expect('on-grid-value', 'y');
        Observer.Verify();
    end;
}
