// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Duration plus / minus an Integer (issue #184 item 30): the value (Format 9, milliseconds), the type of the result seen through a Variant (IsDuration / IsInteger / IsBigInteger / IsDecimal), negative and zero operands, assignment to Duration and BigInteger. Duration + Duration is pinned in types/lt-filter-enum-relation-duration-guid/D_Duration.al.
// BC versions: 29 (27 and 28 by CI)

codeunit 74455 "LT DurInt DurPlusInt"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DurationPlusInteger_Value_Result()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
        R: Duration;
    begin
        D := 1500;
        I := 500;
        R := D + I;
        Observer.Observe('sum_ms', Format(R, 0, 9));
        R := D + 0;
        Observer.Observe('plus_zero', Format(R, 0, 9));
        I := -2000;
        R := D + I;
        Observer.Observe('plus_negative', Format(R, 0, 9));
        R := D - 500;
        Observer.Observe('minus_literal', Format(R, 0, 9));
        I := 2500;
        R := D - I;
        Observer.Observe('minus_to_negative', Format(R, 0, 9));
        Observer.Observe('sum_equals_2000', Format(D + 500 = 2000));
        Observer.Observe('sum_format_default', Format(D + 500));
        Observer.Expect('sum_ms', 'P0DT0H0M2.0S');
        Observer.Expect('plus_zero', 'P0DT0H0M1.5S');
        Observer.Expect('plus_negative', '-P0DT0H0M0.5S');
        Observer.Expect('minus_literal', 'P0DT0H0M1.0S');
        Observer.Expect('minus_to_negative', '-P0DT0H0M1.0S');
        Observer.Expect('sum_equals_2000', 'Yes');
        Observer.Expect('sum_format_default', '2000');
        Observer.Verify();
    end;

    [Test]
    procedure DurationPlusInteger_ResultType_Result()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
        V: Variant;
    begin
        D := 1500;
        I := 500;
        V := D + I;
        Observer.Observe('plus_is_duration', Format(V.IsDuration()));
        Observer.Observe('plus_is_integer', Format(V.IsInteger()));
        Observer.Observe('plus_is_biginteger', Format(V.IsBigInteger()));
        Observer.Observe('plus_is_decimal', Format(V.IsDecimal()));
        V := D - I;
        Observer.Observe('minus_is_duration', Format(V.IsDuration()));
        Observer.Observe('minus_is_integer', Format(V.IsInteger()));
        Observer.Observe('minus_is_biginteger', Format(V.IsBigInteger()));
        V := D + 1;
        Observer.Observe('plus_literal_is_duration', Format(V.IsDuration()));
        Observer.Expect('plus_is_duration', 'No');
        Observer.Expect('plus_is_integer', 'No');
        Observer.Expect('plus_is_biginteger', 'Yes');
        Observer.Expect('plus_is_decimal', 'No');
        Observer.Expect('minus_is_duration', 'No');
        Observer.Expect('minus_is_integer', 'No');
        Observer.Expect('minus_is_biginteger', 'Yes');
        Observer.Expect('plus_literal_is_duration', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure DurationPlusInteger_ToBigInteger_Result()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        B: BigInteger;
    begin
        D := 60000;
        B := D + 1;
        Observer.Observe('big_plus_one', Format(B));
        B := D - 60001;
        Observer.Observe('big_minus', Format(B));
        Observer.Expect('big_plus_one', '60001');
        Observer.Expect('big_minus', '-1');
        Observer.Verify();
    end;
}
