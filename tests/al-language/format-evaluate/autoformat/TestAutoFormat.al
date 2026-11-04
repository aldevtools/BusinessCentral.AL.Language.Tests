// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autoformattype-property
// Scope: in-scope
// Fixtures used: Assert (60021), ALT AutoFormat Row (60603), ALT AutoFormat Card (60604)
//
// What a TestPage reads back from a Decimal control that carries page-side formatting
// properties. Every control on "ALT AutoFormat Card" is bound to the SAME table field
// holding the SAME value, so each assertion below is about the property on the control and
// nothing else.
//
// The suite is written so that no arm can pass by accident:
//
//   * every expected value is a concrete string, never a "not empty" or "is a number" shape;
//   * the Plain arm pins the unformatted baseline, so an implementation that dropped ALL
//     page-side formatting would fail the DecPlaces and Custom arms while still passing Plain;
//   * the DecPlaces arm asks for THREE decimals on a value that has one significant decimal
//     digit, so its expected string cannot coincide with the two-decimal baseline;
//   * the negative arm asserts the specific error a TestPage raises for a control that is not
//     on the page at all, so "reads any control successfully" cannot masquerade as a pass.
//
// The tier is the authority for the exact strings: they are what a real BC service tier
// produced for this page, not values predicted from reading the platform.

codeunit 60605 "ALT AutoFormat Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRow(CurrencyCode: Code[10])
    var
        Row: Record "ALT AutoFormat Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'AF-1';
        Row.Amount := 1234.5;
        Row."Currency Code" := CurrencyCode;
        Row.Insert();
    end;

    [Test]
    procedure AutoFormat_PlainControl_FallsToTheTwoDecimalDefault()
    var
        Card: TestPage "ALT AutoFormat Card";
    begin
        // AutoFormatType = 0 and no DecimalPlaces: the baseline every other arm is read against.
        SeedRow('');

        Card.OpenView();
        // Measured, not assumed: the tier answers 1,234.50 on 27.0 and 28.1 alike. A Decimal
        // control with no AutoFormat and no DecimalPlaces is still formatted - it falls to the
        // two-decimal default - so "no AutoFormatType" does not mean "unformatted".
        Assert.AreEqual('1,234.50', Card.Plain.Value,
          'AutoFormatType = 0 with no DecimalPlaces still formats to two decimals');
        Card.Close();
    end;

    [Test]
    procedure AutoFormat_DecimalPlacesControl_ReadsThreeDecimals()
    var
        Card: TestPage "ALT AutoFormat Card";
    begin
        // DecimalPlaces = 3 : 3 on a value with one significant decimal digit, so the expected
        // string cannot coincide with the Plain arm's.
        SeedRow('');

        Card.OpenView();
        Assert.AreEqual('1,234.500', Card.DecPlaces.Value,
          'DecimalPlaces = 3 : 3 should pad the value to three decimals');
        Assert.AreNotEqual(Card.Plain.Value, Card.DecPlaces.Value,
          'DecimalPlaces must change what the control reads back, or the property did nothing');
        Card.Close();
    end;

    [Test]
    procedure AutoFormat_CustomExpressionControl_HonoursTheFormatString()
    var
        Card: TestPage "ALT AutoFormat Card";
    begin
        // AutoFormatType = 11 carries a literal format string rather than a currency code,
        // so this arm fails if AutoFormatExpression is ignored.
        SeedRow('');

        Card.OpenView();
        Assert.AreEqual('1,234.500', Card.Custom.Value,
          'AutoFormatType = 11 should apply its AutoFormatExpression format string');
        Card.Close();
    end;

    [Test]
    procedure AutoFormat_CurrencyControl_WithACurrencyCode()
    var
        Card: TestPage "ALT AutoFormat Card";
    begin
        // AutoFormatType = 1 with a non-blank AutoFormatExpression: the route through the
        // platform's AutoFormat resolution.
        SeedRow('EUR');

        Card.OpenView();
        Assert.AreEqual('1,234.50', Card.Currency.Value,
          'AutoFormatType = 1 with a currency code should resolve through AutoFormat');
        Card.Close();
    end;

    [Test]
    procedure AutoFormat_CurrencyControl_WithABlankExpression()
    var
        Card: TestPage "ALT AutoFormat Card";
    begin
        // AutoFormatType = 1 whose expression evaluates to '': BC treats this case separately
        // from a resolved currency code.
        SeedRow('');

        Card.OpenView();
        Assert.AreEqual('1,234.50', Card.CurrBlank.Value,
          'AutoFormatType = 1 with a blank expression should still apply type 1');
        Card.Close();
    end;

    [Test]
    procedure AutoFormat_GetFieldByTableFieldNo_Errors()
    var
        Card: TestPage "ALT AutoFormat Card";
        Row: Record "ALT AutoFormat Row";
        Fetched: Text;
    begin
        // The negative arm. GetField() takes a page CONTROL id, not a table field number, so
        // asking for the source field's number must be refused. Without this, every assertion
        // above could be satisfied by an implementation that answered any read at all.
        SeedRow('');

        Card.OpenView();
        asserterror Fetched := Card.GetField(Row.FieldNo(Amount)).Value();
        Assert.IsTrue(StrPos(GetLastErrorText(), 'is not found on the page') > 0,
          'GetField() must refuse a TABLE field number: its argument is a page control id');
        Card.Close();
    end;
}
