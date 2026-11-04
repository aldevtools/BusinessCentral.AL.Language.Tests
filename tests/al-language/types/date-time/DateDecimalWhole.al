// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Date + Decimal and Date - Decimal with whole values, and Record.Next(Steps) with whole steps.
// BC versions: 29 (27 and 28 by CI)

table 70342 "LT P98 NextRow"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70341 "LT P98 DateDecimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_DatePlusMinusWholeDecimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        Dec: Decimal;
    begin
        D := DMY2Date(10, 3, 2021);
        Dec := 2;
        Observer.Observe('plusInt', Format(D + 2, 0, 9));
        Observer.Observe('plusDec', Format(D + Dec, 0, 9));
        Observer.Observe('minusDec', Format(D - Dec, 0, 9));
        Dec := 2.0;
        Observer.Observe('plusDec20', Format(D + Dec, 0, 9));
        Dec := -3;
        Observer.Observe('plusNeg', Format(D + Dec, 0, 9));
        Observer.Observe('minusNeg', Format(D - Dec, 0, 9));
        Dec := 0;
        Observer.Observe('plusZero', Format(D + Dec, 0, 9));
        Dec := 365;
        Observer.Observe('plus365', Format(D + Dec, 0, 9));
        Observer.Observe('minus365', Format(D - Dec, 0, 9));
        Observer.Expect('plusInt', '2021-03-12');
        Observer.Expect('plusDec', '2021-03-12');
        Observer.Expect('minusDec', '2021-03-08');
        Observer.Expect('plusDec20', '2021-03-12');
        Observer.Expect('plusNeg', '2021-03-07');
        Observer.Expect('minusNeg', '2021-03-13');
        Observer.Expect('plusZero', '2021-03-10');
        Observer.Expect('plus365', '2022-03-10');
        Observer.Expect('minus365', '2020-03-10');
        Observer.Verify();
    end;

    [Test]
    procedure P98_DateMinusDate_Type()
    var
        Observer: Codeunit "Probe Observer";
        D1: Date;
        D2: Date;
        Dec: Decimal;
        Int: Integer;
    begin
        D1 := DMY2Date(10, 3, 2021);
        D2 := DMY2Date(1, 3, 2021);
        Dec := D1 - D2;
        Int := D1 - D2;
        Observer.Observe('dec', Format(Dec));
        Observer.Observe('int', Format(Int));
        Observer.Observe('expr', Format(D1 - D2));
        Observer.Expect('dec', '9');
        Observer.Expect('int', '9');
        Observer.Expect('expr', '9');
        Observer.Verify();
    end;

    [Test]
    procedure P98_DateTimePlusDecimal()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
        Dec: Decimal;
    begin
        DT := CreateDateTime(DMY2Date(10, 3, 2021), 120000T);
        Dec := 1000;
        Observer.Observe('plus', Format(DT + Dec, 0, 9));
        Observer.Observe('minus', Format(DT - Dec, 0, 9));
        Dec := 1000.5;
        asserterror Observer.Observe('plusFrac', Format(DT + Dec, 0, 9));
        Observer.ObserveError('af78');
        Observer.Expect('plus', '2021-03-10T12:00:01Z');
        Observer.Expect('minus', '2021-03-10T11:59:59Z');
        Observer.Expect('af78|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1000.5 to System.Int64.');
        Observer.Expect('af78|code', 'ConversionCast');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Next_WholeSteps()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 NextRow";
        I: Integer;
    begin
        R.DeleteAll();
        for I := 1 to 6 do begin
            R.Id := I;
            R.Insert();
        end;
        R.FindFirst();
        Observer.Observe('next2', Format(R.Next(2)) + '|' + Format(R.Id));
        Observer.Observe('next1', Format(R.Next(1)) + '|' + Format(R.Id));
        Observer.Observe('nextMinus1', Format(R.Next(-1)) + '|' + Format(R.Id));
        Observer.Observe('nextMinus2', Format(R.Next(-2)) + '|' + Format(R.Id));
        Observer.Observe('nextMinus9', Format(R.Next(-9)) + '|' + Format(R.Id));
        Observer.Observe('next0', Format(R.Next(0)) + '|' + Format(R.Id));
        Observer.Observe('next99', Format(R.Next(99)) + '|' + Format(R.Id));
        R.DeleteAll();
        Observer.Expect('next2', '2|3');
        Observer.Expect('next1', '1|4');
        Observer.Expect('nextMinus1', '-1|3');
        Observer.Expect('nextMinus2', '-2|1');
        Observer.Expect('nextMinus9', '0|1');
        Observer.Expect('next0', '0|1');
        Observer.Expect('next99', '5|6');
        Observer.Verify();
    end;
}
