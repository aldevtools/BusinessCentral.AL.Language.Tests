// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-data-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 70907
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Time +/- BigInteger (compile-risky: kept in its own file), BigInteger small, negative and above Int32
// BC versions: 29 (27 and 28 by CI)

codeunit 70907 "LT P170 Time BigInt"
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
    local procedure TryPlus(T: Time; B: BigInteger; var R: Text)
    begin
        R := Format(T + B, 0, 9);
    end;

    [TryFunction]
    local procedure TryMinus(T: Time; B: BigInteger; var R: Text)
    begin
        R := Format(T - B, 0, 9);
    end;

    [Test]
    procedure P170_TimePlusMinusBigInteger()
    var
        Observer: Codeunit "Probe Observer";
        Big: BigInteger;
        R: Text;
        Ok: Boolean;
    begin
        Big := 1500;
        Ok := TryPlus(120000T, Big, R);
        Observer.Observe('plus_1500', Res(Ok, R));
        Ok := TryMinus(120000T, Big, R);
        Observer.Observe('minus_1500', Res(Ok, R));
        Big := -1500;
        Ok := TryPlus(120000T, Big, R);
        Observer.Observe('plus_neg', Res(Ok, R));
        Big := 0;
        Ok := TryMinus(120000T, Big, R);
        Observer.Observe('minus_0', Res(Ok, R));
        Big := 2147483647;
        Big := Big * 2;
        Ok := TryPlus(120000T, Big, R);
        Observer.Observe('plus_over_int32', Res(Ok, R));
        Ok := TryMinus(120000T, Big, R);
        Observer.Observe('minus_over_int32', Res(Ok, R));
        Big := 1500;
        Ok := TryPlus(0T, Big, R);
        Observer.Observe('plus_undefined', Res(Ok, R));
        Ok := TryMinus(0T, Big, R);
        Observer.Observe('minus_undefined', Res(Ok, R));
        Observer.Expect('plus_1500', 'ok:12:00:01.5');
        Observer.Expect('minus_1500', 'ok:11:59:58.5');
        Observer.Expect('plus_neg', 'ok:11:59:58.5');
        Observer.Expect('minus_0', 'ok:12:00:00');
        Observer.Expect('plus_over_int32', 'error:Overflow under conversion of System.Int64 value 4294967294 to System.Int32.|ConversionCast');
        Observer.Expect('minus_over_int32', 'error:Overflow under conversion of System.Int64 value -4294967294 to System.Int32.|ConversionCast');
        Observer.Expect('plus_undefined', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Expect('minus_undefined', 'error:Adding to an undefined (0T) time.|InvalidTime');
        Observer.Verify();
    end;
}
