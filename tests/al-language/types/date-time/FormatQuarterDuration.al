// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), codeunit 74947
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Format of a Date with the <Quarter> and <Quarter>/<Year4> format strings for a date in each quarter and at the quarter edges; a Duration divided by a Decimal: the Decimal value, its Format, and a zero Decimal divisor.
// BC versions: 29 (27 and 28 by CI)

codeunit 74947 "LT Quarter Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(D: Date; Fmt: Text; var Result: Text)
    begin
        Result := Format(D, 0, Fmt);
    end;

    local procedure FormatOf(D: Date; Fmt: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryFormat(D, Fmt, Result) then
            exit('ok|' + Result);
        exit('error|' + GetLastErrorCode() + '|' + GetLastErrorText());
    end;

    [Test]
    procedure FormatDate_Quarter_EachQuarter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('q1_feb', FormatOf(DMY2Date(15, 2, 2026), '<Quarter>'));
        Observer.Observe('q2_may', FormatOf(DMY2Date(15, 5, 2026), '<Quarter>'));
        Observer.Observe('q3_aug', FormatOf(DMY2Date(15, 8, 2026), '<Quarter>'));
        Observer.Observe('q4_nov', FormatOf(DMY2Date(15, 11, 2026), '<Quarter>'));
        Observer.Expect('q1_feb', 'ok|1');
        Observer.Expect('q2_may', 'ok|2');
        Observer.Expect('q3_aug', 'ok|3');
        Observer.Expect('q4_nov', 'ok|4');
        Observer.Verify();
    end;

    [Test]
    procedure FormatDate_Quarter_QuarterEdges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('jan1', FormatOf(DMY2Date(1, 1, 2026), '<Quarter>'));
        Observer.Observe('mar31', FormatOf(DMY2Date(31, 3, 2026), '<Quarter>'));
        Observer.Observe('apr1', FormatOf(DMY2Date(1, 4, 2026), '<Quarter>'));
        Observer.Observe('jun30', FormatOf(DMY2Date(30, 6, 2026), '<Quarter>'));
        Observer.Observe('jul1', FormatOf(DMY2Date(1, 7, 2026), '<Quarter>'));
        Observer.Observe('sep30', FormatOf(DMY2Date(30, 9, 2026), '<Quarter>'));
        Observer.Observe('oct1', FormatOf(DMY2Date(1, 10, 2026), '<Quarter>'));
        Observer.Observe('dec31', FormatOf(DMY2Date(31, 12, 2026), '<Quarter>'));
        Observer.Expect('jan1', 'ok|1');
        Observer.Expect('mar31', 'ok|1');
        Observer.Expect('apr1', 'ok|2');
        Observer.Expect('jun30', 'ok|2');
        Observer.Expect('jul1', 'ok|3');
        Observer.Expect('sep30', 'ok|3');
        Observer.Expect('oct1', 'ok|4');
        Observer.Expect('dec31', 'ok|4');
        Observer.Verify();
    end;

    [Test]
    procedure FormatDate_QuarterSlashYear4_EachQuarter()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('q1', FormatOf(DMY2Date(15, 2, 2026), '<Quarter>/<Year4>'));
        Observer.Observe('q2', FormatOf(DMY2Date(15, 5, 2026), '<Quarter>/<Year4>'));
        Observer.Observe('q3', FormatOf(DMY2Date(15, 8, 2026), '<Quarter>/<Year4>'));
        Observer.Observe('q4', FormatOf(DMY2Date(15, 11, 2026), '<Quarter>/<Year4>'));
        Observer.Observe('dec31_2025', FormatOf(DMY2Date(31, 12, 2025), '<Quarter>/<Year4>'));
        Observer.Observe('jan1_2027', FormatOf(DMY2Date(1, 1, 2027), '<Quarter>/<Year4>'));
        Observer.Observe('year2', FormatOf(DMY2Date(15, 5, 2026), '<Quarter>/<Year>'));
        Observer.Observe('prefixed', FormatOf(DMY2Date(15, 5, 2026), 'Q<Quarter> <Year4>'));
        Observer.Observe('quarter_twice', FormatOf(DMY2Date(15, 5, 2026), '<Quarter><Quarter>'));
        Observer.Observe('undefined_date', FormatOf(0D, '<Quarter>'));
        Observer.Observe('closing_date', FormatOf(ClosingDate(DMY2Date(31, 12, 2026)), '<Quarter>'));
        Observer.Expect('q1', 'ok|1/2026');
        Observer.Expect('q2', 'ok|2/2026');
        Observer.Expect('q3', 'ok|3/2026');
        Observer.Expect('q4', 'ok|4/2026');
        Observer.Expect('dec31_2025', 'ok|4/2025');
        Observer.Expect('jan1_2027', 'ok|1/2027');
        Observer.Expect('year2', 'ok|2/26');
        Observer.Expect('prefixed', 'ok|Q2 2026');
        Observer.Expect('quarter_twice', 'ok|22');
        Observer.Expect('undefined_date', 'ok|');
        Observer.Expect('closing_date', 'ok|4');
        Observer.Verify();
    end;

    [Test]
    procedure FormatDate_Quarter_WithOtherTokens()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('month_text', FormatOf(DMY2Date(15, 5, 2026), '<Month Text> <Quarter>'));
        Observer.Observe('quarter_day', FormatOf(DMY2Date(15, 5, 2026), '<Quarter>-<Day,2>'));
        Observer.Observe('lower', FormatOf(DMY2Date(15, 5, 2026), '<quarter>'));
        Observer.Expect('month_text', 'ok|May 2');
        Observer.Expect('quarter_day', 'ok|2-15');
        Observer.Expect('lower', 'ok|2');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedByDecimal_Values()
    var
        D: Duration;
        Dec: Decimal;
        Result: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        D := 26820000;
        Dec := 60000.0;
        Result := D / Dec;
        Observer.Observe('big', Format(Result));
        D := 30000;
        Result := D / Dec;
        Observer.Observe('half', Format(Result));
        Observer.Observe('half_xml', Format(Result, 0, 9));
        D := 0;
        Result := D / Dec;
        Observer.Observe('zero', Format(Result));
        D := 1;
        Result := D / Dec;
        Observer.Observe('one_ms', Format(Result, 0, 9));
        Dec := 0.5;
        D := 30000;
        Result := D / Dec;
        Observer.Observe('divisor_half', Format(Result, 0, 9));
        Dec := -60000.0;
        D := 26820000;
        Result := D / Dec;
        Observer.Observe('negative_divisor', Format(Result, 0, 9));
        Observer.Expect('big', '447');
        Observer.Expect('half', '0.5');
        Observer.Expect('half_xml', '0.5');
        Observer.Expect('zero', '0');
        Observer.Expect('one_ms', '0.000016666666666667');
        Observer.Expect('divisor_half', '60000');
        Observer.Expect('negative_divisor', '-447');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedByDecimal_IntoOtherTypes()
    var
        D: Duration;
        Dec: Decimal;
        Int: Integer;
        Big: BigInteger;
        Dur: Duration;
        Observer: Codeunit "Probe Observer";
    begin
        D := 26820000;
        Dec := 60000.0;
        Int := D / Dec;
        Observer.Observe('into_integer', Format(Int));
        Big := D / Dec;
        Observer.Observe('into_biginteger', Format(Big));
        D := 30000;
        asserterror Int := D / Dec;
        Observer.ObserveError('half_into_integer');
        asserterror Dur := D / Dec;
        Observer.ObserveError('half_into_duration');
        D := 26820000;
        Dur := D / Dec;
        Observer.Observe('into_duration', Format(Dur, 0, 9));
        Observer.Expect('into_integer', '447');
        Observer.Expect('into_biginteger', '447');
        Observer.Expect('half_into_integer|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int32.');
        Observer.Expect('half_into_integer|code', 'ConversionCast');
        Observer.Expect('half_into_duration|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 0.5 to System.Int64.');
        Observer.Expect('half_into_duration|code', 'ConversionCast');
        Observer.Expect('into_duration', 'P0DT0H0M0.447S');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedByZeroDecimal_Error()
    var
        D: Duration;
        Zero: Decimal;
        Result: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        D := 26820000;
        asserterror Result := D / Zero;
        Observer.ObserveError('zero_decimal');
        Observer.Expect('zero_decimal|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_decimal|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedByZeroDecimal_ZeroDuration()
    var
        D: Duration;
        Zero: Decimal;
        Result: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        D := 0;
        asserterror Result := D / Zero;
        Observer.ObserveError('zero_over_zero');
        Observer.Expect('zero_over_zero|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_over_zero|code', 'AL:DivideByZero');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_DividedByZeroInteger_Error()
    var
        D: Duration;
        ZeroInt: Integer;
        Result: Decimal;
        Observer: Codeunit "Probe Observer";
    begin
        D := 26820000;
        asserterror Result := D / ZeroInt;
        Observer.ObserveError('zero_integer');
        Observer.Expect('zero_integer|text', 'Attempted to divide by zero.');
        Observer.Expect('zero_integer|code', 'AL:DivideByZero');
        Observer.Verify();
    end;
}
