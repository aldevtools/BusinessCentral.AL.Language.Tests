// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70058
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Decimal arithmetic, 18 digits, rounding in operations, errors
// BC versions: 29 (27 and 28 by CI)

codeunit 70058 "LT ScT Dec Arith"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Decimal_Basic()
    var
        Observer: Codeunit "Probe Observer";
        A: Decimal;
        B: Decimal;
    begin
        A := 10.5;
        B := 3;
        Observer.Observe('add', Format(A + B));
        Observer.Observe('sub', Format(A - B));
        Observer.Observe('mul', Format(A * B));
        Observer.Observe('div', Format(A / B));
        Observer.Observe('div9', Format(A / B, 0, 9));
        Observer.Observe('div_int', Format(A div B));
        Observer.Observe('mod_int', Format(A mod B));
        Observer.Observe('neg', Format(-A));
        Observer.Observe('default', Format(Dflt()));
        Observer.Expect('add', '13.5');
        Observer.Expect('sub', '7.5');
        Observer.Expect('mul', '31.5');
        Observer.Expect('div', '3.5');
        Observer.Expect('div9', '3.5');
        Observer.Expect('div_int', '3');
        Observer.Expect('mod_int', '1.5');
        Observer.Expect('neg', '-10.5');
        Observer.Expect('default', '0');
        Observer.Verify();
    end;

    local procedure Dflt(): Decimal
    var
        D: Decimal;
    begin
        exit(D);
    end;

    [Test]
    procedure Decimal_DivByZero()
    var
        Observer: Codeunit "Probe Observer";
        A: Decimal;
        Z: Decimal;
        R: Decimal;
    begin
        A := 10;
        Z := 0;
        asserterror R := A / Z;
        Observer.ObserveError('slash');
        asserterror R := A div Z;
        Observer.ObserveError('div');
        asserterror R := A mod Z;
        Observer.ObserveError('mod');
        asserterror R := 0 / Z;
        Observer.ObserveError('zero_slash');
        Observer.Expect('slash|text', 'Attempted to divide by zero.');
        Observer.Expect('slash|code', 'AL:DivideByZero');
        Observer.Expect('div|text', 'Attempted to divide by zero.');
        Observer.Expect('div|code', 'AL:DivideByZero');
        Observer.Expect('mod|text', 'Attempted to divide by zero.');
        Observer.Expect('mod|code', 'AL:DivideByZero');
        Observer.Expect('zero_slash|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_slash|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Digits()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 0.123456789012345678;
        Observer.Observe('18frac', Format(D, 0, 9));
        D := 0.1234567890123456789;
        Observer.Observe('19frac', Format(D, 0, 9));
        D := 0.00000000000000000049;
        Observer.Observe('tiny_round_down', Format(D, 0, 9));
        D := 0.0000000000000000005;
        Observer.Observe('tiny_round_up', Format(D, 0, 9));
        asserterror Evaluate(D, '123456789012345678');
        Observer.ObserveError('af76');
        Observer.Observe('18int', Format(D, 0, 9));
        asserterror Evaluate(D, '1234567890123456789');
        Observer.ObserveError('af79');
        Observer.Observe('19int', Format(D, 0, 9));
        D := 12345678901234567890123.0;
        asserterror Observer.Observe('23int', Format(D, 0, 9));
        Observer.ObserveError('af83');
        D := 1.0 / 3.0;
        Observer.Observe('third', Format(D, 0, 9));
        D := 2.0 / 3.0;
        Observer.Observe('two_thirds', Format(D, 0, 9));
        D := 1;
        D := D / 3 * 3;
        Observer.Observe('third_times_3', Format(D, 0, 9));
        Observer.Expect('18frac', '0.123456789012345678');
        Observer.Expect('19frac', '0.123456789012345679');
        Observer.Expect('tiny_round_down', '0');
        Observer.Expect('tiny_round_up', '0.000000000000000001');
        Observer.Expect('af76|text', 'The value "123456789012345678" can''t be evaluated into type Decimal.');
        Observer.Expect('af76|code', 'Evaluate');
        Observer.Expect('18int', '0.000000000000000001');
        Observer.Expect('af79|text', 'The value "1234567890123456789" can''t be evaluated into type Decimal.');
        Observer.Expect('af79|code', 'Evaluate');
        Observer.Expect('19int', '0.000000000000000001');
        Observer.Expect('af83|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 12,345,678,901,234,567,900,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af83|code', 'OutsidePermittedRange');
        Observer.Expect('third', '0.333333333333333333');
        Observer.Expect('two_thirds', '0.666666666666666667');
        Observer.Expect('third_times_3', '0.999999999999999999');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_MixedArithmetic()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        I: Integer;
        B: BigInteger;
        R: Decimal;
    begin
        D := 2.5;
        I := 4;
        Evaluate(B, '5000000000');
        R := D * I;
        Observer.Observe('dec_int', Format(R));
        R := D + B;
        Observer.Observe('dec_big', Format(R));
        R := I / 3;
        Observer.Observe('int_div_int', Format(R, 0, 9));
        R := I / 2;
        Observer.Observe('int_div_int_exact', Format(R));
        R := I div 3;
        Observer.Observe('int_idiv', Format(R));
        R := B / I;
        Observer.Observe('big_div', Format(R));
        Observer.Observe('cmp_dec_int', Format(D < I));
        Observer.Observe('eq_dec_int', Format(4.0 = I));
        Observer.Observe('cmp_dec_big', Format(D < B));
        Observer.Expect('dec_int', '10');
        Observer.Expect('dec_big', '5,000,000,002.5');
        Observer.Expect('int_div_int', '1.33333333333333333');
        Observer.Expect('int_div_int_exact', '2');
        Observer.Expect('int_idiv', '1');
        Observer.Expect('big_div', '1,250,000,000');
        Observer.Expect('cmp_dec_int', 'Yes');
        Observer.Expect('eq_dec_int', 'Yes');
        Observer.Expect('cmp_dec_big', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_Compare()
    var
        Observer: Codeunit "Probe Observer";
        A: Decimal;
        B: Decimal;
    begin
        A := 0.1;
        B := 0.10;
        Observer.Observe('eq', Format(A = B));
        B := A * 3;
        Observer.Observe('three_tenths', Format(B = 0.3));
        B := 0.1 + 0.2;
        Observer.Observe('sum', Format(B = 0.3));
        Observer.Observe('lt', Format(-0.5 < 0));
        Observer.Observe('negzero', Format(-0.0 = 0));
        Observer.Expect('eq', 'Yes');
        Observer.Expect('three_tenths', 'Yes');
        Observer.Expect('sum', 'Yes');
        Observer.Expect('lt', 'Yes');
        Observer.Expect('negzero', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Decimal_DivModTruncation()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 7.9;
        Observer.Observe('div2', Format(D div 2));
        Observer.Observe('mod2', Format(D mod 2));
        D := -7.9;
        Observer.Observe('negdiv2', Format(D div 2));
        Observer.Observe('negmod2', Format(D mod 2));
        D := 7;
        Observer.Observe('div_frac', Format(D div 0.5));
        Observer.Observe('mod_frac', Format(D mod 0.5));
        Observer.Observe('mod_frac2', Format(D mod 2.5));
        Observer.Expect('div2', '3');
        Observer.Expect('mod2', '1.9');
        Observer.Expect('negdiv2', '-3');
        Observer.Expect('negmod2', '-1.9');
        Observer.Expect('div_frac', '14');
        Observer.Expect('mod_frac', '0');
        Observer.Expect('mod_frac2', '2');
        Observer.Verify();
    end;
}
