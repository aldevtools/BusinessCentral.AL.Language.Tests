// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Format: the seconds fraction of a Duration in format 9 has its trailing zeros trimmed
// Facts: Format(Duration, 0, N): format 9 for many millisecond values, formats 0 to 8 for one value
// BC versions: 29 (27 and 28 by CI)

codeunit 70096 "LT PnA Fmt Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryF(V: Variant; N: Integer; var R: Text)
    begin
        R := Format(V, 0, N);
    end;

    local procedure F(V: Variant; N: Integer): Text
    var
        R: Text;
    begin
        if TryF(V, N, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Dur(var Observer: Codeunit "Probe Observer"; Name: Text; Ms: BigInteger)
    var
        D: Duration;
    begin
        D := Ms;
        Observer.Observe(Name + '-n9', F(D, 9));
    end;

    [Test]
    procedure Format9_Values()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Dur(Observer, '0', 0);
        Dur(Observer, '5', 5);
        Dur(Observer, '12', 12);
        Dur(Observer, '100', 100);
        Dur(Observer, '120', 120);
        Dur(Observer, '500', 500);
        Dur(Observer, '999', 999);
        Dur(Observer, '1000', 1000);
        Dur(Observer, '1500', 1500);
        Dur(Observer, '1050', 1050);
        Dur(Observer, '60000', 60000);
        Dur(Observer, '61005', 61005);
        Dur(Observer, '3600000', 3600000);
        Dur(Observer, '3600500', 3600500);
        Dur(Observer, '86400000', 86400000);
        Dur(Observer, '90061001', 90061001);
        Dur(Observer, 'minus-1500', -1500);
        Dur(Observer, 'minus-5', -5);
        Observer.Expect('0-n9', 'P0DT0H0M0.0S');
        Observer.Expect('5-n9', 'P0DT0H0M0.005S');
        Observer.Expect('12-n9', 'P0DT0H0M0.012S');
        Observer.Expect('100-n9', 'P0DT0H0M0.1S');
        Observer.Expect('120-n9', 'P0DT0H0M0.12S');
        Observer.Expect('500-n9', 'P0DT0H0M0.5S');
        Observer.Expect('999-n9', 'P0DT0H0M0.999S');
        Observer.Expect('1000-n9', 'P0DT0H0M1.0S');
        Observer.Expect('1500-n9', 'P0DT0H0M1.5S');
        Observer.Expect('1050-n9', 'P0DT0H0M1.05S');
        Observer.Expect('60000-n9', 'P0DT0H1M0.0S');
        Observer.Expect('61005-n9', 'P0DT0H1M1.005S');
        Observer.Expect('3600000-n9', 'P0DT1H0M0.0S');
        Observer.Expect('3600500-n9', 'P0DT1H0M0.5S');
        Observer.Expect('86400000-n9', 'P1DT0H0M0.0S');
        Observer.Expect('90061001-n9', 'P1DT1H1M1.001S');
        Observer.Expect('minus-1500-n9', '-P0DT0H0M1.5S');
        Observer.Expect('minus-5-n9', '-P0DT0H0M0.005S');
        Observer.Verify();
    end;

    [Test]
    procedure FormatNumbers_ForOneValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        i: Integer;
    begin
        D := 90061500;
        for i := 0 to 9 do
            Observer.Observe('n' + Format(i), F(D, i));
        Observer.Observe('default', Format(D));
        D := 1500;
        Observer.Observe('1500-n0', F(D, 0));
        Observer.Observe('1500-n1', F(D, 1));
        Observer.Observe('1500-n2', F(D, 2));
        Observer.Expect('n0', '1 day 1 hour 1 minute 1 second 500 milliseconds');
        Observer.Expect('n1', '1 day 1 hour 1 minute 1 second 500 milliseconds');
        Observer.Expect('n2', '1 0 1 2 1 4 1 6 500 9');
        Observer.Expect('n3', 'error:Standard format number 3 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n4', 'error:Standard format number 4 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n5', 'error:Standard format number 5 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n6', 'error:Standard format number 6 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n7', 'error:Standard format number 7 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n8', 'error:Standard format number 8 does not exist for the type ''Variant''.|InvalidStandardFormat');
        Observer.Expect('n9', 'P1DT1H1M1.5S');
        Observer.Expect('default', '1 day 1 hour 1 minute 1 second 500 milliseconds');
        Observer.Expect('1500-n0', '1 second 500 milliseconds');
        Observer.Expect('1500-n1', '1 second 500 milliseconds');
        Observer.Expect('1500-n2', '1 6 500 9');
        Observer.Verify();
    end;
}
