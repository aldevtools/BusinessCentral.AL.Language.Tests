// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-operators-and-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 72790
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: the error text and code of "/", "div" and "mod" with a zero right operand over Integer, BigInteger, Decimal and Duration, and the zero-dividend cases that must not fail.
codeunit 72790 "LT Binary DivByZero"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_DivisionByZero_IntegerOperands()
    var
        Observer: Codeunit "Probe Observer";
        Zero: Integer;
        One: Integer;
        R: Integer;
        Q: Decimal;
    begin
        Zero := 0;
        One := 1;
        asserterror Q := One / Zero;
        Observer.ObserveError('int-slash-zero');
        asserterror R := One div Zero;
        Observer.ObserveError('int-div-zero');
        asserterror R := One mod Zero;
        Observer.ObserveError('int-mod-zero');
        asserterror Q := Zero / Zero;
        Observer.ObserveError('zero-slash-zero');
        asserterror R := -One div Zero;
        Observer.ObserveError('neg-div-zero');
        Q := Zero / One;
        Observer.Observe('zero-slash-one', Format(Q));
        R := Zero div One;
        Observer.Observe('zero-div-one', Format(R));
        R := Zero mod One;
        Observer.Observe('zero-mod-one', Format(R));
        Observer.Expect('int-slash-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('int-slash-zero|code', 'AL:DivideByZero');
        Observer.Expect('int-div-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('int-div-zero|code', 'AL:DivideByZero');
        Observer.Expect('int-mod-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('int-mod-zero|code', 'AL:DivideByZero');
        Observer.Expect('zero-slash-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('zero-slash-zero|code', 'AL:DivideByZero');
        Observer.Expect('neg-div-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('neg-div-zero|code', 'AL:DivideByZero');
        Observer.Expect('zero-slash-one', '0');
        Observer.Expect('zero-div-one', '0');
        Observer.Expect('zero-mod-one', '0');
        Observer.Verify();
    end;

    [Test]
    procedure P195_DivisionByZero_DecimalBigIntegerDuration()
    var
        Observer: Codeunit "Probe Observer";
        DZero: Decimal;
        D: Decimal;
        BigZero: BigInteger;
        Big: BigInteger;
        DurZero: Integer;
        Dur: Duration;
    begin
        DZero := 0;
        D := 2.5;
        asserterror D := D / DZero;
        Observer.ObserveError('dec-slash-zero');
        asserterror D := 5 / DZero;
        Observer.ObserveError('int-slash-dec-zero');
        Big := 5;
        BigZero := 0;
        asserterror Big := Big div BigZero;
        Observer.ObserveError('big-div-zero');
        asserterror Big := Big mod BigZero;
        Observer.ObserveError('big-mod-zero');
        asserterror D := Big / BigZero;
        Observer.ObserveError('big-slash-zero');
        Dur := 1000;
        DurZero := 0;
        asserterror Dur := Dur / DurZero;
        Observer.ObserveError('duration-slash-zero');
        D := DZero / 2;
        Observer.Observe('dec-zero-over-two', Format(D));
        D := 0 * 5.5;
        Observer.Observe('zero-times-dec', Format(D));
        Observer.Expect('dec-slash-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('dec-slash-zero|code', 'AL:DivideByZero');
        Observer.Expect('int-slash-dec-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('int-slash-dec-zero|code', 'AL:DivideByZero');
        Observer.Expect('big-div-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('big-div-zero|code', 'AL:DivideByZero');
        Observer.Expect('big-mod-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('big-mod-zero|code', 'AL:DivideByZero');
        Observer.Expect('big-slash-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('big-slash-zero|code', 'AL:DivideByZero');
        Observer.Expect('duration-slash-zero|text', 'Attempted to divide by zero.');
        Observer.Expect('duration-slash-zero|code', 'AL:DivideByZero');
        Observer.Expect('dec-zero-over-two', '0');
        Observer.Expect('zero-times-dec', '0');
        Observer.Verify();
    end;
}
