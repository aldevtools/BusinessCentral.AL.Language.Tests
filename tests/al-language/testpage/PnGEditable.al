// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/currpage/currpage-editable-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Card (70134), LT PnG List (70135), LT PnG Item (70130)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row 84 (TestPage): CurrPage.Editable(false) in a trigger other than OnOpenPage changes no control's Editable() beyond the control's own expression; Editable(true) never widens
// Facts: TestPage.Editable() and control Editable() before and after an action that calls CurrPage.Editable(false) / (true), in edit and view mode, and whether a field can still be set
// BC versions: 29 (27 and 28 by CI)

codeunit 70185 "LT PnG Editable"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'E1';
        Item.Name := 'Editable one';
        Item.Qty := 1;
        Item.Insert();
    end;

    [Test]
    procedure CardEditableFalseFromAnAction()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Card: TestPage "LT PnG Card";
    begin
        Seed();
        Card.OpenEdit();
        Observer.Observe('page-before', Format(Card.Editable()));
        Observer.Observe('name-before', Format(Card.NameCtl.Editable()));
        Observer.Observe('no-before', Format(Card.NoCtl.Editable()));
        Card.SetEditableFalse.Invoke();
        Observer.Observe('page-after', Format(Card.Editable()));
        Observer.Observe('name-after', Format(Card.NameCtl.Editable()));
        Observer.Observe('no-after', Format(Card.NoCtl.Editable()));
        Observer.Observe('qty-after', Format(Card.QtyCtl.Editable()));
        Card.NameCtl.SetValue('Set after editable false');
        Observer.Observe('name-value-after-setvalue', Card.NameCtl.Value());
        Card.Close();
        Item.Get('E1');
        Observer.Observe('stored-name', Item.Name);
        Observer.Expect('page-before', 'Yes');
        Observer.Expect('name-before', 'Yes');
        Observer.Expect('no-before', 'Yes');
        Observer.Expect('page-after', 'Yes');
        Observer.Expect('name-after', 'Yes');
        Observer.Expect('no-after', 'Yes');
        Observer.Expect('qty-after', 'Yes');
        Observer.Expect('name-value-after-setvalue', 'Set after editable false');
        Observer.Expect('stored-name', 'Set after editable false');
        Observer.Verify();
    end;

    [Test]
    procedure CardEditableTrueDoesNotWiden()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
    begin
        Seed();
        Card.OpenView();
        Observer.Observe('page-before', Format(Card.Editable()));
        Observer.Observe('name-before', Format(Card.NameCtl.Editable()));
        Card.SetEditableTrue.Invoke();
        Observer.Observe('page-after', Format(Card.Editable()));
        Observer.Observe('name-after', Format(Card.NameCtl.Editable()));
        Card.NameCtl.SetValue('widened?');
        Observer.Observe('setvalue-after-true', 'no error');
        Card.Close();
        Observer.Expect('page-before', 'No');
        Observer.Expect('name-before', 'No');
        Observer.Expect('page-after', 'No');
        Observer.Expect('name-after', 'No');
        Observer.Expect('setvalue-after-true', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure CardEditableFalseThenTrue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT PnG Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.SetEditableFalse.Invoke();
        Card.SetEditableTrue.Invoke();
        Observer.Observe('page-after', Format(Card.Editable()));
        Observer.Observe('name-after', Format(Card.NameCtl.Editable()));
        Card.Close();
        Observer.Expect('page-after', 'Yes');
        Observer.Expect('name-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ListEditableFalseFromAnAction()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenEdit();
        Observer.Observe('page-before', Format(List.Editable()));
        Observer.Observe('name-before', Format(List.NameCtl.Editable()));
        List.SetEditableFalse.Invoke();
        Observer.Observe('page-after', Format(List.Editable()));
        Observer.Observe('name-after', Format(List.NameCtl.Editable()));
        Observer.Observe('action-enabled-after', Format(List.SetEditableTrue.Enabled()));
        List.SetEditableTrue.Invoke();
        Observer.Observe('page-restored', Format(List.Editable()));
        Observer.Observe('name-restored', Format(List.NameCtl.Editable()));
        List.Close();
        Observer.Expect('page-before', 'Yes');
        Observer.Expect('name-before', 'Yes');
        Observer.Expect('page-after', 'Yes');
        Observer.Expect('name-after', 'Yes');
        Observer.Expect('action-enabled-after', 'Yes');
        Observer.Expect('page-restored', 'Yes');
        Observer.Expect('name-restored', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure ListViewModeEditableTrue()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PnG List";
    begin
        Seed();
        List.OpenView();
        Observer.Observe('page-before', Format(List.Editable()));
        List.SetEditableTrue.Invoke();
        Observer.Observe('page-after', Format(List.Editable()));
        Observer.Observe('name-after', Format(List.NameCtl.Editable()));
        List.Close();
        Observer.Expect('page-before', 'No');
        Observer.Expect('page-after', 'No');
        Observer.Expect('name-after', 'No');
        Observer.Verify();
    end;
}
