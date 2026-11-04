// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), test codeunits 72691 and 72692 (P85)
// Probe: written against BC 29 (P85); the facts are measured later on a local BC 29 service tier.
// Facts: Duration to Integer, BigInteger, Decimal (also negative and beyond the Integer range), Time - Time, Duration arithmetic and Format
// BC versions: 29

codeunit 72691 "LT P85 Duration Convert"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Mk(A: Integer; M: Integer): BigInteger
    var
        B: BigInteger;
    begin
        B := A;
        exit(B * M);
    end;

    [TryFunction]
    local procedure TryToInt(V: Duration; var I: Integer)
    begin
        I := V;
    end;

    [TryFunction]
    local procedure TryToBig(V: Duration; var B: BigInteger)
    begin
        B := V;
    end;

    [TryFunction]
    local procedure TryToDec(V: Duration; var D: Decimal)
    begin
        D := V;
    end;

    [TryFunction]
    local procedure TryVarToInt(V: Variant; var I: Integer)
    begin
        I := V;
    end;

    local procedure ToInt(V: Duration): Text
    var
        I: Integer;
    begin
        if TryToInt(V, I) then
            exit('ok:' + Format(I));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ToBig(V: Duration): Text
    var
        B: BigInteger;
    begin
        if TryToBig(V, B) then
            exit('ok:' + Format(B));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure ToDec(V: Duration): Text
    var
        D: Decimal;
    begin
        if TryToDec(V, D) then
            exit('ok:' + Format(D));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure VarToInt(V: Variant): Text
    var
        I: Integer;
    begin
        if TryVarToInt(V, I) then
            exit('ok:' + Format(I));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Duration_To_Integer_InRange()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        D := 0;
        Observer.Observe('zero', ToInt(D));
        D := 1;
        Observer.Observe('one', ToInt(D));
        D := 1500;
        Observer.Observe('1500', ToInt(D));
        D := 86400000;
        Observer.Observe('day_ms', ToInt(D));
        D := -1;
        Observer.Observe('minus_one', ToInt(D));
        D := -86400000;
        Observer.Observe('minus_day', ToInt(D));
        D := 2147483647;
        Observer.Observe('int_max', ToInt(D));
        D := Mk(-2147483647, 1) - 1;
        Observer.Observe('int_min', ToInt(D));
        Observer.Expect('zero', 'ok:0');
        Observer.Expect('one', 'ok:1');
        Observer.Expect('1500', 'ok:1500');
        Observer.Expect('day_ms', 'ok:86400000');
        Observer.Expect('minus_one', 'ok:-1');
        Observer.Expect('minus_day', 'ok:-86400000');
        Observer.Expect('int_max', 'ok:2147483647');
        Observer.Expect('int_min', 'ok:-2147483648');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_To_Integer_BeyondRange()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        B: BigInteger;
    begin
        B := Mk(2147483647, 1) + 1;
        D := B;
        Observer.Observe('int_max_plus_1', ToInt(D));
        B := Mk(-2147483647, 1) - 2;
        D := B;
        Observer.Observe('int_min_minus_1', ToInt(D));
        B := Mk(65536, 65536);
        D := B;
        Observer.Observe('2_pow_32', ToInt(D));
        B := Mk(2147483647, 2147483647) * 2;
        D := B;
        Observer.Observe('big_max', ToInt(D));
        Observer.Observe('big_max_as_big', ToBig(D));
        asserterror Observer.Observe('big_max_as_dec', ToDec(D));
        Observer.ObserveError('af126');
        asserterror Observer.Observe('big_max_format', Format(D));
        Observer.ObserveError('af128');
        Observer.Expect('int_max_plus_1', 'error:Overflow under conversion of System.Int64 value 2147483648 to System.Int32.|ConversionCast');
        Observer.Expect('int_min_minus_1', 'error:Overflow under conversion of System.Int64 value -2147483649 to System.Int32.|ConversionCast');
        Observer.Expect('2_pow_32', 'error:Overflow under conversion of System.Int64 value 4294967296 to System.Int32.|ConversionCast');
        Observer.Expect('big_max', 'error:Overflow under conversion of System.Int64 value 9223372028264841218 to System.Int32.|ConversionCast');
        Observer.Expect('big_max_as_big', 'ok:9223372028264841218');
        Observer.Expect('af126|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 9,223,372,028,264,841,220. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af126|code', 'OutsidePermittedRange');
        Observer.Expect('af128|text', 'Arithmetic operation resulted in an overflow.');
        Observer.Expect('af128|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_To_BigInteger_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        B: BigInteger;
    begin
        D := 0;
        Observer.Observe('zero_big', ToBig(D));
        Observer.Observe('zero_dec', ToDec(D));
        D := 1500;
        Observer.Observe('1500_big', ToBig(D));
        Observer.Observe('1500_dec', ToDec(D));
        D := -1500;
        Observer.Observe('neg_big', ToBig(D));
        Observer.Observe('neg_dec', ToDec(D));
        B := Mk(50000, 100000);
        D := B;
        Observer.Observe('5e9_big', ToBig(D));
        Observer.Observe('5e9_dec', ToDec(D));
        B := Mk(-50000, 100000);
        D := B;
        Observer.Observe('neg5e9_big', ToBig(D));
        Observer.Observe('neg5e9_dec', ToDec(D));
        Observer.Expect('zero_big', 'ok:0');
        Observer.Expect('zero_dec', 'ok:0');
        Observer.Expect('1500_big', 'ok:1500');
        Observer.Expect('1500_dec', 'ok:1,500');
        Observer.Expect('neg_big', 'ok:-1500');
        Observer.Expect('neg_dec', 'ok:-1,500');
        Observer.Expect('5e9_big', 'ok:5000000000');
        Observer.Expect('5e9_dec', 'ok:5,000,000,000');
        Observer.Expect('neg5e9_big', 'ok:-5000000000');
        Observer.Expect('neg5e9_dec', 'ok:-5,000,000,000');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Via_Variant()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        B: BigInteger;
        V: Variant;
        Dec: Decimal;
    begin
        D := 1500;
        V := D;
        Observer.Observe('is_duration', Format(V.IsDuration()));
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Observer.Observe('is_biginteger', Format(V.IsBigInteger()));
        Observer.Observe('is_decimal', Format(V.IsDecimal()));
        Observer.Observe('var_to_int', VarToInt(V));
        B := Mk(50000, 100000);
        D := B;
        V := D;
        Observer.Observe('var_big_to_int', VarToInt(V));
        D := -7;
        V := D;
        Observer.Observe('var_neg_to_int', VarToInt(V));
        V := 3000;
        D := V;
        Observer.Observe('int_variant_to_duration', Format(D) + '|' + Format(D, 0, 9));
        Dec := 2500.7;
        asserterror D := Dec;
        Observer.ObserveError('af186');
        Observer.Observe('decimal_to_duration', Format(D, 0, 9));
        Dec := -2500.7;
        asserterror D := Dec;
        Observer.ObserveError('af191');
        Observer.Observe('neg_decimal_to_duration', Format(D, 0, 9));
        Observer.Expect('is_duration', 'Yes');
        Observer.Expect('is_integer', 'No');
        Observer.Expect('is_biginteger', 'No');
        Observer.Expect('is_decimal', 'No');
        Observer.Expect('var_to_int', 'ok:1500');
        Observer.Expect('var_big_to_int', 'error:The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Overflow');
        Observer.Expect('var_neg_to_int', 'ok:-7');
        Observer.Expect('int_variant_to_duration', '3 seconds|P0DT0H0M3.0S');
        Observer.Expect('af186|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 2500.7 to System.Int64.');
        Observer.Expect('af186|code', 'ConversionCast');
        Observer.Expect('decimal_to_duration', 'P0DT0H0M3.0S');
        Observer.Expect('af191|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value -2500.7 to System.Int64.');
        Observer.Expect('af191|code', 'ConversionCast');
        Observer.Expect('neg_decimal_to_duration', 'P0DT0H0M3.0S');
        Observer.Verify();
    end;

    [Test]
    procedure TimeMinusTime_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        StartTime: Time;
        EndTime: Time;
        I: Integer;
        B: BigInteger;
        Dec: Decimal;
        D: Duration;
    begin
        StartTime := 100000T;
        EndTime := 103000T;
        D := EndTime - StartTime;
        I := EndTime - StartTime;
        B := EndTime - StartTime;
        Dec := EndTime - StartTime;
        Observer.Observe('duration', Format(D, 0, 9));
        Observer.Observe('int', Format(I));
        Observer.Observe('big', Format(B));
        Observer.Observe('dec', Format(Dec));
        I := StartTime - EndTime;
        Observer.Observe('negative_int', Format(I));
        EndTime := StartTime;
        I := EndTime - StartTime;
        Observer.Observe('same_int', Format(I));
        EndTime := 235959.999T;
        StartTime := 000000T;
        I := EndTime - StartTime;
        Observer.Observe('full_day_int', Format(I));
        Observer.Observe('full_day_dec', Format(EndTime - StartTime, 0, 9));
        Observer.Expect('duration', 'P0DT0H30M0.0S');
        Observer.Expect('int', '1800000');
        Observer.Expect('big', '1800000');
        Observer.Expect('dec', '1,800,000');
        Observer.Expect('negative_int', '-1800000');
        Observer.Expect('same_int', '0');
        Observer.Expect('full_day_int', '86399999');
        Observer.Expect('full_day_dec', '86399999');
        Observer.Verify();
    end;

    [Test]
    procedure DateTimeMinusDateTime_To_Integer()
    var
        Observer: Codeunit "Probe Observer";
        A: DateTime;
        B: DateTime;
        BI: BigInteger;
        D: Duration;
        I: Integer;
    begin
        A := CreateDateTime(DMY2Date(1, 1, 2020), 000000T);
        B := CreateDateTime(DMY2Date(2, 1, 2020), 000000T);
        D := B - A;
        BI := B - A;
        Observer.Observe('one_day_duration', Format(D, 0, 9));
        Observer.Observe('one_day_big', Format(BI));
        Observer.Observe('one_day_int', ToInt(B - A));
        B := CreateDateTime(DMY2Date(1, 1, 2021), 000000T);
        BI := B - A;
        Observer.Observe('one_year_big', Format(BI));
        Observer.Observe('one_year_int', ToInt(B - A));
        BI := A - B;
        Observer.Observe('neg_year_big', Format(BI));
        Observer.Observe('neg_year_int', ToInt(A - B));
        Observer.Expect('one_day_duration', 'P1DT0H0M0.0S');
        Observer.Expect('one_day_big', '86400000');
        Observer.Expect('one_day_int', 'ok:86400000');
        Observer.Expect('one_year_big', '31622400000');
        Observer.Expect('one_year_int', 'error:Overflow under conversion of System.Int64 value 31622400000 to System.Int32.|ConversionCast');
        Observer.Expect('neg_year_big', '-31622400000');
        Observer.Expect('neg_year_int', 'error:Overflow under conversion of System.Int64 value -31622400000 to System.Int32.|ConversionCast');
        Observer.Verify();
    end;
}

codeunit 72692 "LT P85 Duration Arith"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Mk(A: Integer; M: Integer): BigInteger
    var
        B: BigInteger;
    begin
        B := A;
        exit(B * M);
    end;

    [Test]
    procedure Duration_Arithmetic()
    var
        Observer: Codeunit "Probe Observer";
        D1: Duration;
        D2: Duration;
        D: Duration;
        Dec: Decimal;
    begin
        D1 := 90000;
        D2 := 30000;
        D := D1 + D2;
        Observer.Observe('add', Format(D, 0, 9));
        D := D1 - D2;
        Observer.Observe('sub', Format(D, 0, 9));
        D := D2 - D1;
        Observer.Observe('sub_negative', Format(D, 0, 9));
        D := D1 * 2;
        Observer.Observe('mul', Format(D, 0, 9));
        D := D1 / 4;
        Observer.Observe('div', Format(D, 0, 9));
        asserterror D := D1 / 7;
        Observer.ObserveError('af291');
        Observer.Observe('div_fraction', Format(D, 0, 9));
        Dec := D1 / D2;
        Observer.Observe('ratio_dec', Format(Dec));
        Observer.Observe('div_op', Format(D1 div 7));
        Observer.Observe('mod_op', Format(D1 mod 7));
        Observer.Observe('compare_gt', Format(D1 > D2));
        Observer.Observe('compare_eq', Format(D1 = 90000));
        D := D1 * -1;
        Observer.Observe('unary_minus', Format(D, 0, 9));
        Observer.Expect('add', 'P0DT0H2M0.0S');
        Observer.Expect('sub', 'P0DT0H1M0.0S');
        Observer.Expect('sub_negative', '-P0DT0H1M0.0S');
        Observer.Expect('mul', 'P0DT0H3M0.0S');
        Observer.Expect('div', 'P0DT0H0M22.5S');
        Observer.Expect('af291|text', 'Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 12857.1428571428571 to System.Int64.');
        Observer.Expect('af291|code', 'ConversionCast');
        Observer.Expect('div_fraction', 'P0DT0H0M22.5S');
        Observer.Expect('ratio_dec', '3');
        Observer.Expect('div_op', '12,857');
        Observer.Expect('mod_op', '1');
        Observer.Expect('compare_gt', 'Yes');
        Observer.Expect('compare_eq', 'Yes');
        Observer.Expect('unary_minus', '-P0DT0H1M30.0S');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        i: Integer;
    begin
        D := 0;
        Observer.Observe('zero', Format(D));
        D := 999;
        Observer.Observe('999ms', Format(D));
        D := 1000;
        Observer.Observe('1s', Format(D));
        D := 61000;
        Observer.Observe('61s', Format(D));
        D := 3600000;
        Observer.Observe('1h', Format(D));
        D := 90061001;
        Observer.Observe('1d_1h_1m_1s_1ms', Format(D));
        D := -1000;
        Observer.Observe('minus_1s', Format(D));
        D := -90061001;
        Observer.Observe('neg_long', Format(D));
        D := Mk(50000, 100000);
        Observer.Observe('5e9', Format(D));
        D := 1500;
        for i := 0 to 2 do
            Observer.Observe('f' + Format(i), Format(D, 0, i));
        Observer.Expect('zero', '');
        Observer.Expect('999ms', '999 milliseconds');
        Observer.Expect('1s', '1 second');
        Observer.Expect('61s', '1 minute 1 second');
        Observer.Expect('1h', '1 hour');
        Observer.Expect('1d_1h_1m_1s_1ms', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('minus_1s', '-1 second');
        Observer.Expect('neg_long', '-1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('5e9', '57 days 20 hours 53 minutes 20 seconds');
        Observer.Expect('f0', '1 second 500 milliseconds');
        Observer.Expect('f1', '1 second 500 milliseconds');
        Observer.Expect('f2', '1 6 500 9');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        Observer.Observe('1h', Format(Evaluate(D, '1 hour')) + '|' + Format(D, 0, 9));
        Observer.Observe('1h30m', Format(Evaluate(D, '1 hour 30 minutes')) + '|' + Format(D, 0, 9));
        Observer.Observe('2d', Format(Evaluate(D, '2 days')) + '|' + Format(D, 0, 9));
        Observer.Observe('number', Format(Evaluate(D, '1500')) + '|' + Format(D, 0, 9));
        Observer.Observe('negative_number', Format(Evaluate(D, '-1500')) + '|' + Format(D, 0, 9));
        Observer.Observe('big_number', Format(Evaluate(D, '5000000000')) + '|' + Format(D, 0, 9));
        Observer.Observe('text_garbage', Format(Evaluate(D, 'abc')) + '|' + Format(D, 0, 9));
        Observer.Observe('decimal', Format(Evaluate(D, '1.5')) + '|' + Format(D, 0, 9));
        Observer.Expect('1h', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('1h30m', 'Yes|P0DT1H30M0.0S');
        Observer.Expect('2d', 'Yes|P2DT0H0M0.0S');
        Observer.Expect('number', 'Yes|P62DT12H0M0.0S');
        Observer.Expect('negative_number', 'Yes|-P62DT12H0M0.0S');
        Observer.Expect('big_number', 'Yes|P208333333DT8H0M0.0S');
        Observer.Expect('text_garbage', 'No|P208333333DT8H0M0.0S');
        Observer.Expect('decimal', 'Yes|P0DT1H30M0.0S');
        Observer.Verify();
    end;

    [Test]
    procedure TimePlusDuration()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        D: Duration;
        T2: Time;
    begin
        T := 100000T;
        D := 3600000;
        T2 := T + D;
        Observer.Observe('plus_1h', Format(T2, 0, 9));
        D := -3600000;
        T2 := T + D;
        Observer.Observe('plus_neg_1h', Format(T2, 0, 9));
        D := 86400000;
        T2 := T + D;
        Observer.Observe('plus_day_wraps', Format(T2, 0, 9));
        D := Mk(50000, 100000);
        asserterror T2 := T + D;
        Observer.ObserveError('af373');
        Observer.Observe('plus_beyond_int', Format(T2, 0, 9));
        Observer.Expect('plus_1h', '11:00:00');
        Observer.Expect('plus_neg_1h', '09:00:00');
        Observer.Expect('plus_day_wraps', '10:00:00');
        Observer.Expect('af373|text', 'Overflow under conversion of System.Int64 value 5000000000 to System.Int32.');
        Observer.Expect('af373|code', 'ConversionCast');
        Observer.Expect('plus_beyond_int', '10:00:00');
        Observer.Verify();
    end;
}
