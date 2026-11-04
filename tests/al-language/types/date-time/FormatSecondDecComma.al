// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-format-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: observed on the corpus CI (BC on Linux, legs 27.5, 28.5 and 29.0); every literal asserted below is what BC produced.
// Topic: <Comma,x> with <Second dec.>, <Second dec> and <Thousands> in a custom format string of a Time, a DateTime and a Duration,
//   with 0, 50, 123 and 999 milliseconds. A format string BC refuses is observed as err:<error code>.
//   (AL Runner issue 7033: '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.><Comma,.>' of a Time.)
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
        Observer.Finish();
    end;

    [Test]
    procedure Time_Format_SecondDecComma_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStrings(Observer, '14:30:59.000', 143059T);
        ObserveStrings(Observer, '23:59:59.999', 235959.999T);
        Observer.Finish();
    end;

    [Test]
    procedure DateTime_Format_SecondDecComma()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ObserveStrings(Observer, 'DT 14:30:59.123', CreateDateTime(DMY2Date(5, 3, 2024), 143059.123T));
        ObserveStrings(Observer, 'DT 09:05:00.050', CreateDateTime(DMY2Date(5, 3, 2024), 090500.05T));
        ObserveStrings(Observer, 'DT 14:30:59.000', CreateDateTime(DMY2Date(5, 3, 2024), 143059T));
        Observer.Finish();
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
        Observer.Finish();
    end;
}
