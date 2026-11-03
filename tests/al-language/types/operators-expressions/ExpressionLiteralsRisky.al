// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); enum "LT Lit Enum" (72787, ExpressionLiterals.al); self-contained test codeunit 72794
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: a Decimal literal with 20 significant digits and a Char assigned from a character may be refused by the compiler; this file is separate so only it drops.
// Facts: the value and Format of a Decimal literal with 20 digits and of a Decimal literal with the most fractional digits.
codeunit 72794 "LT Literals Risky"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_Literal_DecimalTwentyDigits()
    var
        Observer: Codeunit "Probe Observer";
        Dec: Decimal;
    begin
        Dec := 123456789012345.12345;
        Observer.Observe('dec-20-digits', Format(Dec));
        Observer.Observe('dec-20-digits-xml', Format(Dec, 0, 9));
        Observer.Observe('dec-20-digits-plus-one', Format(Dec + 1, 0, 9));
        Observer.Observe('dec-20-digits-times-two', Format(Dec * 2, 0, 9));
        Dec := 12345678901234567890.0;
        asserterror Observer.Observe('dec-integer-part-20-xml', Format(Dec, 0, 9));
        Observer.ObserveError('af25');
        Dec := 0.12345678901234567890;
        Observer.Observe('dec-fraction-20-xml', Format(Dec, 0, 9));
        Dec := 1.00000000000000000001;
        Observer.Observe('dec-fraction-tail-xml', Format(Dec, 0, 9));
        Observer.Observe('dec-fraction-tail-eq-one', Format(Dec = 1));
        Observer.Expect('dec-20-digits', '123,456,789,012,345.123');
        Observer.Expect('dec-20-digits-xml', '123456789012345.123');
        Observer.Expect('dec-20-digits-plus-one', '123456789012346.123');
        Observer.Expect('dec-20-digits-times-two', '246913578024690.246');
        Observer.Expect('af25|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 12,345,678,901,234,567,900. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af25|code', 'OutsidePermittedRange');
        Observer.Expect('dec-fraction-20-xml', '0.123456789012345679');
        Observer.Expect('dec-fraction-tail-xml', '1');
        Observer.Expect('dec-fraction-tail-eq-one', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Literal_CharFromTextTimeMillisEnumNames()
    var
        Observer: Codeunit "Probe Observer";
        Ch: Char;
    begin
        Ch := 'B';
        Observer.Observe('char-from-literal', Format(Ch));
        Observer.Observe('char-from-literal-as-int', Format(Ch + 0));
        Observer.Observe('time-millis-eq', Format(235959.999T = 235959.999T));
        Observer.Observe('time-ms-xml', Format(120000.123T, 0, 9));
        Observer.Observe('enum-names-second', Enum::"LT Lit Enum".Names().Get(2));
        Observer.Observe('enum-names-count', Format(Enum::"LT Lit Enum".Names().Count()));
        Observer.Expect('char-from-literal', 'B');
        Observer.Expect('char-from-literal-as-int', '66');
        Observer.Expect('time-millis-eq', 'Yes');
        Observer.Expect('time-ms-xml', '12:00:00.123');
        Observer.Expect('enum-names-second', 'Fifth');
        Observer.Expect('enum-names-count', '3');
        Observer.Verify();
    end;
}
