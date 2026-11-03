// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ref-overview-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71430
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

// Facts: Duration div Duration and Duration mod Duration: values (as Integer, BigInteger, Format), sign, rounding, a zero divisor.
codeunit 71430 "LT Dur Div Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDiv(A: Duration; B: Duration; var R: BigInteger)
    begin
        R := A div B;
    end;

    [TryFunction]
    local procedure TryMod(A: Duration; B: Duration; var R: BigInteger)
    begin
        R := A mod B;
    end;

    local procedure Dur(Ms: BigInteger): Duration
    var
        D: Duration;
    begin
        D := Ms;
        exit(D);
    end;

    [Test]
    procedure Div_TwoDurations()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryDiv(Dur(90000), Dur(30000), R);
        Observer.Observe('exact ok', Format(Ok));
        Observer.Observe('exact', Format(R));
        Ok := TryDiv(Dur(100000), Dur(30000), R);
        Observer.Observe('truncated ok', Format(Ok));
        Observer.Observe('truncated', Format(R));
        Ok := TryDiv(Dur(30000), Dur(90000), R);
        Observer.Observe('smaller ok', Format(Ok));
        Observer.Observe('smaller', Format(R));
        Ok := TryDiv(Dur(-100000), Dur(30000), R);
        Observer.Observe('negative dividend ok', Format(Ok));
        Observer.Observe('negative dividend', Format(R));
        Ok := TryDiv(Dur(100000), Dur(-30000), R);
        Observer.Observe('negative divisor ok', Format(Ok));
        Observer.Observe('negative divisor', Format(R));
        Ok := TryDiv(Dur(0), Dur(30000), R);
        Observer.Observe('zero dividend ok', Format(Ok));
        Observer.Observe('zero dividend', Format(R));
        Observer.Expect('exact ok', 'Yes');
        Observer.Expect('exact', '3');
        Observer.Expect('truncated ok', 'Yes');
        Observer.Expect('truncated', '3');
        Observer.Expect('smaller ok', 'Yes');
        Observer.Expect('smaller', '0');
        Observer.Expect('negative dividend ok', 'Yes');
        Observer.Expect('negative dividend', '-3');
        Observer.Expect('negative divisor ok', 'Yes');
        Observer.Expect('negative divisor', '-3');
        Observer.Expect('zero dividend ok', 'Yes');
        Observer.Expect('zero dividend', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Div_TwoDurations_ZeroDivisor()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryDiv(Dur(100000), Dur(0), R);
        Observer.Observe('zero divisor ok', Format(Ok));
        Observer.ObserveError('zero divisor');
        Observer.Expect('zero divisor ok', 'No');
        Observer.Expect('zero divisor|text', 'Attempted to divide by zero.');
        Observer.Expect('zero divisor|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure Mod_TwoDurations()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryMod(Dur(100000), Dur(30000), R);
        Observer.Observe('mod ok', Format(Ok));
        Observer.Observe('mod', Format(R));
        Ok := TryMod(Dur(90000), Dur(30000), R);
        Observer.Observe('exact mod ok', Format(Ok));
        Observer.Observe('exact mod', Format(R));
        Ok := TryMod(Dur(30000), Dur(90000), R);
        Observer.Observe('smaller mod ok', Format(Ok));
        Observer.Observe('smaller mod', Format(R));
        Ok := TryMod(Dur(-100000), Dur(30000), R);
        Observer.Observe('negative dividend mod ok', Format(Ok));
        Observer.Observe('negative dividend mod', Format(R));
        Ok := TryMod(Dur(100000), Dur(-30000), R);
        Observer.Observe('negative divisor mod ok', Format(Ok));
        Observer.Observe('negative divisor mod', Format(R));
        Observer.Expect('mod ok', 'Yes');
        Observer.Expect('mod', '10000');
        Observer.Expect('exact mod ok', 'Yes');
        Observer.Expect('exact mod', '0');
        Observer.Expect('smaller mod ok', 'Yes');
        Observer.Expect('smaller mod', '30000');
        Observer.Expect('negative dividend mod ok', 'Yes');
        Observer.Expect('negative dividend mod', '-10000');
        Observer.Expect('negative divisor mod ok', 'Yes');
        Observer.Expect('negative divisor mod', '10000');
        Observer.Verify();
    end;

    [Test]
    procedure Mod_TwoDurations_ZeroDivisor()
    var
        Observer: Codeunit "Probe Observer";
        R: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryMod(Dur(100000), Dur(0), R);
        Observer.Observe('zero divisor mod ok', Format(Ok));
        Observer.ObserveError('zero divisor mod');
        Observer.Expect('zero divisor mod ok', 'No');
        Observer.Expect('zero divisor mod|text', 'Attempted to divide by zero.');
        Observer.Expect('zero divisor mod|code', 'AL:DivideByZero');
        Observer.Verify();
    end;
}
