// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: <Comma,x> with <Second dec.>, <Second dec> and <Thousands> in a custom format string of a Time, a DateTime and a Duration,
//   with 0, 50, 123 and 999 milliseconds. A format string BC refuses is observed as err:<error code>.
//   (AL Runner issue 7033: '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.><Comma,.>' of a Time.)
// Facts (29.0): on a Time and a DateTime <Comma,x> writes nothing. Right after <Second dec.> or <Second dec> it sets the character that code
//   writes before the fraction (59,123); before <Second dec.>, alone or with <Thousands> it changes nothing. <Second dec.> writes nothing when
//   there are no milliseconds and drops trailing zeros (.05). On a Duration every one of these strings fails with InvalidFormatString.
// BC versions: 27.5, 28.5, 29.0

codeunit 95485 "DT Format Second Dec Comma"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormatInner(V: Variant; F: Text; var Result: Text)
    begin
        Result := Format(V, 0, F);
    end;

    local procedure TryFormat(V: Variant; F: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if not TryFormatInner(V, F, Result) then
            exit('err:' + GetLastErrorCode());
        exit(Result);
    end;

    local procedure ObserveStrings(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    begin
        Observer.Observe(Name + ' app', TryFormat(V, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.><Comma,.>'));
        Observer.Observe(Name + ' dec. comma ,', TryFormat(V, '<Seconds,2><Second dec.><Comma,,>'));
        Observer.Observe(Name + ' comma ; before dec.', TryFormat(V, '<Comma,;><Seconds,2><Second dec.>'));
        Observer.Observe(Name + ' comma . alone', TryFormat(V, '<Seconds,2><Comma,.>'));
        Observer.Observe(Name + ' dec comma ,', TryFormat(V, '<Seconds,2><Second dec><Comma,,>'));
        Observer.Observe(Name + ' thousands comma ,', TryFormat(V, '<Seconds,2>:<Thousands><Comma,,>'));
        Observer.Observe(Name + ' thousands,3 comma ,', TryFormat(V, '<Thousands,3><Comma,,>'));
    end;

    [Test]
    procedure Time_Format_SecondDecComma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStrings(Observer, '14:30:59.123', 143059.123T);
        ObserveStrings(Observer, '00:00:00.000', 000000T);
        ObserveStrings(Observer, '09:05:00.050', 090500.05T);
        Observer.Expect('14:30:59.123 app', '143059.123');
        Observer.Expect('14:30:59.123 dec. comma ,', '59,123');
        Observer.Expect('14:30:59.123 comma ; before dec.', '59.123');
        Observer.Expect('14:30:59.123 comma . alone', '59');
        Observer.Expect('14:30:59.123 dec comma ,', '59,123');
        Observer.Expect('14:30:59.123 thousands comma ,', '59:123');
        Observer.Expect('14:30:59.123 thousands,3 comma ,', '123');
        Observer.Expect('00:00:00.000 app', '000000');
        Observer.Expect('00:00:00.000 dec. comma ,', '00');
        Observer.Expect('00:00:00.000 comma ; before dec.', '00');
        Observer.Expect('00:00:00.000 comma . alone', '00');
        Observer.Expect('00:00:00.000 dec comma ,', '00');
        Observer.Expect('00:00:00.000 thousands comma ,', '00:0');
        Observer.Expect('00:00:00.000 thousands,3 comma ,', '  0');
        Observer.Expect('09:05:00.050 app', '090500.05');
        Observer.Expect('09:05:00.050 dec. comma ,', '00,05');
        Observer.Expect('09:05:00.050 comma ; before dec.', '00.05');
        Observer.Expect('09:05:00.050 comma . alone', '00');
        Observer.Expect('09:05:00.050 dec comma ,', '00,05');
        Observer.Expect('09:05:00.050 thousands comma ,', '00:50');
        Observer.Expect('09:05:00.050 thousands,3 comma ,', ' 50');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_SecondDecComma_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStrings(Observer, '14:30:59.000', 143059T);
        ObserveStrings(Observer, '23:59:59.999', 235959.999T);
        Observer.Expect('14:30:59.000 app', '143059');
        Observer.Expect('14:30:59.000 dec. comma ,', '59');
        Observer.Expect('14:30:59.000 comma ; before dec.', '59');
        Observer.Expect('14:30:59.000 comma . alone', '59');
        Observer.Expect('14:30:59.000 dec comma ,', '59');
        Observer.Expect('14:30:59.000 thousands comma ,', '59:0');
        Observer.Expect('14:30:59.000 thousands,3 comma ,', '  0');
        Observer.Expect('23:59:59.999 app', '235959.999');
        Observer.Expect('23:59:59.999 dec. comma ,', '59,999');
        Observer.Expect('23:59:59.999 comma ; before dec.', '59.999');
        Observer.Expect('23:59:59.999 comma . alone', '59');
        Observer.Expect('23:59:59.999 dec comma ,', '59,999');
        Observer.Expect('23:59:59.999 thousands comma ,', '59:999');
        Observer.Expect('23:59:59.999 thousands,3 comma ,', '999');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_SecondDecComma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStrings(Observer, 'DT 14:30:59.123', CreateDateTime(DMY2Date(5, 3, 2024), 143059.123T));
        ObserveStrings(Observer, 'DT 09:05:00.050', CreateDateTime(DMY2Date(5, 3, 2024), 090500.05T));
        ObserveStrings(Observer, 'DT 14:30:59.000', CreateDateTime(DMY2Date(5, 3, 2024), 143059T));
        Observer.Expect('DT 14:30:59.123 app', '143059.123');
        Observer.Expect('DT 14:30:59.123 dec. comma ,', '59,123');
        Observer.Expect('DT 14:30:59.123 comma ; before dec.', '59.123');
        Observer.Expect('DT 14:30:59.123 comma . alone', '59');
        Observer.Expect('DT 14:30:59.123 dec comma ,', '59,123');
        Observer.Expect('DT 14:30:59.123 thousands comma ,', '59:123');
        Observer.Expect('DT 14:30:59.123 thousands,3 comma ,', '123');
        Observer.Expect('DT 09:05:00.050 app', '090500.05');
        Observer.Expect('DT 09:05:00.050 dec. comma ,', '00,05');
        Observer.Expect('DT 09:05:00.050 comma ; before dec.', '00.05');
        Observer.Expect('DT 09:05:00.050 comma . alone', '00');
        Observer.Expect('DT 09:05:00.050 dec comma ,', '00,05');
        Observer.Expect('DT 09:05:00.050 thousands comma ,', '00:50');
        Observer.Expect('DT 09:05:00.050 thousands,3 comma ,', '050');
        Observer.Expect('DT 14:30:59.000 app', '143059');
        Observer.Expect('DT 14:30:59.000 dec. comma ,', '59');
        Observer.Expect('DT 14:30:59.000 comma ; before dec.', '59');
        Observer.Expect('DT 14:30:59.000 comma . alone', '59');
        Observer.Expect('DT 14:30:59.000 dec comma ,', '59');
        Observer.Expect('DT 14:30:59.000 thousands comma ,', '59:0');
        Observer.Expect('DT 14:30:59.000 thousands,3 comma ,', '000');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format_SecondDecComma()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        D := 52259123; // 14:30:59.123
        ObserveStrings(Observer, 'Duration 52259123', D);
        D := 50;
        ObserveStrings(Observer, 'Duration 50', D);
        Observer.Expect('Duration 52259123 app', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 dec. comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 comma ; before dec.', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 comma . alone', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 dec comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 thousands comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 52259123 thousands,3 comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 app', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 dec. comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 comma ; before dec.', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 comma . alone', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 dec comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 thousands comma ,', 'err:InvalidFormatString');
        Observer.Expect('Duration 50 thousands,3 comma ,', 'err:InvalidFormatString');
        Observer.Verify();
    end;
}
