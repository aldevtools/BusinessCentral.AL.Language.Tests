// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope. Format with a format string that contains <Comma,...>.
// Fixtures used: Probe Observer (69160) from the AL Language Coverage Tests app; self-contained codeunit 67357
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: <Comma,,> before <Decimals>; <Comma,.> with <Integer Thousand> and <Decimals,3>; <Comma,.> on a Decimal, a BigInteger, a Duration and a DateTime. A format string BC rejects is recorded as error text and code.
//   No locale-dependent value: the session language is set to 1033 for the run and restored.
//   Corpus issue 576 item 3.
//   Format(Decimal, 0, '<Sign><Integer><Decimals,3><Comma,.>') (width 3 includes the point): two places zero padded, no grouping, a minus only for a nonzero
//   value, '***' when the fraction does not fit in width 3 (no rounding), identical under GlobalLanguage 1033, 2055 and 1031 (runtime PR 6138).
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
        Observer.Expect('d_0', 'ok:0.00');
        Observer.Expect('d_-0', 'ok:0.00');
        Observer.Expect('d_1234', 'ok:1234.00');
        Observer.Expect('d_-1234', 'ok:-1234.00');
        Observer.Expect('d_0.5', 'ok:0.50');
        Observer.Expect('d_-0.5', 'ok:-0.50');
        Observer.Expect('d_1234.5', 'ok:1234.50');
        Observer.Expect('d_-1234.5', 'ok:-1234.50');
        Observer.Expect('d_0.005', 'ok:0***');
        Observer.Expect('d_-0.005', 'ok:-0***');
        Observer.Expect('d_1.234', 'ok:1***');
        Observer.Expect('d_-1.234', 'ok:-1***');
        Observer.Expect('d_1.235', 'ok:1***');
        Observer.Expect('d_1.995', 'ok:1***');
        Observer.Expect('d_99999', 'ok:99999.00');
        Observer.Expect('d_-99999', 'ok:-99999.00');
        Observer.Expect('d_1.2300', 'ok:1.23');
        Observer.Expect('d_999999999999999.99', 'ok:999999999999999.99');
        Observer.Verify();
    end;

    [Test]
    procedure Format_SignIntegerDecimalsWidth3Comma_Lang2055()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WidthThree(2055, Observer);
        Observer.Expect('d_0', 'ok:0.00');
        Observer.Expect('d_-0', 'ok:0.00');
        Observer.Expect('d_1234', 'ok:1234.00');
        Observer.Expect('d_-1234', 'ok:-1234.00');
        Observer.Expect('d_0.5', 'ok:0.50');
        Observer.Expect('d_-0.5', 'ok:-0.50');
        Observer.Expect('d_1234.5', 'ok:1234.50');
        Observer.Expect('d_-1234.5', 'ok:-1234.50');
        Observer.Expect('d_0.005', 'ok:0***');
        Observer.Expect('d_-0.005', 'ok:-0***');
        Observer.Expect('d_1.234', 'ok:1***');
        Observer.Expect('d_-1.234', 'ok:-1***');
        Observer.Expect('d_1.235', 'ok:1***');
        Observer.Expect('d_1.995', 'ok:1***');
        Observer.Expect('d_99999', 'ok:99999.00');
        Observer.Expect('d_-99999', 'ok:-99999.00');
        Observer.Expect('d_1.2300', 'ok:1.23');
        Observer.Expect('d_999999999999999.99', 'ok:999999999999999.99');
        Observer.Verify();
    end;

    [Test]
    procedure Format_SignIntegerDecimalsWidth3Comma_Lang1031()
    var
        Observer: Codeunit "Probe Observer";
    begin
        WidthThree(1031, Observer);
        Observer.Expect('d_0', 'ok:0.00');
        Observer.Expect('d_-0', 'ok:0.00');
        Observer.Expect('d_1234', 'ok:1234.00');
        Observer.Expect('d_-1234', 'ok:-1234.00');
        Observer.Expect('d_0.5', 'ok:0.50');
        Observer.Expect('d_-0.5', 'ok:-0.50');
        Observer.Expect('d_1234.5', 'ok:1234.50');
        Observer.Expect('d_-1234.5', 'ok:-1234.50');
        Observer.Expect('d_0.005', 'ok:0***');
        Observer.Expect('d_-0.005', 'ok:-0***');
        Observer.Expect('d_1.234', 'ok:1***');
        Observer.Expect('d_-1.234', 'ok:-1***');
        Observer.Expect('d_1.235', 'ok:1***');
        Observer.Expect('d_1.995', 'ok:1***');
        Observer.Expect('d_99999', 'ok:99999.00');
        Observer.Expect('d_-99999', 'ok:-99999.00');
        Observer.Expect('d_1.2300', 'ok:1.23');
        Observer.Expect('d_999999999999999.99', 'ok:999999999999999.99');
        Observer.Verify();
    end;

    // ---- <Standard Format,N> with a <Comma,x> element (al-runner issue 6792): the reporter's values under en-US (GlobalLanguage 1033)
    // and de-DE (1031), with and without a leading <Precision,A:B>, other Standard Format numbers, another character, <Comma> without one,
    // the element first, a Length, and an Integer value.
    local procedure StdComma(Prefix: Text; Fmt: Text; Lang: Integer; Length: Integer; var Observer: Codeunit "Probe Observer")
    var
        Inputs: List of [Text];
        Input: Text;
        Value: Decimal;
        Saved: Integer;
        Result: Text;
    begin
        Inputs.AddRange('0', '0.04', '-0.04', '0.05', '-1.45', '6.38', '999.94', '999.95', '1234.5', '1234567.89');
        Saved := GlobalLanguage();
        GlobalLanguage(Lang);
        foreach Input in Inputs do begin
            Evaluate(Value, Input, 9);
            if Length = 0 then
                Run(Prefix + Input, Value, Fmt, Observer)
            else begin
                ClearLastError();
                Result := '';
                if TryFormatLength(Value, Length, Fmt, Result) then
                    Observer.Observe(Prefix + Input, 'ok:[' + Result + ']')
                else begin
                    Observer.Observe(Prefix + Input, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
                    ClearLastError();
                end;
            end;
        end;
        GlobalLanguage(Saved);
    end;

    [TryFunction]
    local procedure TryFormatLength(Value: Decimal; Length: Integer; Fmt: Text; var Result: Text)
    begin
        Result := Format(Value, Length, Fmt);
    end;

    [Test]
    procedure Format_Prec11Std0CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,0><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Std0CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Standard Format,0><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std0CommaComma_De()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,0><Comma,,>', 1031, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Std0CommaComma_De()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Standard Format,0><Comma,,>', 1031, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std0CommaDot_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,0><Comma,.>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Std0CommaDot_De()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Standard Format,0><Comma,.>', 1031, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec22Std0CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,2:2><Standard Format,0><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec02Std0CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,0:2><Standard Format,0><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std1CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,1><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std2CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,2><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std3CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,3><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std4CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Precision,1:1><Standard Format,4><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Std9CommaComma_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('v_', '<Standard Format,9><Comma,,>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std0CommaOther_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('semi_', '<Precision,1:1><Standard Format,0><Comma,;>', 1033, 0, Observer);
        StdComma('bare_', '<Precision,1:1><Standard Format,0><Comma>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_CommaFirstPrec11Std0_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('first_', '<Comma,,><Precision,1:1><Standard Format,0>', 1033, 0, Observer);
        StdComma('mid_', '<Precision,1:1><Comma,,><Standard Format,0>', 1033, 0, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Prec11Std0CommaComma_Length12_En()
    var
        Observer: Codeunit "Probe Observer";
    begin
        StdComma('len_', '<Precision,1:1><Standard Format,0><Comma,,>', 1033, 12, Observer);
        Observer.Finish();
    end;

    [Test]
    procedure Format_Std0CommaComma_OtherTypes_En()
    var
        Observer: Codeunit "Probe Observer";
        IntValue: Integer;
        BigValue: BigInteger;
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        IntValue := 1234;
        BigValue := 1234567;
        Run('int_prec', IntValue, '<Precision,1:1><Standard Format,0><Comma,,>', Observer);
        Run('int', IntValue, '<Standard Format,0><Comma,,>', Observer);
        Run('int_zero', 0, '<Precision,1:1><Standard Format,0><Comma,,>', Observer);
        Run('big_prec', BigValue, '<Precision,1:1><Standard Format,0><Comma,,>', Observer);
        Run('big', BigValue, '<Standard Format,0><Comma,,>', Observer);
        GlobalLanguage(Saved);
        Observer.Finish();
    end;
}
