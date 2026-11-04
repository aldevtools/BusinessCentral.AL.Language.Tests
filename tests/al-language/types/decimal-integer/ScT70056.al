// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 70056
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Integer arithmetic, overflow, div and mod, errors
// BC versions: 29 (27 and 28 by CI)

codeunit 70056 "LT ScT Int Arith"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Integer_Basic()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
    begin
        A := 17;
        B := 5;
        Observer.Observe('add', Format(A + B));
        Observer.Observe('sub', Format(A - B));
        Observer.Observe('mul', Format(A * B));
        Observer.Observe('div_slash', Format(A / B));
        Observer.Observe('div', Format(A div B));
        Observer.Observe('mod', Format(A mod B));
        Observer.Observe('neg_div', Format((-A) div B));
        Observer.Observe('neg_mod', Format((-A) mod B));
        Observer.Observe('div_neg', Format(A div -B));
        Observer.Observe('mod_neg', Format(A mod -B));
        Observer.Observe('neg_neg_div', Format((-A) div -B));
        Observer.Observe('neg_neg_mod', Format((-A) mod -B));
        Observer.Observe('unary', Format(-A));
        Observer.Observe('unary_plus', Format(+A));
        Observer.Observe('prec', Format(2 + 3 * 4));
        Observer.Observe('zero_div', Format(0 div B));
        Observer.Observe('zero_mod', Format(0 mod B));
        Observer.Expect('add', '22');
        Observer.Expect('sub', '12');
        Observer.Expect('mul', '85');
        Observer.Expect('div_slash', '3.4');
        Observer.Expect('div', '3');
        Observer.Expect('mod', '2');
        Observer.Expect('neg_div', '-3');
        Observer.Expect('neg_mod', '-2');
        Observer.Expect('div_neg', '-3');
        Observer.Expect('mod_neg', '2');
        Observer.Expect('neg_neg_div', '3');
        Observer.Expect('neg_neg_mod', '-2');
        Observer.Expect('unary', '-17');
        Observer.Expect('unary_plus', '17');
        Observer.Expect('prec', '14');
        Observer.Expect('zero_div', '0');
        Observer.Expect('zero_mod', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_DivByZero()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        Z: Integer;
        R: Integer;
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
        asserterror R := 0 div Z;
        Observer.ObserveError('zero_div');
        asserterror R := 0 mod Z;
        Observer.ObserveError('zero_mod');
        Observer.Expect('div|text', 'Attempted to divide by zero.');
        Observer.Expect('div|code', 'AL:DivideByZero');
        Observer.Expect('mod|text', 'Attempted to divide by zero.');
        Observer.Expect('mod|code', 'AL:DivideByZero');
        Observer.Expect('slash|text', 'Attempted to divide by zero.');
        Observer.Expect('slash|code', 'AL:DivideByZero');
        Observer.Expect('zero_div|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_div|code', 'AL:DivideByZero');
        Observer.Expect('zero_mod|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_mod|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Overflow()
    var
        Observer: Codeunit "Probe Observer";
        Mx: Integer;
        Mn: Integer;
        One: Integer;
        R: Integer;
    begin
        Mx := 2147483647;
        Mn := -2147483647 - 1;
        One := 1;
        asserterror R := Mx + One;
        Observer.ObserveError('max_plus');
        asserterror R := Mn - One;
        Observer.ObserveError('min_minus');
        asserterror R := Mx * 2;
        Observer.ObserveError('max_times');
        asserterror R := -Mn;
        Observer.ObserveError('neg_min');
        asserterror R := Mn * -1;
        Observer.ObserveError('min_times_neg');
        asserterror R := Mn div -1;
        Observer.ObserveError('min_div_neg');
        asserterror R := Mn mod -1;
        Observer.ObserveError('min_mod_neg');
        asserterror R := Abs(Mn);
        Observer.ObserveError('abs_min');
        R := Mx - One;
        Observer.Observe('max_minus', Format(R));
        R := Mn + One;
        Observer.Observe('min_plus', Format(R));
        R := Abs(Mn + One);
        Observer.Observe('abs_min1', Format(R));
        Observer.Expect('max_plus|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('max_plus|code', 'AL:Overflow');
        Observer.Expect('min_minus|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_minus|code', 'AL:Overflow');
        Observer.Expect('max_times|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('max_times|code', 'AL:Overflow');
        Observer.Expect('neg_min|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('neg_min|code', 'AL:Overflow');
        Observer.Expect('min_times_neg|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_times_neg|code', 'AL:Overflow');
        Observer.Expect('min_div_neg|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_div_neg|code', 'AL:Overflow');
        Observer.Expect('min_mod_neg|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('min_mod_neg|code', 'AL:Overflow');
        Observer.Expect('abs_min|text', 'Negating the minimum value of a twos complement number is invalid.');
        Observer.Expect('abs_min|code', 'AL:Overflow');
        Observer.Expect('max_minus', '2147483646');
        Observer.Expect('min_plus', '-2147483647');
        Observer.Expect('abs_min1', '2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Increment()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        I := 2147483646;
        I += 1;
        Observer.Observe('to_max', Format(I));
        asserterror I += 1;
        Observer.ObserveError('past_max');
        Observer.Observe('after_error', Format(I));
        I := -2147483647;
        I -= 1;
        Observer.Observe('to_min', Format(I));
        asserterror I -= 1;
        Observer.ObserveError('past_min');
        I := 10;
        I *= 3;
        Observer.Observe('times', Format(I));
        asserterror I /= 4;
        Observer.ObserveError('af123');
        Observer.Observe('divide', Format(I));
        Observer.Expect('to_max', '2147483647');
        Observer.Expect('past_max|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('past_max|code', 'AL:Overflow');
        Observer.Expect('after_error', '2147483647');
        Observer.Expect('to_min', '-2147483648');
        Observer.Expect('past_min|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('past_min|code', 'AL:Overflow');
        Observer.Expect('times', '30');
        Observer.Expect('af123|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 7.5 to System.Int32.');
        Observer.Expect('af123|code', 'ConversionCast');
        Observer.Expect('divide', '30');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_DivisionResult()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        D: Decimal;
        I: Integer;
    begin
        A := 7;
        B := 2;
        D := A / B;
        Observer.Observe('dec', Format(D));
        asserterror I := A / B;
        Observer.ObserveError('to_int');
        A := 8;
        I := A / B;
        Observer.Observe('exact', Format(I));
        A := 1;
        B := 3;
        D := A / B;
        Observer.Observe('third', Format(D));
        Observer.Observe('third9', Format(D, 0, 9));
        Observer.Expect('dec', '3.5');
        Observer.Expect('to_int|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3.5 to System.Int32.');
        Observer.Expect('to_int|code', 'ConversionCast');
        Observer.Expect('exact', '4');
        Observer.Expect('third', '0.333333333333333333');
        Observer.Expect('third9', '0.333333333333333333');
        Observer.Verify();
    end;

    [Test]
    procedure Integer_Compare()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
    begin
        A := -5;
        B := 3;
        Observer.Observe('lt', Format(A < B));
        Observer.Observe('gt', Format(A > B));
        Observer.Observe('le', Format(A <= A));
        Observer.Observe('ge', Format(A >= B));
        Observer.Observe('eq', Format(A = B));
        Observer.Observe('ne', Format(A <> B));
        Observer.Observe('default', Format(Default0()));
        Observer.Observe('in', Format(A in [-5, 0, 3]));
        Observer.Observe('range', Format(B in [1 .. 5]));
        Observer.Observe('not_in', Format(B in [4 .. 5]));
        Observer.Expect('lt', 'Yes');
        Observer.Expect('gt', 'No');
        Observer.Expect('le', 'Yes');
        Observer.Expect('ge', 'No');
        Observer.Expect('eq', 'No');
        Observer.Expect('ne', 'Yes');
        Observer.Expect('default', '0');
        Observer.Expect('in', 'Yes');
        Observer.Expect('range', 'Yes');
        Observer.Expect('not_in', 'No');
        Observer.Verify();
    end;

    local procedure Default0(): Integer
    var
        I: Integer;
    begin
        exit(I);
    end;
}
