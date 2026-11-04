// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: TPD Dec Row (69931), TPD Dec Card (69931), Assert (60021)
// BC versions: 27.0+
//
// CLAIM UNDER TEST: AssertEquals(<Decimal>) on a TestPage field holding a number of a thousand or
// more passes when the record holds that number. The control SHOWS such a value with thousands
// separators ('1,234,567.89'); NavTestField.ALAssertEquals converts the expected Decimal through
// the field's own ValueToString and compares it ORDINALLY with the control's text, so the two have
// to be spelled the same way or no Decimal of four digits or more could ever be asserted.
//
// WHY IT IS HERE: Microsoft's Tests-SMB `OrderDiscountTypePercentageIsSetWhenInvoiceIsOpened`
// (codeunit 138006) asserts a random discount amount through AssertEquals and, on AL Runner,
// fails for any amount from 1,000 up: Expected = '4175412.34', Actual = '4,175,412.34'. Whether
// that is AL Runner's formatting of the expected side or what BC does is the question
// (AL Runner issue https://github.com/StefanMaron/BusinessCentral.AL.Runner/issues/4867 notes it).
//
// Every test below asserts under 1,000 as well as over, so a rule that is right for one spelling
// only cannot pass.
//
// OVERLAP WITH codeunit 69932 (TPF Tests): that suite already pins the control text of a 2:2
// decimal (Value_Decimal_TwoPlaces and its siblings), typed AssertEquals of -1234567.89 and 1234567, the
// string forms, and the page-variable-bound decimal. What it has no counterpart for, and what is
// asserted here: a typed AssertEquals of 1234567.89, 1000 and 999.5 on a RECORD-bound 2:2 control,
// and a typed wrong value of a thousand or more still failing.

codeunit 69931 "TPD Dec Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure OpenOn(Amount: Decimal; var Card: TestPage "TPD Dec Card")
    var
        Row: Record "TPD Dec Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.PK := 'R1';
        Row.Amount := Amount;
        Row.Insert();
        Card.OpenEdit();
        Card.GoToKey('R1');
    end;

    [Test]
    procedure TestPageField_AssertEquals_DecimalOfSevenDigits_Passes()
    var
        Card: TestPage "TPD Dec Card";
    begin
        OpenOn(1234567.89, Card);
        Card.Amount.AssertEquals(1234567.89);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_DecimalOfFourDigits_Passes()
    var
        Card: TestPage "TPD Dec Card";
    begin
        OpenOn(1000, Card);
        Card.Amount.AssertEquals(1000);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_DecimalUnderOneThousand_Passes()
    var
        Card: TestPage "TPD Dec Card";
    begin
        OpenOn(999.5, Card);
        Card.Amount.AssertEquals(999.5);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_WrongDecimalOverOneThousand_Fails()
    var
        Card: TestPage "TPD Dec Card";
    begin
        OpenOn(1234567.89, Card);
        asserterror Card.Amount.AssertEquals(1234567.88);
        Assert.ExpectedError('AssertEquals for Field: Amount Expected = ');
        Card.Close();
    end;
}
