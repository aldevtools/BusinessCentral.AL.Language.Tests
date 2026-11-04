// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ref-overview-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71432
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

// Facts: Duration mod Integer for a Duration larger than an Integer (25 days) and for a negative Duration; the sign of the remainder; a zero divisor.
codeunit 71432 "LT Dur Mod Integer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Days25(): BigInteger
    var
        B: BigInteger;
    begin
        B := 86400000;
        B := B * 25;
        exit(B);
    end;

    local procedure Days25Plus(Extra: Integer): BigInteger
    begin
        exit(Days25() + Extra);
    end;

    local procedure MaxIntPlusOne(): BigInteger
    var
        B: BigInteger;
    begin
        B := 2147483647;
        exit(B + 1);
    end;

    local procedure Dur(Ms: BigInteger): Duration
    var
        D: Duration;
    begin
        D := Ms;
        exit(D);
    end;

    [TryFunction]
    local procedure TryMod(D: Duration; Divisor: Integer; var R: BigInteger)
    begin
        R := D mod Divisor;
    end;

    [Test]
    procedure Mod_Integer_LargeDuration()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryMod(Dur(Days25Plus(7)), 1000, R);
        Observer.Observe('mod 1000 ok', Format(Ok));
        Observer.Observe('mod 1000', Format(R));
        Ok := TryMod(Dur(Days25Plus(7)), 7, R);
        Observer.Observe('mod 7 ok', Format(Ok));
        Observer.Observe('mod 7', Format(R));
        Ok := TryMod(Dur(Days25()), 2147483647, R);
        Observer.Observe('mod max Integer ok', Format(Ok));
        Observer.Observe('mod max Integer', Format(R));
        Observer.Expect('mod 1000 ok', 'Yes');
        Observer.Expect('mod 1000', '7');
        Observer.Expect('mod 7 ok', 'Yes');
        Observer.Expect('mod 7', '4');
        Observer.Expect('mod max Integer ok', 'Yes');
        Observer.Expect('mod max Integer', '12516353');
        Observer.Verify();
    end;

    [Test]
    procedure Mod_Integer_NegativeDuration()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryMod(Dur(-100000), 7, R);
        Observer.Observe('negative dividend ok', Format(Ok));
        Observer.Observe('negative dividend', Format(R));
        Ok := TryMod(Dur(100000), -7, R);
        Observer.Observe('negative divisor ok', Format(Ok));
        Observer.Observe('negative divisor', Format(R));
        Observer.Expect('negative dividend ok', 'Yes');
        Observer.Expect('negative dividend', '-5');
        Observer.Expect('negative divisor ok', 'Yes');
        Observer.Expect('negative divisor', '5');
        Observer.Verify();
    end;

    [Test]
    procedure Mod_Integer_ZeroDivisor()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryMod(Dur(100000), 0, R);
        Observer.Observe('zero divisor ok', Format(Ok));
        Observer.ObserveError('zero divisor');
        Observer.Expect('zero divisor ok', 'No');
        Observer.Expect('zero divisor|text', 'Attempted to divide by zero.');
        Observer.Expect('zero divisor|code', 'AL:DivideByZero');
        Observer.Verify();
    end;
}
