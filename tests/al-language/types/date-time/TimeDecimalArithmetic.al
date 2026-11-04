// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 70906
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Time +/- whole and fractional Decimal variables, Time +/- Decimal literal, Time - 0T, 0T - Time, wrap around midnight with a Decimal
// BC versions: 29 (27 and 28 by CI)

codeunit 70906 "LT P170 Time Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit('ok:' + R);
        exit('error:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryPlus(T: Time; D: Decimal; var R: Text)
    begin
        R := Format(T + D, 0, 9);
    end;

    [TryFunction]
    local procedure TryMinus(T: Time; D: Decimal; var R: Text)
    begin
        R := Format(T - D, 0, 9);
    end;

    [TryFunction]
    local procedure TryMinusTime(A: Time; B: Time; var R: Text)
    begin
        R := Format(A - B);
    end;

    [Test]
    procedure P170_TimePlusMinusDecimal_Whole()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryPlus(120000T, 1500.0, R);
        Observer.Observe('plus_1500', Res(Ok, R));
        Ok := TryPlus(120000T, 0.0, R);
        Observer.Observe('plus_0', Res(Ok, R));
        Ok := TryPlus(120000T, -1500.0, R);
        Observer.Observe('plus_neg_1500', Res(Ok, R));
        Ok := TryPlus(235959T, 2000.0, R);
        Observer.Observe('plus_wrap', Res(Ok, R));
        Ok := TryMinus(120000T, 1500.0, R);
        Observer.Observe('minus_1500', Res(Ok, R));
        Ok := TryMinus(000001T, 2000.0, R);
        Observer.Observe('minus_wrap', Res(Ok, R));
        Ok := TryPlus(120000T, 1500.00000000001, R);
        Observer.Observe('plus_tiny_fraction', Res(Ok, R));
        Ok := TryPlus(120000T, 3000000000.0, R);
        Observer.Observe('plus_over_int32', Res(Ok, R));
        Ok := TryPlus(0T, 1500.0, R);
        Observer.Observe('plus_undefined', Res(Ok, R));
        Observer.Expect('plus_1500', 'ok:12:00:01.5');
        Observer.Expect('plus_0', 'ok:12:00:00');
        Observer.Expect('plus_neg_1500', 'ok:11:59:58.5');
        Observer.Expect('plus_wrap', 'ok:00:00:01');
        Observer.Expect('minus_1500', 'ok:11:59:58.5');
        Observer.Expect('minus_wrap', 'ok:23:59:59');
        Observer.Expect('plus_tiny_fraction', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 1500.00000000001 to System.Int32.|ConversionCast');
        Observer.Expect('plus_over_int32', 'error:Overflow under conversion of Microsoft.Dynamics.Nav.Runtime.Decimal18 value 3000000000.0 to System.Int32.|ConversionCast');
        Observer.Expect('plus_undefined', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TimePlusMinusDecimal_Literal()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 120000T;
        Observer.Observe('plus_literal', Format(T + 1500.0, 0, 9));
        Observer.Observe('minus_literal', Format(T - 1500.0, 0, 9));
        Observer.Observe('plus_int_literal', Format(T + 1500, 0, 9));
        Observer.Observe('same_as_int', Format((T + 1500.0) = (T + 1500)));
        Observer.Expect('plus_literal', '12:00:01.5');
        Observer.Expect('minus_literal', '11:59:58.5');
        Observer.Expect('plus_int_literal', '12:00:01.5');
        Observer.Expect('same_as_int', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P170_TimeMinusUndefinedTime()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryMinusTime(120000T, 0T, R);
        Observer.Observe('time_minus_0t', Res(Ok, R));
        Ok := TryMinusTime(0T, 120000T, R);
        Observer.Observe('0t_minus_time', Res(Ok, R));
        Ok := TryMinusTime(0T, 0T, R);
        Observer.Observe('0t_minus_0t', Res(Ok, R));
        Ok := TryMinusTime(120000T, 120000T, R);
        Observer.Observe('same_minus_same', Res(Ok, R));
        Observer.Expect('time_minus_0t', 'error:Subtracting an undefined (0T) time.|InvalidTime');
        Observer.Expect('0t_minus_time', 'error:Subtracting from an undefined (0T) time.|InvalidTime');
        Observer.Expect('0t_minus_0t', 'ok:0');
        Observer.Expect('same_minus_same', 'ok:0');
        Observer.Verify();
    end;
}
