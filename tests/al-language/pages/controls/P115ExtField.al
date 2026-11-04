// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-editable-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P115 Item (P115Fixtures.al), LT P115 Width Card (P115Width.al)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

pageextension 70297 "LT P115 Width Ext" extends "LT P115 Width Card"
{
    layout
    {
        addlast(Content)
        {
            field(ExtRo; Rec.Qty)
            {
                ApplicationArea = All;
                Editable = false;
            }
            field(ExtOn; Rec.Grp)
            {
                ApplicationArea = All;
                Editable = ExtEdit;
            }
        }
    }

    var
        ExtEdit: Boolean;

    trigger OnAfterGetRecord()
    begin
        ExtEdit := Rec.Qty > 0;
    end;
}

codeunit 70296 "LT P115 Ext Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P115_ExtensionField_Editable()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT P115 Item";
        Grp: Record "LT P115 Grp";
        Card: TestPage "LT P115 Width Card";
    begin
        Item.DeleteAll();
        Grp.DeleteAll();
        Grp.Code := 'G1';
        Grp.Insert();
        Item."No." := 'E1';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'E2';
        Item.Qty := 0;
        Item.Insert();
        Card.OpenEdit();
        Card.GoToKey('E1');
        Observer.Observe('e1-ro-editable', Format(Card.ExtRo.Editable()));
        Observer.Observe('e1-on-editable', Format(Card.ExtOn.Editable()));
        Card.ExtOn.SetValue('G1');
        Observer.Observe('e1-on-value', Card.ExtOn.Value());
        Card.ExtRo.SetValue(5);
        Observer.Observe('e1-ro-setvalue', 'no error');
        Card.GoToKey('E2');
        Observer.Observe('e2-on-editable', Format(Card.ExtOn.Editable()));
        Card.ExtOn.SetValue('G1');
        Observer.Observe('e2-on-setvalue', 'no error');
        Card.Close();
        Observer.Expect('e1-ro-editable', 'No');
        Observer.Expect('e1-on-editable', 'Yes');
        Observer.Expect('e1-on-value', 'G1');
        Observer.Expect('e1-ro-setvalue', 'no error');
        Observer.Expect('e2-on-editable', 'No');
        Observer.Expect('e2-on-setvalue', 'no error');
        Observer.Verify();
    end;
}
