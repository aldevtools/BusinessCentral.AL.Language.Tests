// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-operators-and-expressions
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained test codeunit 72795
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// RISKY: operator and operand combinations the compiler may refuse (Decimal div / mod, Duration / Duration, Duration * Decimal, DateTime + Duration variable, Time + Integer, Date + Integer, BigInteger / BigInteger); this file is separate so only it drops.
// Facts: result and Format of the combinations above.
codeunit 72795 "LT Binary Risky"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P195_Binary_DecimalDivMod()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := 7.9;
        Observer.Observe('dec-div-int', Format(D div 2));
        Observer.Observe('dec-mod-int', Format(D mod 2));
        Observer.Observe('dec-literal-div', Format(7.9 div 2));
        Observer.Observe('dec-literal-mod', Format(7.9 mod 2));
        Observer.Observe('neg-dec-div', Format(-7.9 div 2));
        Observer.Observe('neg-dec-mod', Format(-7.9 mod 2));
        Observer.Expect('dec-div-int', '3');
        Observer.Expect('dec-mod-int', '1.9');
        Observer.Expect('dec-literal-div', '3');
        Observer.Expect('dec-literal-mod', '1.9');
        Observer.Expect('neg-dec-div', '-3');
        Observer.Expect('neg-dec-mod', '-1.9');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_DurationMixed()
    var
        Observer: Codeunit "Probe Observer";
        A: Duration;
        B: Duration;
        DT: DateTime;
    begin
        A := 90000;
        B := 30000;
        DT := CreateDateTime(20240115D, 100000T);
        Observer.Observe('dur-mul-dec', Format(A * 1.5, 0, 9));
        Observer.Observe('dur-slash-dur', Format(A / B));
        Observer.Observe('dt-plus-dur-var', Format(DT + A, 0, 9));
        Observer.Observe('dt-minus-dur-var', Format(DT - A, 0, 9));
        Observer.Observe('dur-div-int', Format(A div 7));
        Observer.Observe('dur-mod-int', Format(A mod 7));
        Observer.Expect('dur-mul-dec', '135000');
        Observer.Expect('dur-slash-dur', '3');
        Observer.Expect('dt-plus-dur-var', '2024-01-15T10:01:30Z');
        Observer.Expect('dt-minus-dur-var', '2024-01-15T09:58:30Z');
        Observer.Expect('dur-div-int', '12,857');
        Observer.Expect('dur-mod-int', '1');
        Observer.Verify();
    end;

    [Test]
    procedure P195_Binary_TimeDateIntegerOperands()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        D: Date;
        Big: BigInteger;
    begin
        T := 100000T;
        D := 20240115D;
        Observer.Observe('time-plus-int', Format(T + 60000, 0, 9));
        Observer.Observe('time-minus-int', Format(T - 60000, 0, 9));
        Observer.Observe('date-plus-int', Format(D + 1, 0, 9));
        Observer.Observe('date-minus-int', Format(D - 1, 0, 9));
        Big := 10;
        Observer.Observe('big-slash-big', Format(Big / Big));
        Observer.Observe('big-div-big', Format(Big div Big));
        Observer.Expect('time-plus-int', '10:01:00');
        Observer.Expect('time-minus-int', '09:59:00');
        Observer.Expect('date-plus-int', '2024-01-16');
        Observer.Expect('date-minus-int', '2024-01-14');
        Observer.Expect('big-slash-big', '1');
        Observer.Expect('big-div-big', '1');
        Observer.Verify();
    end;
}
