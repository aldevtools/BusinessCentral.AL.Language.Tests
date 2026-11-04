// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ref-overview-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71433
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

// Facts: Duration div Duration with a quotient that does not fit an Integer (25 days div 1 ms = 2160000000), assigned to Integer, BigInteger and Format; Duration div Duration with a Duration much larger than an Integer.
codeunit 71433 "LT Dur Div Dur Overflow"
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
    local procedure TryDivToInteger(A: Duration; B: Duration; var R: Integer)
    begin
        R := A div B;
    end;

    [TryFunction]
    local procedure TryDivToBigInteger(A: Duration; B: Duration; var R: BigInteger)
    begin
        R := A div B;
    end;

    [TryFunction]
    local procedure TryDivFormat(A: Duration; B: Duration; var R: Text)
    begin
        R := Format(A div B);
    end;

    [Test]
    procedure Div_Duration_QuotientDoesNotFit()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Big: BigInteger;
        T: Text;
        Ok: Boolean;
    begin
        Ok := TryDivToInteger(Dur(Days25()), Dur(1), I);
        Observer.Observe('to Integer ok', Format(Ok));
        Observer.ObserveError('to Integer');
        Ok := TryDivToBigInteger(Dur(Days25()), Dur(1), Big);
        Observer.Observe('to BigInteger ok', Format(Ok));
        Observer.Observe('to BigInteger', Format(Big));
        Observer.ObserveError('to BigInteger');
        Ok := TryDivFormat(Dur(Days25()), Dur(1), T);
        Observer.Observe('format ok', Format(Ok));
        Observer.Observe('format', T);
        Observer.ObserveError('format');
        Observer.Expect('to Integer ok', 'No');
        Observer.Expect('to Integer|text', 'Overflow under conversion of System.Int64 value 2160000000 to System.Int32.');
        Observer.Expect('to Integer|code', 'ConversionCast');
        Observer.Expect('to BigInteger ok', 'Yes');
        Observer.Expect('to BigInteger', '2160000000');
        Observer.Expect('to BigInteger|text', '');
        Observer.Expect('to BigInteger|code', '');
        Observer.Expect('format ok', 'Yes');
        Observer.Expect('format', '2160000000');
        Observer.Expect('format|text', '');
        Observer.Expect('format|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Div_Duration_QuotientFits()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        Ok: Boolean;
    begin
        Ok := TryDivToInteger(Dur(2147483647), Dur(1), I);
        Observer.Observe('max Integer ok', Format(Ok));
        Observer.Observe('max Integer', Format(I));
        Ok := TryDivToInteger(Dur(Days25()), Dur(2), I);
        Observer.Observe('half ok', Format(Ok));
        Observer.Observe('half', Format(I));
        Observer.Expect('max Integer ok', 'Yes');
        Observer.Expect('max Integer', '2147483647');
        Observer.Expect('half ok', 'Yes');
        Observer.Expect('half', '1080000000');
        Observer.Verify();
    end;
}
