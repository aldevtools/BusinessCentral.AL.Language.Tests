// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope. Format with a format string that contains <Comma,...>.
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained codeunit 67357
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: <Comma,,> before <Decimals>; <Comma,.> with <Integer Thousand> and <Decimals,3>; <Comma,.> on a Decimal, a BigInteger, a Duration and a DateTime. A format string BC rejects is recorded as error text and code.
//   No locale-dependent value: the session language is set to 1033 for the run and restored.
//   Corpus issue 576 item 3.
// BC versions: 27, 28, 29

codeunit 67357 "LT FCM Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFormat(Value: Variant; Fmt: Text; var Result: Text)
    begin
        Result := Format(Value, 0, Fmt);
    end;

    local procedure Run(Name: Text; Value: Variant; Fmt: Text; var Observer: Codeunit "Probe Observer")
    var
        Result: Text;
    begin
        ClearLastError();
        Result := '';
        if TryFormat(Value, Fmt, Result) then
            Observer.Observe(Name, 'ok:' + Result)
        else begin
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
    end;

    [Test]
    procedure Format_CommaBeforeDecimals_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        WholeDecimal: Decimal;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        WholeDecimal := 1000;
        Run('whole_decimal', WholeDecimal, '<Integer><Comma,,><Decimals>', Observer);
        Run('whole_decimal_dot', WholeDecimal, '<Integer><Comma,.><Decimals>', Observer);
        Run('big', 1234567.891, '<Integer><Comma,,><Decimals>', Observer);
        Run('small', 0.5, '<Integer><Comma,,><Decimals>', Observer);
        Run('negative', -1234.5, '<Integer><Comma,,><Decimals>', Observer);
        Run('whole', 1000, '<Integer><Comma,,><Decimals>', Observer);
        Run('thousand_big', 1234567.891, '<Integer Thousand><Comma,,><Decimals>', Observer);
        Run('dot_big', 1234567.891, '<Integer><Comma,.><Decimals>', Observer);
        Run('dot_whole', 1000, '<Integer><Comma,.><Decimals>', Observer);
        GlobalLanguage(Saved);
        Observer.Expect('whole_decimal', 'ok:1000');
        Observer.Expect('whole_decimal_dot', 'ok:1000');
        Observer.Expect('big', 'ok:1234567.891');
        Observer.Expect('small', 'ok:0.5');
        Observer.Expect('negative', 'ok:1234.5');
        Observer.Expect('whole', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,,><Decimals>|InvalidFormatString');
        Observer.Expect('thousand_big', 'ok:1,234,567.891');
        Observer.Expect('dot_big', 'ok:1234567.891');
        Observer.Expect('dot_whole', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,.><Decimals>|InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaWithThousandAndWidth_Decimal()
    var
        Observer: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        Run('thousand_dot_dec3', 1234567.891, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_whole', 1234567, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_small', 0.5, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('thousand_dot_dec3_negative', -1234.5, '<Integer Thousand><Comma,.><Decimals,3>', Observer);
        Run('width10', 1234.5, '<Integer,10><Comma,.><Decimals,3>', Observer);
        Run('thousand_width12', 1234567.891, '<Integer Thousand,12><Comma,.><Decimals,3>', Observer);
        Run('sign', -1234.5, '<Sign><Integer Thousand><Comma,.><Decimals,2>', Observer);
        Run('padded', 1234.5, '<Integer,8><Filler Character,0><Comma,.><Decimals,2>', Observer);
        GlobalLanguage(Saved);
        Observer.Expect('thousand_dot_dec3', 'ok:1,234,567***');
        Observer.Expect('thousand_dot_dec3_whole', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.><Decimals,3>|InvalidFormatString');
        Observer.Expect('thousand_dot_dec3_small', 'ok:0.50');
        Observer.Expect('thousand_dot_dec3_negative', 'ok:1,234.50');
        Observer.Expect('width10', 'ok:      1234.50');
        Observer.Expect('thousand_width12', 'ok:   1,234,567***');
        Observer.Expect('sign', 'ok:-1,234.5');
        Observer.Expect('padded', 'ok:00001234.5');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaOnOtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        BigValue: BigInteger;
        Dur: Duration;
        Stamp: DateTime;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        BigValue := 1234567890123L;
        Dur := 3723000;
        Stamp := CreateDateTime(DMY2Date(15, 6, 2026), 134500T);
        Run('biginteger', BigValue, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('biginteger_comma', BigValue, '<Integer><Comma,,><Decimals>', Observer);
        Run('duration', Dur, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('duration_comma', Dur, '<Integer><Comma,,><Decimals>', Observer);
        Run('datetime', Stamp, '<Integer Thousand><Comma,.><Decimals>', Observer);
        Run('datetime_comma', Stamp, '<Integer><Comma,,><Decimals>', Observer);
        GlobalLanguage(Saved);
        Observer.Expect('biginteger', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('biginteger_comma', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,,><Decimals>|InvalidFormatString');
        Observer.Expect('duration', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('duration_comma', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,,><Decimals>|InvalidFormatString');
        Observer.Expect('datetime', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.><Decimals>|InvalidFormatString');
        Observer.Expect('datetime_comma', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer><Comma,,><Decimals>|InvalidFormatString');
        Observer.Verify();
    end;

    [Test]
    procedure Format_CommaWithoutDecimals_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
        BigValue: BigInteger;
        Dur: Duration;
        Stamp: DateTime;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        BigValue := 1234567890123L;
        Dur := 3723000;
        Stamp := CreateDateTime(DMY2Date(15, 6, 2026), 134500T);
        Run('biginteger_integer', BigValue, '<Integer Thousand><Comma,.>', Observer);
        Run('biginteger_only', BigValue, '<Comma,.>', Observer);
        Run('duration_integer', Dur, '<Integer Thousand><Comma,.>', Observer);
        Run('duration_only', Dur, '<Comma,.>', Observer);
        Run('datetime_integer', Stamp, '<Integer Thousand><Comma,.>', Observer);
        Run('datetime_only', Stamp, '<Comma,.>', Observer);
        GlobalLanguage(Saved);
        Observer.Expect('biginteger_integer', 'ok:1,234,567,890,123');
        Observer.Expect('biginteger_only', 'ok:');
        Observer.Expect('duration_integer', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.>|InvalidFormatString');
        Observer.Expect('duration_only', 'ok:');
        Observer.Expect('datetime_integer', 'error:An invalid field or attribute has been specified for the ''Format'' property.\\<Integer Thousand><Comma,.>|InvalidFormatString');
        Observer.Expect('datetime_only', 'ok:');
        Observer.Verify();
    end;

    local procedure WidthThree(Lang: Integer; var Observer: Codeunit "Probe Observer")
    var
        Inputs: List of [Text];
        Input: Text;
        Value: Decimal;
        Saved: Integer;
    begin
        Inputs.AddRange('0', '-0', '1234', '-1234', '0.5', '-0.5', '1234.5', '-1234.5', '0.005', '-0.005', '1.234', '-1.234', '1.235', '1.995', '99999', '-99999', '1.2300', '999999999999999.99');
        Saved := GlobalLanguage();
        GlobalLanguage(Lang);
        foreach Input in Inputs do begin
            Evaluate(Value, Input, 9);
            Run('d_' + Input, Value, '<Sign><Integer><Decimals,3><Comma,.>', Observer);
        end;
        GlobalLanguage(Saved);
    end;

    [Test]
    procedure Format_SignIntegerDecimalsWidth3Comma_Lang1033()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WidthThree(1033, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_SignIntegerDecimalsWidth3Comma_Lang2055()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WidthThree(2055, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_SignIntegerDecimalsWidth3Comma_Lang1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WidthThree(1031, Observer);
        Observer.Finish();
    end;
}
