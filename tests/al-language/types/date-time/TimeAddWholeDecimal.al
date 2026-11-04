// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/time-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73747
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a Time plus and minus a Decimal variable that holds a whole number (1000, 0, negative, a day, from a division, beyond Integer), the undefined time with a Decimal, a fractional Decimal.
//   Time with Integer and with a fractional Decimal is pinned already by types/PUTimeArithmetic.al; DateTime with a whole Decimal by record/lt-record-conversion-assumptions/DateDecimalWhole.al.
// BC versions: 29 (27 and 28 by CI)

codeunit 73747 "LT TimeDec Whole"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure TimeDecimal_Whole_PlusMinus1000()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
    begin
        T := 120000T;
        Dec := 1000;
        Observer.Observe('plus', Format(T + Dec, 0, 9));
        Observer.Observe('minus', Format(T - Dec, 0, 9));
        Dec := 1000.0;
        Observer.Observe('plusPointZero', Format(T + Dec, 0, 9));
        Observer.Observe('minusPointZero', Format(T - Dec, 0, 9));
        Observer.Observe('sumAssigned', Format(T + 1000, 0, 9));
        Observer.Expect('plus', '12:00:01');
        Observer.Expect('minus', '11:59:59');
        Observer.Expect('plusPointZero', '12:00:01');
        Observer.Expect('minusPointZero', '11:59:59');
        Observer.Expect('sumAssigned', '12:00:01');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Whole_Zero()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
    begin
        T := 120000T;
        Dec := 0;
        Observer.Observe('plus0', Format(T + Dec, 0, 9));
        Observer.Observe('minus0', Format(T - Dec, 0, 9));
        Observer.Expect('plus0', '12:00:00');
        Observer.Expect('minus0', '12:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Whole_Negative()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
    begin
        T := 120000T;
        Dec := -1000;
        Observer.Observe('plusNeg', Format(T + Dec, 0, 9));
        Observer.Observe('minusNeg', Format(T - Dec, 0, 9));
        Observer.Expect('plusNeg', '11:59:59');
        Observer.Expect('minusNeg', '12:00:01');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Whole_WrapsAroundMidnight()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
    begin
        T := 235959T;
        Dec := 2000;
        Observer.Observe('plusWrap', Format(T + Dec, 0, 9));
        T := 000001T;
        Observer.Observe('minusWrap', Format(T - Dec, 0, 9));
        T := 120000T;
        Dec := 86400000;
        Observer.Observe('plusDay', Format(T + Dec, 0, 9));
        Observer.Observe('minusDay', Format(T - Dec, 0, 9));
        Dec := 90000000;
        Observer.Observe('plusDayAndHour', Format(T + Dec, 0, 9));
        Observer.Expect('plusWrap', '00:00:01');
        Observer.Expect('minusWrap', '23:59:59');
        Observer.Expect('plusDay', '12:00:00');
        Observer.Expect('minusDay', '12:00:00');
        Observer.Expect('plusDayAndHour', '13:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Whole_FromDivisionAndProduct()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
    begin
        T := 120000T;
        Dec := 2000 / 2;
        Observer.Observe('division', Format(T + Dec, 0, 9));
        Dec := 0.5 * 2000;
        Observer.Observe('product', Format(T + Dec, 0, 9));
        Dec := 1000.00;
        Observer.Observe('twoZeros', Format(T + Dec, 0, 9));
        Observer.Expect('division', '12:00:01');
        Observer.Expect('product', '12:00:01');
        Observer.Expect('twoZeros', '12:00:01');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Whole_BeyondInteger()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
        R: Time;
    begin
        T := 120000T;
        Dec := 3000000000.0;
        asserterror R := T + Dec;
        Observer.ObserveError('plusBeyond');
        asserterror R := T - Dec;
        Observer.ObserveError('minusBeyond');
        Observer.Expect('plusBeyond|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000.0 to System.Int32.');
        Observer.Expect('plusBeyond|code', 'ConversionCast');
        Observer.Expect('minusBeyond|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -3000000000.0 to System.Int32.');
        Observer.Expect('minusBeyond|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_Fractional()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
        R: Time;
    begin
        T := 120000T;
        Dec := 1000.5;
        asserterror R := T + Dec;
        Observer.ObserveError('plusFrac');
        asserterror R := T - Dec;
        Observer.ObserveError('minusFrac');
        Observer.Expect('plusFrac|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1000.5 to System.Int32.');
        Observer.Expect('plusFrac|code', 'ConversionCast');
        Observer.Expect('minusFrac|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -1000.5 to System.Int32.');
        Observer.Expect('minusFrac|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_UndefinedTime()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        Dec: Decimal;
        R: Time;
    begin
        Dec := 1000;
        asserterror R := T + Dec;
        Observer.ObserveError('undefinedPlus');
        asserterror R := T - Dec;
        Observer.ObserveError('undefinedMinus');
        Dec := 0;
        asserterror R := T + Dec;
        Observer.ObserveError('undefinedPlusZero');
        Observer.Expect('undefinedPlus|text', 'Adding to an undefined (0T) time.');
        Observer.Expect('undefinedPlus|code', 'InvalidTime');
        Observer.Expect('undefinedMinus|text', 'Adding to an undefined (0T) time.');
        Observer.Expect('undefinedMinus|code', 'InvalidTime');
        Observer.Expect('undefinedPlusZero|text', 'Adding to an undefined (0T) time.');
        Observer.Expect('undefinedPlusZero|code', 'InvalidTime');
        Observer.Verify();
    end;

    [Test]
    procedure TimeDecimal_AssignedToDecimalAndDuration()
    var
        Observer: Codeunit "Probe Observer";
        T1: Time;
        T2: Time;
        Dec: Decimal;
        Dur: Duration;
    begin
        T1 := 120000T;
        T2 := 120001T;
        Dec := T2 - T1;
        Dur := T2 - T1;
        Observer.Observe('timeDiffToDecimal', Format(Dec));
        Observer.Observe('timeDiffToDuration', Format(Dur, 0, 9));
        Observer.Observe('addBack', Format(T1 + Dec, 0, 9));
        Observer.Expect('timeDiffToDecimal', '1,000');
        Observer.Expect('timeDiffToDuration', 'P0DT0H0M1.0S');
        Observer.Expect('addBack', '12:00:01');
        Observer.Verify();
    end;
}
