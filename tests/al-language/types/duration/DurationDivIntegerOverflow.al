// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/ref-overview-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); test codeunit 71431
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

// Facts: Duration div Integer when the quotient does not fit an Integer (25 days = 2160000000 ms div 1), assigned to Integer, BigInteger and Decimal and passed to Format; and the quotient that still fits.
codeunit 71431 "LT Dur Div Int Overflow"
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
    local procedure TryDivToInteger(D: Duration; Divisor: Integer; var R: Integer)
    begin
        R := D div Divisor;
    end;

    [TryFunction]
    local procedure TryDivToBigInteger(D: Duration; Divisor: Integer; var R: BigInteger)
    begin
        R := D div Divisor;
    end;

    [TryFunction]
    local procedure TryDivFormat(D: Duration; Divisor: Integer; var R: Text)
    begin
        R := Format(D div Divisor);
    end;

    [Test]
    procedure Div_Integer_QuotientDoesNotFit()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        T: Text;
        Ok: Boolean;
    begin
        Ok := TryDivToInteger(Dur(Days25()), 1, I);
        Observer.Observe('to Integer ok', Format(Ok));
        Observer.ObserveError('to Integer');
        Ok := TryDivToBigInteger(Dur(Days25()), 1, B);
        Observer.Observe('to BigInteger ok', Format(Ok));
        Observer.Observe('to BigInteger', Format(B));
        Observer.ObserveError('to BigInteger');
        Ok := TryDivFormat(Dur(Days25()), 1, T);
        Observer.Observe('format ok', Format(Ok));
        Observer.Observe('format', T);
        Observer.ObserveError('format');
        Observer.Expect('to Integer ok', 'No');
        Observer.Expect('to Integer|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2160000000 to System.Int32.');
        Observer.Expect('to Integer|code', 'ConversionCast');
        Observer.Expect('to BigInteger ok', 'Yes');
        Observer.Expect('to BigInteger', '2160000000');
        Observer.Expect('to BigInteger|text', '');
        Observer.Expect('to BigInteger|code', '');
        Observer.Expect('format ok', 'Yes');
        Observer.Expect('format', '2,160,000,000');
        Observer.Expect('format|text', '');
        Observer.Expect('format|code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Div_Integer_QuotientFits()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryDivToInteger(Dur(Days25()), 2, I);
        Observer.Observe('half ok', Format(Ok));
        Observer.Observe('half', Format(I));
        Ok := TryDivToBigInteger(Dur(2147483647), 1, B);
        Observer.Observe('max Integer ok', Format(Ok));
        Observer.Observe('max Integer', Format(B));
        Ok := TryDivToInteger(Dur(2147483647), 1, I);
        Observer.Observe('max Integer to Integer ok', Format(Ok));
        Observer.Observe('max Integer to Integer', Format(I));
        Ok := TryDivToInteger(Dur(MaxIntPlusOne()), 1, I);
        Observer.Observe('max Integer plus one ok', Format(Ok));
        Observer.ObserveError('max Integer plus one');
        Observer.Expect('half ok', 'Yes');
        Observer.Expect('half', '1080000000');
        Observer.Expect('max Integer ok', 'Yes');
        Observer.Expect('max Integer', '2147483647');
        Observer.Expect('max Integer to Integer ok', 'Yes');
        Observer.Expect('max Integer to Integer', '2147483647');
        Observer.Expect('max Integer plus one ok', 'No');
        Observer.Expect('max Integer plus one|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2147483648 to System.Int32.');
        Observer.Expect('max Integer plus one|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure Div_Integer_NegativeLargeQuotient()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        Ok: Boolean;
    begin
        Ok := TryDivToInteger(Dur(-Days25()), 1, I);
        Observer.Observe('negative to Integer ok', Format(Ok));
        Observer.ObserveError('negative to Integer');
        Ok := TryDivToBigInteger(Dur(-Days25()), 1, B);
        Observer.Observe('negative to BigInteger ok', Format(Ok));
        Observer.Observe('negative to BigInteger', Format(B));
        Observer.Expect('negative to Integer ok', 'No');
        Observer.Expect('negative to Integer|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2160000000 to System.Int32.');
        Observer.Expect('negative to Integer|code', 'ConversionCast');
        Observer.Expect('negative to BigInteger ok', 'Yes');
        Observer.Expect('negative to BigInteger', '-2160000000');
        Observer.Verify();
    end;
}
