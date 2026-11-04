// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/time/time-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 73935
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: "Time + Integer, Time - Time" (Tests-SCM-Service ...: LoadFields, TestField with an ErrorInfo, WordMergeDataItem, Time and Option arithmetic, issue 41)
// Facts: Time + Integer (inside the day and past midnight), Time - Integer, Time - Time as Duration (positive, negative, zero), the type of the result through a Variant, undefined Time (0T)
// BC versions: 29 (27 and 28 by CI)

codeunit 73935 "LT PnF Time Arithmetic"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryPlus(T: Time; N: Integer; var R: Text)
    begin
        R := Format(T + N, 0, 9);
    end;

    [TryFunction]
    local procedure TryMinusInt(T: Time; N: Integer; var R: Text)
    begin
        R := Format(T - N, 0, 9);
    end;

    [TryFunction]
    local procedure TryMinusTime(A: Time; B: Time; var R: Text)
    var
        V: Variant;
    begin
        V := A - B;
        R := Format(V) + '|' + Format(V.IsDuration()) + '|' + Format(V.IsInteger()) + '|' + Format(V.IsTime());
    end;

    [TryFunction]
    local procedure TryMinusTimeDuration(A: Time; B: Time; var R: Text)
    var
        D: Duration;
    begin
        D := A - B;
        R := Format(D) + '|' + Format(D, 0, 9) + '|' + Format(D / 1);
    end;

    local procedure Res(Ok: Boolean; R: Text): Text
    begin
        if Ok then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure TimePlusMinusInteger()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryPlus(235959T, 2000, R);
        Observer.Observe('plus_over_midnight', Res(Ok, R));
        Ok := TryPlus(120000T, 2000, R);
        Observer.Observe('plus_inside_day', Res(Ok, R));
        Ok := TryPlus(120000T, 0, R);
        Observer.Observe('plus_zero', Res(Ok, R));
        Ok := TryPlus(120000T, -2000, R);
        Observer.Observe('plus_negative', Res(Ok, R));
        Ok := TryPlus(000000T, -1000, R);
        Observer.Observe('plus_negative_before_midnight', Res(Ok, R));
        Ok := TryPlus(0T, 2000, R);
        Observer.Observe('plus_undefined', Res(Ok, R));
        Ok := TryMinusInt(120000T, 2000, R);
        Observer.Observe('minus_inside_day', Res(Ok, R));
        Ok := TryMinusInt(000001T, 2000, R);
        Observer.Observe('minus_before_midnight', Res(Ok, R));
        Ok := TryMinusInt(0T, 2000, R);
        Observer.Observe('minus_undefined', Res(Ok, R));
        Observer.Expect('plus_over_midnight', '00:00:01');
        Observer.Expect('plus_inside_day', '12:00:02');
        Observer.Expect('plus_zero', '12:00:00');
        Observer.Expect('plus_negative', '11:59:58');
        Observer.Expect('plus_negative_before_midnight', '23:59:59');
        Observer.Expect('plus_undefined', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Expect('minus_inside_day', '11:59:58');
        Observer.Expect('minus_before_midnight', '23:59:59');
        Observer.Expect('minus_undefined', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Verify();
    end;

    [Test]
    procedure TimeMinusTime()
    var
        Observer: Codeunit "Probe Observer";
        R: Text;
        Ok: Boolean;
    begin
        Ok := TryMinusTime(120000T, 110000T, R);
        Observer.Observe('minus_positive_variant', Res(Ok, R));
        Ok := TryMinusTime(110000T, 120000T, R);
        Observer.Observe('minus_negative_variant', Res(Ok, R));
        Ok := TryMinusTime(120000T, 120000T, R);
        Observer.Observe('minus_zero_variant', Res(Ok, R));
        Ok := TryMinusTimeDuration(120000T, 110000T, R);
        Observer.Observe('minus_positive_duration', Res(Ok, R));
        Ok := TryMinusTimeDuration(110000T, 120000T, R);
        Observer.Observe('minus_negative_duration', Res(Ok, R));
        Ok := TryMinusTimeDuration(120000T, 0T, R);
        Observer.Observe('minus_undefined_right', Res(Ok, R));
        Ok := TryMinusTimeDuration(0T, 120000T, R);
        Observer.Observe('minus_undefined_left', Res(Ok, R));
        Observer.Observe('literal', Format(120000T - 110000T));
        Observer.Expect('minus_positive_variant', '3600000|No|Yes|No');
        Observer.Expect('minus_negative_variant', '-3600000|No|Yes|No');
        Observer.Expect('minus_zero_variant', '0|No|Yes|No');
        Observer.Expect('minus_positive_duration', '1 hour|P0DT1H0M0.0S|3,600,000');
        Observer.Expect('minus_negative_duration', '-1 hour|-P0DT1H0M0.0S|-3,600,000');
        Observer.Expect('minus_undefined_right', 'error:Subtracting an undefined (0T) time.|InvalidTime');
        Observer.Expect('minus_undefined_left', 'error:Subtracting from an undefined (0T) time.|InvalidTime');
        Observer.Expect('literal', '3600000');
        Observer.Verify();
    end;

    [Test]
    procedure TimeComparisonsAndMilliseconds()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 120000T;
        Observer.Observe('plus_1000_format', Format(T + 1000));
        Observer.Observe('plus_60000_format', Format(T + 60000));
        Observer.Observe('plus_3600000_format', Format(T + 3600000));
        Observer.Observe('plus_86400000_format', Format(T + 86400000));
        Observer.Observe('later', Format(T + 1000 > T));
        Observer.Expect('plus_1000_format', '12:00:01 PM');
        Observer.Expect('plus_60000_format', '12:01:00 PM');
        Observer.Expect('plus_3600000_format', ' 1:00:00 PM');
        Observer.Expect('plus_86400000_format', '12:00:00 PM');
        Observer.Expect('later', 'Yes');
        Observer.Verify();
    end;
}
