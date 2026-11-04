// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects in BcImplicitAreaObjects.al; writer QV: List page 87466, page extensions 87467 to 87469 (AL Runner issue 5674)
// Corpus issue 659 item 3 (from al-runtime-rs #252): a page extension may add to area(FactBoxes) when the base card declares only
// area(Content), and the test page opens. These tests read what the added parts show. An area name that does not exist is
// must-not-compile case 1270.

codeunit 80972 "BC Implicit Areas"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Setup()
    var
        Row: Record "BC Implicit Row";
    begin
        Row.DeleteAll();
        Row.Number := 3;
        Row.Insert();
        Row.Number := 5;
        Row.Insert();
        Row.Number := 7;
        Row.Insert();
    end;

    [Test]
    procedure FactBoxes_NotDeclared_OpenView_Closes()
    var
        Card: TestPage "BC Implicit FB Card";
    begin
        // The repro of al-runtime-rs #252.
        Setup();
        Card.OpenView();
        Card.Close();
    end;

    [Test]
    procedure FactBoxes_NotDeclared_PartsShowLinkedRow()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "BC Implicit FB Card";
    begin
        Setup();
        Card.OpenView();
        Card.GoToKey(5);
        Observer.Observe('card number', Card.Number.Value());
        Observer.Observe('part number', Card.BCPart.PartNumber.Value());
        Observer.Observe('part visible', Format(Card.BCPart.Visible()));
        Observer.Observe('part editable', Format(Card.BCPart.Editable()));
        Observer.Observe('part next', Format(Card.BCPart.Next()));
        Observer.Observe('after part number', Card.BCPartAfter.PartNumber.Value());
        Observer.Observe('after part visible', Format(Card.BCPartAfter.Visible()));
        Card.GoToKey(7);
        Observer.Observe('card number 7', Card.Number.Value());
        Observer.Observe('part number 7', Card.BCPart.PartNumber.Value());
        Card.Close();
        Observer.Expect('card number', '5');
        Observer.Expect('part number', '5');
        Observer.Expect('part visible', 'Yes');
        Observer.Expect('part editable', 'No');
        Observer.Expect('part next', 'No');
        Observer.Expect('after part number', '5');
        Observer.Expect('after part visible', 'Yes');
        Observer.Expect('card number 7', '7');
        Observer.Expect('part number 7', '7');
        Observer.Verify();
    end;

    [Test]
    procedure NoLayout_ExtensionAddsContentAndFactBox()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "BC No Layout Card";
    begin
        Setup();
        Card.OpenView();
        Card.GoToKey(3);
        Observer.Observe('number', Card.BCNumber.Value());
        Observer.Observe('number visible', Format(Card.BCNumber.Visible()));
        Observer.Observe('part number', Card.BCNoLayoutPart.PartNumber.Value());
        Observer.Observe('part visible', Format(Card.BCNoLayoutPart.Visible()));
        Card.Close();
        Observer.Expect('number', '3');
        Observer.Expect('number visible', 'Yes');
        Observer.Expect('part number', '3');
        Observer.Expect('part visible', 'Yes');
        Observer.Verify();
    end;

    // Writer QV (AL Runner issue 5674): a List page that declares no area(FactBoxes); extensions add a system part (addfirst) and a
    // part with a SubPageLink (addlast).
    [Test]
    procedure QV_List_FactBoxes_NotDeclared_OpenView_Closes()
    var
        List: TestPage "LT QV Implicit FB List";
    begin
        Setup();
        List.OpenView();
        List.Close();
    end;

    [Test]
    procedure QV_List_FactBoxes_NotDeclared_PartFollowsRow()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT QV Implicit FB List";
    begin
        Setup();
        List.OpenView();
        Observer.Observe('open number', List.Number.Value());
        Observer.Observe('open part number', List.QVPart.PartNumber.Value());
        Observer.Observe('part visible', Format(List.QVPart.Visible()));
        Observer.Observe('part editable', Format(List.QVPart.Editable()));
        Observer.Observe('part next', Format(List.QVPart.Next()));
        Observer.Observe('gotokey 5', Format(List.GoToKey(5)) + '|' + List.Number.Value() + '|' + List.QVPart.PartNumber.Value());
        Observer.Observe('next', Format(List.Next()) + '|' + List.Number.Value() + '|' + List.QVPart.PartNumber.Value());
        List.Close();
        Observer.Expect('open number', '3');
        Observer.Expect('open part number', '3');
        Observer.Expect('part visible', 'Yes');
        Observer.Expect('part editable', 'No');
        Observer.Expect('part next', 'No');
        Observer.Expect('gotokey 5', 'Yes|5|5');
        Observer.Expect('next', 'Yes|7|7');
        Observer.Verify();
    end;

    // The reporter's case: Base Application's List page 7500 "Item Attributes" with a system part added by addfirst(FactBoxes).
    [Test]
    procedure QV_ItemAttributes_FactBoxes_OpenView_Closes()
    var
        ItemAttributes: TestPage "Item Attributes";
    begin
        ItemAttributes.OpenView();
        ItemAttributes.Close();
    end;
}
