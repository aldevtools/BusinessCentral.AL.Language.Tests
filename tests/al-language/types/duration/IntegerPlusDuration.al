// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/duration/duration-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: an Integer plus a Duration (issue #184 item 30): the value (Format 9), the type of the result through a Variant, negative and zero operands, the commuted result against Duration + Integer.
// BC versions: 29 (27 and 28 by CI)

codeunit 74456 "LT DurInt IntPlusDur"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure IntegerPlusDuration_Value_Result()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
        R: Duration;
    begin
        D := 1500;
        I := 500;
        R := I + D;
        Observer.Observe('sum_ms', Format(R, 0, 9));
        R := 0 + D;
        Observer.Observe('zero_plus', Format(R, 0, 9));
        I := -2000;
        R := I + D;
        Observer.Observe('negative_plus', Format(R, 0, 9));
        I := 500;
        Observer.Observe('commutes', Format(I + D = D + I));
        Observer.Observe('format_default', Format(I + D));
        Observer.Expect('sum_ms', 'P0DT0H0M2.0S');
        Observer.Expect('zero_plus', 'P0DT0H0M1.5S');
        Observer.Expect('negative_plus', '-P0DT0H0M0.5S');
        Observer.Expect('commutes', 'Yes');
        Observer.Expect('format_default', '2000');
        Observer.Verify();
    end;

    [Test]
    procedure IntegerPlusDuration_ResultType_Result()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
        V: Variant;
    begin
        D := 1500;
        I := 500;
        V := I + D;
        Observer.Observe('is_duration', Format(V.IsDuration()));
        Observer.Observe('is_integer', Format(V.IsInteger()));
        Observer.Observe('is_biginteger', Format(V.IsBigInteger()));
        Observer.Observe('is_decimal', Format(V.IsDecimal()));
        Observer.Expect('is_duration', 'No');
        Observer.Expect('is_integer', 'No');
        Observer.Expect('is_biginteger', 'Yes');
        Observer.Expect('is_decimal', 'No');
        Observer.Verify();
    end;
}
