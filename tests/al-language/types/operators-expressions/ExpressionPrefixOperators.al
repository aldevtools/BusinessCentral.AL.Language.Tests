// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-operators-and-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 72792
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: unary - + and not over Integer, BigInteger, Decimal, Duration and Boolean, stacked prefixes (- -5, not not true), the overflow of -(smallest Integer), and the sign of zero. "not" on an Integer and "-" on a Text are compile errors and cannot be observed at runtime.
codeunit 72792 "LT Prefix Operators"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_Prefix_StackedAndLiterals()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: Boolean;
    begin
        I := 5;
        B := true;
        Observer.Observe('neg-neg-literal', Format(- -5));
        Observer.Observe('neg-neg-var', Format(- -I));
        Observer.Observe('pos-pos-literal', Format(+ +5));
        Observer.Observe('neg-pos-literal', Format(-+5));
        Observer.Observe('pos-neg-literal', Format(+-5));
        Observer.Observe('neg-neg-neg', Format(- - -I));
        Observer.Observe('not-not-literal', Format(not not true));
        Observer.Observe('not-not-not-var', Format(not not not B));
        Observer.Observe('not-in-and', Format(not B and B));
        Observer.Observe('not-in-or', Format(not B or B));
        Observer.Observe('not-paren-and', Format(not (B and B)));
        Observer.Observe('neg-binds-tighter-than-mul', Format(-I * 2));
        Observer.Observe('neg-binds-tighter-than-mod', Format(-7 mod 3));
        Observer.Observe('neg-binds-tighter-than-div', Format(-7 div 2));
        Observer.Observe('neg-sub', Format(3 - -I));
        Observer.Observe('pos-add', Format(3 + +I));
        Observer.Observe('not-eq-precedence', Format(not (I = 5)));
        Observer.Expect('neg-neg-literal', '5');
        Observer.Expect('neg-neg-var', '5');
        Observer.Expect('pos-pos-literal', '5');
        Observer.Expect('neg-pos-literal', '-5');
        Observer.Expect('pos-neg-literal', '-5');
        Observer.Expect('neg-neg-neg', '-5');
        Observer.Expect('not-not-literal', 'Yes');
        Observer.Expect('not-not-not-var', 'No');
        Observer.Expect('not-in-and', 'No');
        Observer.Expect('not-in-or', 'Yes');
        Observer.Expect('not-paren-and', 'No');
        Observer.Expect('neg-binds-tighter-than-mul', '-10');
        Observer.Expect('neg-binds-tighter-than-mod', '-1');
        Observer.Expect('neg-binds-tighter-than-div', '-3');
        Observer.Expect('neg-sub', '8');
        Observer.Expect('pos-add', '8');
        Observer.Expect('not-eq-precedence', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Prefix_DecimalBigIntegerDuration()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
        Z: Decimal;
        Big: BigInteger;
        Dur: Duration;
    begin
        D := 2.5;
        Z := 0;
        Big := 2147483647;
        Big := Big * 4;
        Dur := 90000;
        Observer.Observe('neg-dec', Format(-D));
        Observer.Observe('pos-dec', Format(+D));
        Observer.Observe('neg-zero-dec', Format(-Z));
        Observer.Observe('neg-zero-dec-xml', Format(-Z, 0, 9));
        Observer.Observe('neg-zero-eq-zero', Format(-Z = Z));
        Observer.Observe('neg-big', Format(-Big));
        Observer.Observe('pos-big', Format(+Big));
        Observer.Observe('neg-neg-big', Format(-(-Big)));
        Observer.Observe('neg-dec-literal', Format(-0.5));
        Observer.Observe('neg-dec-round', Format(Round(-2.5, 1)));
        Observer.Observe('neg-dec-in-sum', Format(1.5 + -D));
        Observer.Expect('neg-dec', '-2.5');
        Observer.Expect('pos-dec', '2.5');
        Observer.Expect('neg-zero-dec', '0');
        Observer.Expect('neg-zero-dec-xml', '0');
        Observer.Expect('neg-zero-eq-zero', 'Yes');
        Observer.Expect('neg-big', '-8589934588');
        Observer.Expect('pos-big', '8589934588');
        Observer.Expect('neg-neg-big', '8589934588');
        Observer.Expect('neg-dec-literal', '-0.5');
        Observer.Expect('neg-dec-round', '-3');
        Observer.Expect('neg-dec-in-sum', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Prefix_IntegerEdges()
    var
        Observer: Codeunit "Probe Observer";
        Min: Integer;
        Max: Integer;
        R: Integer;
        Zero: Integer;
    begin
        Max := 2147483647;
        Min := -Max - 1;
        Zero := 0;
        Observer.Observe('min', Format(Min));
        Observer.Observe('neg-max', Format(-Max));
        Observer.Observe('neg-zero', Format(-Zero));
        Observer.Observe('pos-min', Format(+Min));
        asserterror R := -Min;
        Observer.ObserveError('neg-min');
        asserterror R := -(-Max - 1);
        Observer.ObserveError('neg-min-expression');
        Observer.Observe('neg-min-plus-one', Format(-(Min + 1)));
        Observer.Observe('abs-min-plus-one', Format(Abs(Min + 1)));
        Observer.Expect('min', '-2147483648');
        Observer.Expect('neg-max', '-2147483647');
        Observer.Expect('neg-zero', '0');
        Observer.Expect('pos-min', '-2147483648');
        Observer.Expect('neg-min|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('neg-min|code', 'AL:Overflow');
        Observer.Expect('neg-min-expression|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('neg-min-expression|code', 'AL:Overflow');
        Observer.Expect('neg-min-plus-one', '2147483647');
        Observer.Expect('abs-min-plus-one', '2147483647');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Prefix_BooleanFromComparisons()
    var
        Observer: Codeunit "Probe Observer";
        A: Boolean;
        B: Boolean;
        Opt: Option X,Y;
    begin
        A := true;
        B := false;
        Opt := Opt::Y;
        Observer.Observe('not-a', Format(not A));
        Observer.Observe('not-b', Format(not B));
        Observer.Observe('not-a-xml', Format(not A, 0, 9));
        Observer.Observe('not-a-eq-b', Format((not A) = B));
        Observer.Observe('not-not-a-eq-a', Format((not not A) = A));
        Observer.Observe('not-option-eq', Format(not (Opt = Opt::Y)));
        Observer.Observe('not-option-ne', Format(not (Opt <> Opt::Y)));
        Observer.Observe('not-text-eq', Format(not ('a' = 'A')));
        Observer.Observe('not-in-set', Format(not (3 in [1 .. 5])));
        Observer.Observe('not-xor', Format(not (A xor B)));
        Observer.Observe('not-a-xor-b', Format(not A xor B));
        Observer.Expect('not-a', 'No');
        Observer.Expect('not-b', 'Yes');
        Observer.Expect('not-a-xml', 'false');
        Observer.Expect('not-a-eq-b', 'Yes');
        Observer.Expect('not-not-a-eq-a', 'Yes');
        Observer.Expect('not-option-eq', 'No');
        Observer.Expect('not-option-ne', 'Yes');
        Observer.Expect('not-text-eq', 'Yes');
        Observer.Expect('not-in-set', 'No');
        Observer.Expect('not-xor', 'No');
        Observer.Expect('not-a-xor-b', 'No');
        Observer.Verify();
    end;
}
