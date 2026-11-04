// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70057
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: BigInteger arithmetic, overflow, mixed with Integer
// BC versions: 29 (27 and 28 by CI)

codeunit 70057 "LT ScT BigInt Arith"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BigInteger_Basic()
    var
        Observer: Codeunit "Probe Observer";
        A: BigInteger;
        B: BigInteger;
    begin
        Evaluate(A, '5000000000');
        B := 3;
        Observer.Observe('add', Format(A + B));
        Observer.Observe('sub', Format(A - B));
        Observer.Observe('mul', Format(A * B));
        Observer.Observe('div', Format(A div B));
        Observer.Observe('mod', Format(A mod B));
        Observer.Observe('slash', Format(A / B));
        Observer.Observe('neg_div', Format((-A) div B));
        Observer.Observe('neg_mod', Format((-A) mod B));
        Observer.Observe('default', Format(Dflt()));
        Observer.Expect('add', '5000000003');
        Observer.Expect('sub', '4999999997');
        Observer.Expect('mul', '15000000000');
        Observer.Expect('div', '1666666666');
        Observer.Expect('mod', '2');
        Observer.Expect('slash', '1,666,666,666.66666667');
        Observer.Expect('neg_div', '-1666666666');
        Observer.Expect('neg_mod', '-2');
        Observer.Expect('default', '0');
        Observer.Verify();
    end;

    local procedure Dflt(): BigInteger
    var
        B: BigInteger;
    begin
        exit(B);
    end;

    [Test]
    procedure BigInteger_Overflow()
    var
        Observer: Codeunit "Probe Observer";
        Mx: BigInteger;
        Mn: BigInteger;
        One: BigInteger;
        R: BigInteger;
    begin
        Evaluate(Mx, '9223372036854775807');
        Evaluate(Mn, '-9223372036854775808');
        One := 1;
        asserterror R := Mx + One;
        Observer.ObserveError('max_plus');
        asserterror R := Mn - One;
        Observer.ObserveError('min_minus');
        asserterror R := Mx * 2;
        Observer.ObserveError('max_times');
        asserterror R := -Mn;
        Observer.ObserveError('neg_min');
        asserterror R := Mn div -1;
        Observer.ObserveError('min_div_neg');
        asserterror R := Abs(Mn);
        Observer.ObserveError('abs_min');
        R := Mx - One;
        Observer.Observe('max_minus', Format(R));
        Observer.Expect('max_plus|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('max_plus|code', 'AL:Overflow');
        Observer.Expect('min_minus|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_minus|code', 'AL:Overflow');
        Observer.Expect('max_times|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('max_times|code', 'AL:Overflow');
        Observer.Expect('neg_min|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('neg_min|code', 'AL:Overflow');
        Observer.Expect('min_div_neg|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_div_neg|code', 'AL:Overflow');
        Observer.Expect('abs_min|text', 'Negating the minimum value of a twos complement number is invalid.');
        Observer.Expect('abs_min|code', 'AL:Overflow');
        Observer.Expect('max_minus', '9223372036854775806');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_DivByZero()
    var
        Observer: Codeunit "Probe Observer";
        A: BigInteger;
        Z: BigInteger;
        R: BigInteger;
        D: Decimal;
    begin
        A := 10;
        Z := 0;
        asserterror R := A div Z;
        Observer.ObserveError('div');
        asserterror R := A mod Z;
        Observer.ObserveError('mod');
        asserterror D := A / Z;
        Observer.ObserveError('slash');
        Observer.Expect('div|text', 'Attempted to divide by zero.');
        Observer.Expect('div|code', 'AL:DivideByZero');
        Observer.Expect('mod|text', 'Attempted to divide by zero.');
        Observer.Expect('mod|code', 'AL:DivideByZero');
        Observer.Expect('slash|text', 'Attempted to divide by zero.');
        Observer.Expect('slash|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_MixedInteger()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
        I: Integer;
        R: BigInteger;
        RI: Integer;
    begin
        Evaluate(B, '3000000000');
        I := 2000000000;
        R := B + I;
        Observer.Observe('big_plus_int', Format(R));
        asserterror R := I + I;
        Observer.ObserveError('af103');
        Observer.Observe('int_plus_int_in_big', Format(R));
        R := I;
        Observer.Observe('int_to_big', Format(R));
        RI := 5;
        asserterror R := RI * I;
        Observer.ObserveError('af109');
        Observer.Observe('int_times_int_big', Format(R));
        asserterror RI := B;
        Observer.ObserveError('big_to_int');
        B := 123;
        RI := B;
        Observer.Observe('small_big_to_int', Format(RI));
        Evaluate(B, '-3000000000');
        asserterror RI := B;
        Observer.ObserveError('neg_big_to_int');
        Observer.Observe('cmp', Format(B < I));
        Observer.Expect('big_plus_int', '5000000000');
        Observer.Expect('af103|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('af103|code', 'AL:Overflow');
        Observer.Expect('int_plus_int_in_big', '5000000000');
        Observer.Expect('int_to_big', '2000000000');
        Observer.Expect('af109|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('af109|code', 'AL:Overflow');
        Observer.Expect('int_times_int_big', '2000000000');
        Observer.Expect('big_to_int|text', 'Overflow under conversion of System.Int64 value 3000000000 to System.Int32.');
        Observer.Expect('big_to_int|code', 'ConversionCast');
        Observer.Expect('small_big_to_int', '123');
        Observer.Expect('neg_big_to_int|text', 'Overflow under conversion of System.Int64 value -3000000000 to System.Int32.');
        Observer.Expect('neg_big_to_int|code', 'ConversionCast');
        Observer.Expect('cmp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure BigInteger_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        B: BigInteger;
        D: Decimal;
    begin
        Evaluate(B, '5000000000');
        D := B;
        Observer.Observe('to_dec', Format(D));
        D := 0.5;
        Observer.Observe('big_plus_dec', Format(B + D));
        D := 5000000000.25;
        asserterror B := D;
        Observer.ObserveError('dec_to_big_frac');
        Evaluate(D, '5000000000');
        B := D;
        Observer.Observe('dec_to_big', Format(B));
        D := 99999999999999999999.0;
        asserterror B := D;
        Observer.ObserveError('dec_to_big_huge');
        Observer.Expect('to_dec', '5,000,000,000');
        Observer.Expect('big_plus_dec', '5,000,000,000.5');
        Observer.Expect('dec_to_big_frac|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 5000000000.25 to System.Int64.');
        Observer.Expect('dec_to_big_frac|code', 'ConversionCast');
        Observer.Expect('dec_to_big', '5000000000');
        Observer.Expect('dec_to_big_huge|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 100000000000000000000 to System.Int64.');
        Observer.Expect('dec_to_big_huge|code', 'ConversionCast');
        Observer.Verify();
    end;
}
