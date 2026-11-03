// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Facts: a Duration divided by an Integer, a Decimal and a BigInteger into a Decimal and into a Duration, Format(D / Dec), a zero Decimal
//   divisor; Format(D * 1.5, 0, 9) and Format(D / 2.5, 0, 9); a Decimal of 1E19 assigned to a Duration; a Date assigned to a DateTime
//   through a Variant (defined, blank, closing date); Time plus and minus a BigInteger.
// BC versions: 27.5+

codeunit 80424 "LT AX Duration DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [TryFunction]
    local procedure TryDivDec(D: Duration; Divisor: Decimal; var Result: Decimal)
    begin
        Result := D / Divisor;
    end;

    [Test]
    procedure Duration_DividedBy_IntegerAndDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
        Divisor: Decimal;
    begin
        D := 26820000;
        Dec := D / 60000;
        Observer.Observe('26820000/60000', Format(Dec, 0, 9));
        D := 30000;
        Dec := D / 60000;
        Observer.Observe('30000/60000', Format(Dec, 0, 9));
        Divisor := 60000;
        D := 26820000;
        Dec := D / Divisor;
        Observer.Observe('26820000/Dec60000', Format(Dec, 0, 9));
        Observer.Observe('Format(D/Dec)', Format(D / Divisor));
        D := 30000;
        Observer.Observe('Format(30000/Dec)', Format(D / Divisor));
        Divisor := 7;
        Observer.Observe('Format(30000/Dec7)', Format(D / Divisor));
        Observer.Expect('26820000/60000', '447');
        Observer.Expect('30000/60000', '0.5');
        Observer.Expect('26820000/Dec60000', '447');
        Observer.Expect('Format(D/Dec)', '447');
        Observer.Expect('Format(30000/Dec)', '0.5');
        Observer.Expect('Format(30000/Dec7)', '4,285.71428571428571');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedBy_ZeroDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
    begin
        D := 26820000;
        Dec := 42;
        if TryDivDec(D, 0, Dec) then
            Observer.Observe('zero', 'no error|' + Format(Dec, 0, 9))
        else begin
            Observer.ObserveError('zero');
            Observer.Observe('after', Format(Dec, 0, 9));
        end;
        Observer.Expect('zero|text', 'Attempted to divide by zero.');
        Observer.Expect('zero|code', 'AL:DivideByZero');
        Observer.Expect('after', '42');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_MulDiv_Decimal_Format9()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        D := 90000;
        Observer.Observe('90000*1.5', Format(D * 1.5, 0, 9));
        Observer.Observe('90000/2.5', Format(D / 2.5, 0, 9));
        D := 7;
        Observer.Observe('7*1.5', Format(D * 1.5, 0, 9));
        Observer.Observe('7/2.5', Format(D / 2.5, 0, 9));
        Observer.Observe('7*1.5 plain', Format(D * 1.5));
        Observer.Expect('90000*1.5', '135000');
        Observer.Expect('90000/2.5', '36000');
        Observer.Expect('7*1.5', '10.5');
        Observer.Expect('7/2.5', '2.8');
        Observer.Expect('7*1.5 plain', '10.5');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDurDivBig(D: Duration; B: BigInteger; var Result: Duration)
    begin
        Result := D / B;
    end;

    [TryFunction]
    local procedure TryDurFromDec(Dec: Decimal; var Result: Duration)
    begin
        Result := Dec;
    end;

    [Test]
    procedure Duration_IntoDecimal_And_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D: Duration;
        Dec: Decimal;
        B: BigInteger;
    begin
        D1 := 90000;
        Dec := D1 / 7;
        Observer.Observe('dec D1/7', Format(Dec, 0, 9));
        B := 7;
        Dec := D1 / B;
        Observer.Observe('dec D1/big7', Format(Dec, 0, 9));
        B := 4;
        D := 1;
        if TryDurDivBig(D1, B, D) then
            Observer.Observe('dur D1/big4', Format(D, 0, 9))
        else
            Observer.ObserveError('dur D1/big4');
        B := 7;
        D := 1;
        if TryDurDivBig(D1, B, D) then
            Observer.Observe('dur D1/big7', Format(D, 0, 9))
        else begin
            Observer.ObserveError('dur D1/big7');
            Observer.Observe('dur after', Format(D, 0, 9));
        end;
        Observer.Expect('dec D1/7', '12857.1428571428571');
        Observer.Expect('dec D1/big7', '12857.1428571428571');
        Observer.Expect('dur D1/big4', 'P0DT0H0M22.5S');
        Observer.Expect('dur D1/big7|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 12857.1428571428571 to System.Int64.');
        Observer.Expect('dur D1/big7|code', 'ConversionCast');
        Observer.Expect('dur after', 'P0DT0H0M0.001S');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_FromDecimal_1E19()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        Dec: Decimal;
    begin
        Dec := 10000000000000000000.0;
        D := 1;
        if TryDurFromDec(Dec, D) then
            Observer.Observe('1E19', Format(D, 0, 9))
        else begin
            Observer.ObserveError('1E19');
            Observer.Observe('after', Format(D, 0, 9));
        end;
        Dec := 1500.5;
        if TryDurFromDec(Dec, D) then
            Observer.Observe('1500.5', Format(D, 0, 9))
        else
            Observer.ObserveError('1500.5');
        Observer.Expect('1E19|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 10000000000000000000 to System.Int64.');
        Observer.Expect('1E19|code', 'ConversionCast');
        Observer.Expect('after', 'P0DT0H0M0.001S');
        Observer.Expect('1500.5|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1500.5 to System.Int64.');
        Observer.Expect('1500.5|code', 'ConversionCast');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryDateToDateTime(D: Date; var DT: DateTime)
    var
        V: Variant;
    begin
        // DT := D does not compile (AL0122, must-not-compile case 1193): the date goes through a Variant.
        V := D;
        DT := V;
    end;

    local procedure DateToDT(D: Date): Text
    var
        DT: DateTime;
    begin
        DT := 0DT;
        if not TryDateToDateTime(D, DT) then
            exit('error ' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit(Format(DT, 0, 9) + '|same as CreateDateTime ' + Format(DT = CreateDateTime(D, 0T)) + '|0DT ' + Format(DT = 0DT));
    end;

    // The Format(DT, 0, 9) texts are UTC; the CI container's session time zone is UTC, so a date at midnight shows as T00:00:00Z.
    [Test]
    procedure Date_AssignedTo_DateTime()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := DMY2Date(15, 3, 2024);
        Observer.Observe('defined', DateToDT(D));
        Observer.Observe('blank', DateToDT(0D));
        Observer.Observe('closing', DateToDT(ClosingDate(D)));
        Observer.Expect('defined', '2024-03-15T00:00:00Z|same as CreateDateTime Yes|0DT No');
        Observer.Expect('blank', '|same as CreateDateTime Yes|0DT Yes');
        Observer.Expect('closing', '2024-03-15T23:59:59Z|same as CreateDateTime Yes|0DT No');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryTimeMinusBig(T: Time; B: BigInteger; var Result: Time)
    begin
        Result := T - B;
    end;

    [TryFunction]
    local procedure TryTimePlusBig(T: Time; B: BigInteger; var Result: Time)
    begin
        Result := T + B;
    end;

    local procedure TimeBig(T: Time; B: BigInteger; Minus: Boolean): Text
    var
        R: Time;
        Ok: Boolean;
    begin
        if Minus then
            Ok := TryTimeMinusBig(T, B, R)
        else
            Ok := TryTimePlusBig(T, B, R);
        if Ok then
            exit('ok:' + Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Time_PlusMinus_BigInteger()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('T-1500', TimeBig(120000T, 1500, true));
        Observer.Observe('T+1500', TimeBig(120000T, 1500, false));
        Observer.Observe('T--1500', TimeBig(120000T, -1500, true));
        Observer.Observe('T-day', TimeBig(120000T, 86400000, true));
        Observer.Observe('T+3e9', TimeBig(120000T, 3000000000L, false));
        Observer.Observe('0T-1', TimeBig(0T, 1, true));
        Observer.Expect('T-1500', 'ok:11:59:58.5');
        Observer.Expect('T+1500', 'ok:12:00:01.5');
        Observer.Expect('T--1500', 'ok:12:00:01.5');
        Observer.Expect('T-day', 'ok:12:00:00');
        Observer.Expect('T+3e9', 'error:Overflow under conversion of System.Int64 value 3000000000 to System.Int32.|ConversionCast');
        Observer.Expect('0T-1', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Verify();
    end;

    // al-runner issue 6285 (reporter's repro, passed on real BC): Duration * Decimal and Decimal * Duration with a Decimal variable
    // (whole or fractional) multiply into a Decimal that keeps the fraction; assigned to a BigInteger or a Duration.
    [Test]
    procedure Duration_Wb_DurationTimesDecimalVariable100()
    var
        D: Duration;
        Pct: Decimal;
        Result: Decimal;
    begin
        D := 28800000;
        Pct := 100;
        Result := D * Pct;
        Assert.AreEqual('2880000000', Format(Result, 0, 9), 'Duration * Decimal 100');
    end;

    [Test]
    procedure Duration_Wb_DecimalTimesDurationVariable()
    var
        D: Duration;
        Pct: Decimal;
        Result: Decimal;
    begin
        D := 28800000;
        Pct := 100;
        Result := Pct * D;
        Assert.AreEqual('2880000000', Format(Result, 0, 9), 'Decimal 100 * Duration');
    end;

    [Test]
    procedure Duration_Wb_DurationTimesFractionVariable()
    var
        D: Duration;
        Pct: Decimal;
        Result: Decimal;
    begin
        D := 28800000;
        Pct := 0.5;
        Result := D * Pct;
        Assert.AreEqual('14400000', Format(Result, 0, 9), 'Duration * 0.5');
        Pct := 1.25;
        Result := D * Pct;
        Assert.AreEqual('36000000', Format(Result, 0, 9), 'Duration * 1.25');
    end;

    [Test]
    procedure Duration_Wb_DurationTimesPercentOverHundredIntoDuration()
    var
        D: Duration;
        Eff: Decimal;
        Taken: Duration;
        Back: Decimal;
    begin
        D := 28800000;
        Eff := 100;
        Taken := D * Eff / 100;
        Back := Taken;
        Assert.AreEqual('28800000', Format(Back, 0, 9), 'D * Eff / 100 into Duration');
    end;

    [Test]
    procedure Duration_Wb_DurationTimesDecimalIntoBigInteger()
    var
        D: Duration;
        Pct: Decimal;
        Big: BigInteger;
    begin
        D := 28800000;
        Pct := 100;
        Big := D * Pct;
        Assert.AreEqual('2880000000', Format(Big, 0, 9), 'Duration * Decimal 100 into BigInteger');
    end;

    [Test]
    procedure Duration_Wb_DurationTimesDecimalIntoDuration()
    var
        D: Duration;
        Pct: Decimal;
        R: Duration;
        Back: Decimal;
    begin
        D := 28800000;
        Pct := 0.5;
        R := D * Pct;
        Back := R;
        Assert.AreEqual('14400000', Format(Back, 0, 9), 'Duration * 0.5 into Duration');
    end;

    [Test]
    procedure Duration_Wb_DurationTimesFractionPrintsValue()
    var
        D: Duration;
        Pct: Decimal;
    begin
        D := 7;
        Pct := 1.5;
        Assert.AreEqual('10.5|10.5', Format(D * Pct, 0, 9) + '|' + Format(Pct * D, 0, 9), 'exact values');
    end;
}
