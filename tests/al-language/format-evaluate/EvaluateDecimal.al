// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/evaluate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own codeunit 67522
// Probe: Evaluate of a Text into a Decimal ('100', decimal and thousands separators, signs, blanks, exponent, garbage) and the conversion of a Variant that holds a Text into a Decimal. Assigning a Text to a Decimal directly does not compile (must-not-compile case 0501) (issue 580 item 5).
// Writer QR (2026-10-21), QR_* tests: punctuation other than letters, digits and % _ - . , + $ (a slash as in an option name, ':', '#', quotes,
//   brackets, currency signs other than $, doubled signs, letters with umlauts), signs and exponents with format number 9, and white space
//   other than a plain space (tab, line breaks, no-break space, narrow no-break space, full-width and Arabic-Indic digits); the statement
//   form of a few (error text and code) and Integer / BigInteger with the same odd forms.
//   BC (27.5, 28.5, 29.0 alike): every punctuation form is rejected (variable kept) except '5$', '$-5', '-$5' (read with no number and 0,
//   rejected with 9); with 9 a trailing minus, parentheses, '$' and '100 -' are rejected, '+', '1E-2', '1e+2', '+.5' are read; tab, CR and LF
//   around the number are dropped with 0 and 9, a no-break space (160 or 8239) anywhere rejects, full-width and Arabic-Indic digits reject.
// BC versions: 27+

codeunit 67522 "LT Evaluate Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Try(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        Ok := Evaluate(D, Input);
        Observer.Observe(Name, '[' + Input + '] ' + Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    [Test]
    procedure Evaluate_PlainAndSeparators()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'plain', '100');
        Try(Observer, 'decimal_point', '100.5');
        Try(Observer, 'thousands_comma', '1,000');
        Try(Observer, 'thousands_and_point', '1,000.5');
        Try(Observer, 'dot_thousands_comma_decimal', '1.000,5');
        Try(Observer, 'comma_decimal', '100,5');
        Try(Observer, 'space_thousands', '1 000');
        Try(Observer, 'misplaced_thousands', '1,0,0');
        Try(Observer, 'leading_point', '.5');
        Try(Observer, 'trailing_point', '5.');
        Try(Observer, 'many_decimals', '0.123456789012345678901');
        Try(Observer, 'large', '79228162514264337593543950335');
        Try(Observer, 'too_large', '792281625142643375935439503350');
        Observer.Expect('plain', '[100] Yes 100');
        Observer.Expect('decimal_point', '[100.5] Yes 100.5');
        Observer.Expect('thousands_comma', '[1,000] Yes 1000');
        Observer.Expect('thousands_and_point', '[1,000.5] Yes 1000.5');
        Observer.Expect('dot_thousands_comma_decimal', '[1.000,5] No -1');
        Observer.Expect('comma_decimal', '[100,5] Yes 1005');
        Observer.Expect('space_thousands', '[1 000] No -1');
        Observer.Expect('misplaced_thousands', '[1,0,0] Yes 100');
        Observer.Expect('leading_point', '[.5] Yes 0.5');
        Observer.Expect('trailing_point', '[5.] Yes 5');
        Observer.Expect('many_decimals', '[0.123456789012345678901] Yes 0.123456789012345678');
        Observer.Expect('large', '[79228162514264337593543950335] No -1');
        Observer.Expect('too_large', '[792281625142643375935439503350] No -1');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_SignsBlanksAndGarbage()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Try(Observer, 'plus', '+100');
        Try(Observer, 'minus', '-100');
        Try(Observer, 'trailing_minus', '100-');
        Try(Observer, 'parentheses', '(100)');
        Try(Observer, 'surrounding_blanks', '  100  ');
        Try(Observer, 'trailing_blank', '100 ');
        Try(Observer, 'empty', '');
        Try(Observer, 'blank', ' ');
        Try(Observer, 'letters', 'abc');
        Try(Observer, 'trailing_letters', '100abc');
        Try(Observer, 'exponent_lower', '1e3');
        Try(Observer, 'exponent_upper', '1E3');
        Try(Observer, 'hex', '0x10');
        Try(Observer, 'percent', '100%');
        Try(Observer, 'two_points', '1.2.3');
        Try(Observer, 'zero', '0');
        Try(Observer, 'negative_zero', '-0');
        Try(Observer, 'leading_zeros', '007');
        Observer.Expect('plus', '[+100] Yes 100');
        Observer.Expect('minus', '[-100] Yes -100');
        Observer.Expect('trailing_minus', '[100-] Yes -100');
        Observer.Expect('parentheses', '[(100)] Yes -100');
        Observer.Expect('surrounding_blanks', '[  100  ] Yes 100');
        Observer.Expect('trailing_blank', '[100 ] Yes 100');
        Observer.Expect('empty', '[] No -1');
        Observer.Expect('blank', '[ ] No -1');
        Observer.Expect('letters', '[abc] No -1');
        Observer.Expect('trailing_letters', '[100abc] No -1');
        Observer.Expect('exponent_lower', '[1e3] Yes 1000');
        Observer.Expect('exponent_upper', '[1E3] Yes 1000');
        Observer.Expect('hex', '[0x10] No -1');
        Observer.Expect('percent', '[100%] No -1');
        Observer.Expect('two_points', '[1.2.3] No -1');
        Observer.Expect('zero', '[0] Yes 0');
        Observer.Expect('negative_zero', '[-0] Yes 0');
        Observer.Expect('leading_zeros', '[007] Yes 7');
        Observer.Verify();
    end;


    [Test]
    procedure Evaluate_FailureRaisesWithoutReturnValue()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        asserterror Evaluate(D, 'abc');
        Observer.ObserveError('letters');
        asserterror Evaluate(D, '');
        Observer.ObserveError('empty');
        asserterror Evaluate(D, '1.2.3');
        Observer.ObserveError('two_points');
        Observer.Expect('letters|text', 'The value "abc" can''t be evaluated into type Decimal.');
        Observer.Expect('letters|code', 'Evaluate');
        Observer.Expect('empty|text', 'The value "" can''t be evaluated into type Decimal.');
        Observer.Expect('empty|code', 'Evaluate');
        Observer.Expect('two_points|text', 'The value "1.2.3" can''t be evaluated into type Decimal.');
        Observer.Expect('two_points|code', 'Evaluate');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure ToDecimal(V: Variant; var D: Decimal)
    begin
        D := V;
    end;

    local procedure Convert(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        ClearLastError();
        Ok := ToDecimal(V, D);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(D, 0, 9) + ' [' + GetLastErrorText() + ']');
    end;

    [Test]
    procedure Variant_HoldingText_ConvertsToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        T: Text;
    begin
        T := '100';
        Convert(Observer, 'plain', T);
        T := '100.5';
        Convert(Observer, 'decimal_point', T);
        T := '1,000.5';
        Convert(Observer, 'thousands_and_point', T);
        T := '1,000';
        Convert(Observer, 'thousands_comma', T);
        T := '100,5';
        Convert(Observer, 'comma_decimal', T);
        T := 'abc';
        Convert(Observer, 'letters', T);
        T := '';
        Convert(Observer, 'empty', T);
        T := ' 100 ';
        Convert(Observer, 'blanks', T);
        T := '-100';
        Convert(Observer, 'negative', T);
        Observer.Expect('plain', 'Yes 100 []');
        Observer.Expect('decimal_point', 'Yes 100.5 []');
        Observer.Expect('thousands_and_point', 'Yes 1000.5 []');
        Observer.Expect('thousands_comma', 'Yes 1000 []');
        Observer.Expect('comma_decimal', 'Yes 1005 []');
        Observer.Expect('letters', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Expect('empty', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Expect('blanks', 'Yes 100 []');
        Observer.Expect('negative', 'Yes -100 []');
        Observer.Verify();
    end;

    [Test]
    procedure Variant_HoldingCode_ConvertsToDecimal()
    var
        Observer: Codeunit "Probe Observer";
        C: Code[20];
    begin
        C := '100';
        Convert(Observer, 'plain', C);
        C := '1,000.5';
        Convert(Observer, 'thousands_and_point', C);
        C := 'ABC';
        Convert(Observer, 'letters', C);
        Observer.Expect('plain', 'Yes 100 []');
        Observer.Expect('thousands_and_point', 'Yes 1000.5 []');
        Observer.Expect('letters', 'No -1 [The expression Variant cannot be type-converted to a Decimal value.]');
        Observer.Verify();
    end;

    [Test]
    procedure Evaluate_IntoOtherNumericTypes()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        Ok: Boolean;
    begin
        Ok := Evaluate(I, '100');
        Observer.Observe('integer_plain', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(I, '100.5');
        Observer.Observe('integer_decimal_point', Format(Ok));
        Ok := Evaluate(I, '1,000');
        Observer.Observe('integer_thousands', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(B, '1,000');
        Observer.Observe('biginteger_thousands', Format(Ok) + ' ' + Format(B));
        Observer.Expect('integer_plain', 'Yes 100');
        Observer.Expect('integer_decimal_point', 'No');
        Observer.Expect('integer_thousands', 'Yes 1000');
        Observer.Expect('biginteger_thousands', 'Yes 1000');
        Observer.Verify();
    end;

    // Writer QR (2026-10-21): the forms below are what the runtime did not read yet. The punctuation family (characters other than letters,
    // digits and % _ - . , + $), signs and exponents with format number 9, and white space other than a plain space. Each line observes
    // the return value and the variable after the call (set to -1 before), with format number 0 or 9 as the test name says.
    // Tokens in a name: {TAB} {LF} {CR} = Char 9, 10, 13; {NBSP} = 160; {NNBSP} = 8239 (narrow no-break space);
    // {FW1} {FW2} = full-width digits one and two (65297, 65298); {AR1} = Arabic-Indic digit one (1633).
    local procedure QrText(Input: Text): Text
    var
        C: Text[1];
    begin
        C[1] := 9;
        Input := Input.Replace('{TAB}', C);
        C[1] := 10;
        Input := Input.Replace('{LF}', C);
        C[1] := 13;
        Input := Input.Replace('{CR}', C);
        C[1] := 160;
        Input := Input.Replace('{NBSP}', C);
        C[1] := 8239;
        Input := Input.Replace('{NNBSP}', C);
        C[1] := 65297;
        Input := Input.Replace('{FW1}', C);
        C[1] := 65298;
        Input := Input.Replace('{FW2}', C);
        C[1] := 1633;
        Input := Input.Replace('{AR1}', C);
        exit(Input);
    end;

    local procedure TryQr(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text; Number: Integer)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        Ok := Evaluate(D, QrText(Input), Number);
        Observer.Observe(Name, Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    local procedure TryQr0(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    begin
        TryQr(Observer, Name, Input, 0);
    end;

    local procedure TryQr9(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    begin
        TryQr(Observer, Name, Input, 9);
    end;

    local procedure TryQrNoNumber(var Observer: Codeunit "Probe Observer"; Name: Text; Input: Text)
    var
        D: Decimal;
        Ok: Boolean;
    begin
        D := -1;
        Ok := Evaluate(D, QrText(Input));
        Observer.Observe(Name, Format(Ok) + ' ' + Format(D, 0, 9));
    end;

    [Test]
    procedure QR_Evaluate_Punctuation_NoNumber()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQrNoNumber(Observer, 'New/Updated', 'New/Updated');
        TryQrNoNumber(Observer, 'a/b', 'a/b');
        TryQrNoNumber(Observer, '1/2', '1/2');
        TryQrNoNumber(Observer, '12:30', '12:30');
        TryQrNoNumber(Observer, '#1', '#1');
        TryQrNoNumber(Observer, '1#', '1#');
        TryQrNoNumber(Observer, 'A&B', 'A&B');
        TryQrNoNumber(Observer, '1=1', '1=1');
        TryQrNoNumber(Observer, '''1''', '''1''');
        TryQrNoNumber(Observer, '"1"', '"1"');
        TryQrNoNumber(Observer, '1;2', '1;2');
        TryQrNoNumber(Observer, '[1]', '[1]');
        TryQrNoNumber(Observer, '{1}', '{1}');
        TryQrNoNumber(Observer, '*1', '*1');
        TryQrNoNumber(Observer, '1*', '1*');
        TryQrNoNumber(Observer, '@1', '@1');
        TryQrNoNumber(Observer, '1_000', '1_000');
        TryQrNoNumber(Observer, '1''000', '1''000');
        TryQrNoNumber(Observer, '€5', '€5');
        TryQrNoNumber(Observer, '£5', '£5');
        TryQrNoNumber(Observer, '5$', '5$');
        TryQrNoNumber(Observer, '$-5', '$-5');
        TryQrNoNumber(Observer, '-$5', '-$5');
        TryQrNoNumber(Observer, '+-5', '+-5');
        TryQrNoNumber(Observer, '--5', '--5');
        TryQrNoNumber(Observer, '5--', '5--');
        TryQrNoNumber(Observer, 'ä', 'ä');
        TryQrNoNumber(Observer, 'Ä1', 'Ä1');
        Observer.Expect('New/Updated', 'No -1');
        Observer.Expect('a/b', 'No -1');
        Observer.Expect('1/2', 'No -1');
        Observer.Expect('12:30', 'No -1');
        Observer.Expect('#1', 'No -1');
        Observer.Expect('1#', 'No -1');
        Observer.Expect('A&B', 'No -1');
        Observer.Expect('1=1', 'No -1');
        Observer.Expect('''1''', 'No -1');
        Observer.Expect('"1"', 'No -1');
        Observer.Expect('1;2', 'No -1');
        Observer.Expect('[1]', 'No -1');
        Observer.Expect('{1}', 'No -1');
        Observer.Expect('*1', 'No -1');
        Observer.Expect('1*', 'No -1');
        Observer.Expect('@1', 'No -1');
        Observer.Expect('1_000', 'No -1');
        Observer.Expect('1''000', 'No -1');
        Observer.Expect('€5', 'No -1');
        Observer.Expect('£5', 'No -1');
        Observer.Expect('5$', 'Yes 5');
        Observer.Expect('$-5', 'Yes -5');
        Observer.Expect('-$5', 'Yes -5');
        Observer.Expect('+-5', 'No -1');
        Observer.Expect('--5', 'No -1');
        Observer.Expect('5--', 'No -1');
        Observer.Expect('ä', 'No -1');
        Observer.Expect('Ä1', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Punctuation_Number0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr0(Observer, 'New/Updated', 'New/Updated');
        TryQr0(Observer, 'a/b', 'a/b');
        TryQr0(Observer, '1/2', '1/2');
        TryQr0(Observer, '12:30', '12:30');
        TryQr0(Observer, '#1', '#1');
        TryQr0(Observer, '1#', '1#');
        TryQr0(Observer, 'A&B', 'A&B');
        TryQr0(Observer, '1=1', '1=1');
        TryQr0(Observer, '''1''', '''1''');
        TryQr0(Observer, '"1"', '"1"');
        TryQr0(Observer, '1;2', '1;2');
        TryQr0(Observer, '[1]', '[1]');
        TryQr0(Observer, '{1}', '{1}');
        TryQr0(Observer, '*1', '*1');
        TryQr0(Observer, '1*', '1*');
        TryQr0(Observer, '@1', '@1');
        TryQr0(Observer, '1_000', '1_000');
        TryQr0(Observer, '1''000', '1''000');
        TryQr0(Observer, '€5', '€5');
        TryQr0(Observer, '£5', '£5');
        TryQr0(Observer, '5$', '5$');
        TryQr0(Observer, '$-5', '$-5');
        TryQr0(Observer, '-$5', '-$5');
        TryQr0(Observer, '+-5', '+-5');
        TryQr0(Observer, '--5', '--5');
        TryQr0(Observer, '5--', '5--');
        TryQr0(Observer, 'ä', 'ä');
        TryQr0(Observer, 'Ä1', 'Ä1');
        Observer.Expect('New/Updated', 'No -1');
        Observer.Expect('a/b', 'No -1');
        Observer.Expect('1/2', 'No -1');
        Observer.Expect('12:30', 'No -1');
        Observer.Expect('#1', 'No -1');
        Observer.Expect('1#', 'No -1');
        Observer.Expect('A&B', 'No -1');
        Observer.Expect('1=1', 'No -1');
        Observer.Expect('''1''', 'No -1');
        Observer.Expect('"1"', 'No -1');
        Observer.Expect('1;2', 'No -1');
        Observer.Expect('[1]', 'No -1');
        Observer.Expect('{1}', 'No -1');
        Observer.Expect('*1', 'No -1');
        Observer.Expect('1*', 'No -1');
        Observer.Expect('@1', 'No -1');
        Observer.Expect('1_000', 'No -1');
        Observer.Expect('1''000', 'No -1');
        Observer.Expect('€5', 'No -1');
        Observer.Expect('£5', 'No -1');
        Observer.Expect('5$', 'Yes 5');
        Observer.Expect('$-5', 'Yes -5');
        Observer.Expect('-$5', 'Yes -5');
        Observer.Expect('+-5', 'No -1');
        Observer.Expect('--5', 'No -1');
        Observer.Expect('5--', 'No -1');
        Observer.Expect('ä', 'No -1');
        Observer.Expect('Ä1', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Punctuation_Number9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr9(Observer, 'New/Updated', 'New/Updated');
        TryQr9(Observer, 'a/b', 'a/b');
        TryQr9(Observer, '1/2', '1/2');
        TryQr9(Observer, '12:30', '12:30');
        TryQr9(Observer, '#1', '#1');
        TryQr9(Observer, '1#', '1#');
        TryQr9(Observer, 'A&B', 'A&B');
        TryQr9(Observer, '1=1', '1=1');
        TryQr9(Observer, '''1''', '''1''');
        TryQr9(Observer, '"1"', '"1"');
        TryQr9(Observer, '1;2', '1;2');
        TryQr9(Observer, '[1]', '[1]');
        TryQr9(Observer, '{1}', '{1}');
        TryQr9(Observer, '*1', '*1');
        TryQr9(Observer, '1*', '1*');
        TryQr9(Observer, '@1', '@1');
        TryQr9(Observer, '1_000', '1_000');
        TryQr9(Observer, '1''000', '1''000');
        TryQr9(Observer, '€5', '€5');
        TryQr9(Observer, '£5', '£5');
        TryQr9(Observer, '5$', '5$');
        TryQr9(Observer, '$-5', '$-5');
        TryQr9(Observer, '-$5', '-$5');
        TryQr9(Observer, '+-5', '+-5');
        TryQr9(Observer, '--5', '--5');
        TryQr9(Observer, '5--', '5--');
        TryQr9(Observer, 'ä', 'ä');
        TryQr9(Observer, 'Ä1', 'Ä1');
        Observer.Expect('New/Updated', 'No -1');
        Observer.Expect('a/b', 'No -1');
        Observer.Expect('1/2', 'No -1');
        Observer.Expect('12:30', 'No -1');
        Observer.Expect('#1', 'No -1');
        Observer.Expect('1#', 'No -1');
        Observer.Expect('A&B', 'No -1');
        Observer.Expect('1=1', 'No -1');
        Observer.Expect('''1''', 'No -1');
        Observer.Expect('"1"', 'No -1');
        Observer.Expect('1;2', 'No -1');
        Observer.Expect('[1]', 'No -1');
        Observer.Expect('{1}', 'No -1');
        Observer.Expect('*1', 'No -1');
        Observer.Expect('1*', 'No -1');
        Observer.Expect('@1', 'No -1');
        Observer.Expect('1_000', 'No -1');
        Observer.Expect('1''000', 'No -1');
        Observer.Expect('€5', 'No -1');
        Observer.Expect('£5', 'No -1');
        Observer.Expect('5$', 'No -1');
        Observer.Expect('$-5', 'No -1');
        Observer.Expect('-$5', 'No -1');
        Observer.Expect('+-5', 'No -1');
        Observer.Expect('--5', 'No -1');
        Observer.Expect('5--', 'No -1');
        Observer.Expect('ä', 'No -1');
        Observer.Expect('Ä1', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Signs_Number0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr0(Observer, '+100', '+100');
        TryQr0(Observer, '-100', '-100');
        TryQr0(Observer, '100-', '100-');
        TryQr0(Observer, '(100)', '(100)');
        TryQr0(Observer, '(-100)', '(-100)');
        TryQr0(Observer, '+100-', '+100-');
        TryQr0(Observer, '$5', '$5');
        TryQr0(Observer, '1E-2', '1E-2');
        TryQr0(Observer, '1e+2', '1e+2');
        TryQr0(Observer, '1E', '1E');
        TryQr0(Observer, '+.5', '+.5');
        TryQr0(Observer, '-.5', '-.5');
        TryQr0(Observer, '  -100  ', '  -100  ');
        TryQr0(Observer, '100 -', '100 -');
        TryQr0(Observer, '- 100', '- 100');
        TryQr0(Observer, '+ 100', '+ 100');
        Observer.Expect('+100', 'Yes 100');
        Observer.Expect('-100', 'Yes -100');
        Observer.Expect('100-', 'Yes -100');
        Observer.Expect('(100)', 'Yes -100');
        Observer.Expect('(-100)', 'No -1');
        Observer.Expect('+100-', 'No -1');
        Observer.Expect('$5', 'Yes 5');
        Observer.Expect('1E-2', 'Yes 0.01');
        Observer.Expect('1e+2', 'Yes 100');
        Observer.Expect('1E', 'No -1');
        Observer.Expect('+.5', 'Yes 0.5');
        Observer.Expect('-.5', 'Yes -0.5');
        Observer.Expect('  -100  ', 'Yes -100');
        Observer.Expect('100 -', 'Yes -100');
        Observer.Expect('- 100', 'No -1');
        Observer.Expect('+ 100', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Signs_Number9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr9(Observer, '+100', '+100');
        TryQr9(Observer, '-100', '-100');
        TryQr9(Observer, '100-', '100-');
        TryQr9(Observer, '(100)', '(100)');
        TryQr9(Observer, '(-100)', '(-100)');
        TryQr9(Observer, '+100-', '+100-');
        TryQr9(Observer, '$5', '$5');
        TryQr9(Observer, '1E-2', '1E-2');
        TryQr9(Observer, '1e+2', '1e+2');
        TryQr9(Observer, '1E', '1E');
        TryQr9(Observer, '+.5', '+.5');
        TryQr9(Observer, '-.5', '-.5');
        TryQr9(Observer, '  -100  ', '  -100  ');
        TryQr9(Observer, '100 -', '100 -');
        TryQr9(Observer, '- 100', '- 100');
        TryQr9(Observer, '+ 100', '+ 100');
        Observer.Expect('+100', 'Yes 100');
        Observer.Expect('-100', 'Yes -100');
        Observer.Expect('100-', 'No -1');
        Observer.Expect('(100)', 'No -1');
        Observer.Expect('(-100)', 'No -1');
        Observer.Expect('+100-', 'No -1');
        Observer.Expect('$5', 'No -1');
        Observer.Expect('1E-2', 'Yes 0.01');
        Observer.Expect('1e+2', 'Yes 100');
        Observer.Expect('1E', 'No -1');
        Observer.Expect('+.5', 'Yes 0.5');
        Observer.Expect('-.5', 'Yes -0.5');
        Observer.Expect('  -100  ', 'Yes -100');
        Observer.Expect('100 -', 'No -1');
        Observer.Expect('- 100', 'No -1');
        Observer.Expect('+ 100', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_WhiteSpace_Number0()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr0(Observer, '{TAB}100', '{TAB}100');
        TryQr0(Observer, '100{TAB}', '100{TAB}');
        TryQr0(Observer, '{LF}100', '{LF}100');
        TryQr0(Observer, '100{CR}{LF}', '100{CR}{LF}');
        TryQr0(Observer, '{NBSP}100', '{NBSP}100');
        TryQr0(Observer, '100{NBSP}', '100{NBSP}');
        TryQr0(Observer, '1{NBSP}000', '1{NBSP}000');
        TryQr0(Observer, '{NNBSP}100', '{NNBSP}100');
        TryQr0(Observer, '1{NNBSP}000', '1{NNBSP}000');
        TryQr0(Observer, '{FW1}{FW2}', '{FW1}{FW2}');
        TryQr0(Observer, '{AR1}', '{AR1}');
        Observer.Expect('{TAB}100', 'Yes 100');
        Observer.Expect('100{TAB}', 'Yes 100');
        Observer.Expect('{LF}100', 'Yes 100');
        Observer.Expect('100{CR}{LF}', 'Yes 100');
        Observer.Expect('{NBSP}100', 'No -1');
        Observer.Expect('100{NBSP}', 'No -1');
        Observer.Expect('1{NBSP}000', 'No -1');
        Observer.Expect('{NNBSP}100', 'No -1');
        Observer.Expect('1{NNBSP}000', 'No -1');
        Observer.Expect('{FW1}{FW2}', 'No -1');
        Observer.Expect('{AR1}', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_WhiteSpace_Number9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        TryQr9(Observer, '{TAB}100', '{TAB}100');
        TryQr9(Observer, '100{TAB}', '100{TAB}');
        TryQr9(Observer, '{LF}100', '{LF}100');
        TryQr9(Observer, '100{CR}{LF}', '100{CR}{LF}');
        TryQr9(Observer, '{NBSP}100', '{NBSP}100');
        TryQr9(Observer, '100{NBSP}', '100{NBSP}');
        TryQr9(Observer, '1{NBSP}000', '1{NBSP}000');
        TryQr9(Observer, '{NNBSP}100', '{NNBSP}100');
        TryQr9(Observer, '1{NNBSP}000', '1{NNBSP}000');
        TryQr9(Observer, '{FW1}{FW2}', '{FW1}{FW2}');
        TryQr9(Observer, '{AR1}', '{AR1}');
        Observer.Expect('{TAB}100', 'Yes 100');
        Observer.Expect('100{TAB}', 'Yes 100');
        Observer.Expect('{LF}100', 'Yes 100');
        Observer.Expect('100{CR}{LF}', 'Yes 100');
        Observer.Expect('{NBSP}100', 'No -1');
        Observer.Expect('100{NBSP}', 'No -1');
        Observer.Expect('1{NBSP}000', 'No -1');
        Observer.Expect('{NNBSP}100', 'No -1');
        Observer.Expect('1{NNBSP}000', 'No -1');
        Observer.Expect('{FW1}{FW2}', 'No -1');
        Observer.Expect('{AR1}', 'No -1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Statement_OddCharacters()
    var
        Observer: Codeunit "Probe Observer";
        D: Decimal;
    begin
        D := -1;
        asserterror Evaluate(D, 'New/Updated');
        Observer.ObserveError('slash');
        Observer.Observe('slash value', Format(D, 0, 9));
        asserterror Evaluate(D, 'New/Updated', 9);
        Observer.ObserveError('slash 9');
        asserterror Evaluate(D, QrText('1{NNBSP}000'));
        Observer.ObserveError('nnbsp');
        asserterror Evaluate(D, QrText('1{NNBSP}000'), 9);
        Observer.ObserveError('nnbsp 9');
        asserterror Evaluate(D, '(100)', 9);
        Observer.ObserveError('parentheses 9');
        Observer.Observe('value after', Format(D, 0, 9));
        Observer.Expect('slash|text', 'The value "New/Updated" can''t be evaluated into type Decimal.');
        Observer.Expect('slash|code', 'Evaluate');
        Observer.Expect('slash value', '-1');
        Observer.Expect('slash 9|text', 'The value "New/Updated" can''t be evaluated into type Decimal.');
        Observer.Expect('slash 9|code', 'Evaluate');
        Observer.Expect('nnbsp|text', 'The value "1 000" can''t be evaluated into type Decimal.');
        Observer.Expect('nnbsp|code', 'Evaluate');
        Observer.Expect('nnbsp 9|text', 'The value "1 000" can''t be evaluated into type Decimal.');
        Observer.Expect('nnbsp 9|code', 'Evaluate');
        Observer.Expect('parentheses 9|text', 'The value "(100)" can''t be evaluated into type Decimal.');
        Observer.Expect('parentheses 9|code', 'Evaluate');
        Observer.Expect('value after', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Evaluate_Integer_OddCharacters()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
        Ok: Boolean;
    begin
        I := -1;
        Ok := Evaluate(I, 'New/Updated');
        Observer.Observe('int slash', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(I, 'New/Updated', 9);
        Observer.Observe('int slash 9', Format(Ok) + ' ' + Format(I));
        Ok := Evaluate(I, '100-');
        Observer.Observe('int trailing minus', Format(Ok) + ' ' + Format(I));
        I := -1;
        Ok := Evaluate(I, '100-', 9);
        Observer.Observe('int trailing minus 9', Format(Ok) + ' ' + Format(I));
        I := -1;
        Ok := Evaluate(I, '(100)');
        Observer.Observe('int parentheses', Format(Ok) + ' ' + Format(I));
        I := -1;
        Ok := Evaluate(I, '+100', 9);
        Observer.Observe('int plus 9', Format(Ok) + ' ' + Format(I));
        I := -1;
        Ok := Evaluate(I, QrText('{TAB}100'));
        Observer.Observe('int tab', Format(Ok) + ' ' + Format(I));
        I := -1;
        Ok := Evaluate(I, QrText('1{NBSP}000'));
        Observer.Observe('int nbsp', Format(Ok) + ' ' + Format(I));
        B := -1;
        Ok := Evaluate(B, 'New/Updated');
        Observer.Observe('big slash', Format(Ok) + ' ' + Format(B));
        Ok := Evaluate(B, '100-');
        Observer.Observe('big trailing minus', Format(Ok) + ' ' + Format(B));
        Observer.Expect('int slash', 'No -1');
        Observer.Expect('int slash 9', 'No -1');
        Observer.Expect('int trailing minus', 'Yes -100');
        Observer.Expect('int trailing minus 9', 'No -1');
        Observer.Expect('int parentheses', 'Yes -100');
        Observer.Expect('int plus 9', 'Yes 100');
        Observer.Expect('int tab', 'Yes 100');
        Observer.Expect('int nbsp', 'No -1');
        Observer.Expect('big slash', 'No -1');
        Observer.Expect('big trailing minus', 'Yes -100');
        Observer.Verify();
    end;
}
