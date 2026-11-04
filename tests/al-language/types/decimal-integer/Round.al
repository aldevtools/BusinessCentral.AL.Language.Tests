// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/decimal/decimal-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Round with precision and direction, Abs, Power, Exp, Ln, Log.
// BC versions: 29 (27 and 28 by CI)

codeunit 72507 "LT SyT Round"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Round_Default()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('1.5', Format(Round(1.5)));
        Observer.Observe('2.5', Format(Round(2.5)));
        Observer.Observe('-1.5', Format(Round(-1.5)));
        Observer.Observe('-2.5', Format(Round(-2.5)));
        Observer.Observe('0.49999', Format(Round(0.49999)));
        Observer.Observe('0.5', Format(Round(0.5)));
        Observer.Observe('-0.5', Format(Round(-0.5)));
        Observer.Observe('0', Format(Round(0)));
        Observer.Observe('big', Format(Round(123456789012.5)));
        Observer.Observe('bigneg', Format(Round(-123456789012.5)));
        Observer.Observe('tiny', Format(Round(0.0000001)));
        Observer.Expect('1.5', '1.5');
        Observer.Expect('2.5', '2.5');
        Observer.Expect('-1.5', '-1.5');
        Observer.Expect('-2.5', '-2.5');
        Observer.Expect('0.49999', '0.5');
        Observer.Expect('0.5', '0.5');
        Observer.Expect('-0.5', '-0.5');
        Observer.Expect('0', '0');
        Observer.Expect('big', '123,456,789,012.5');
        Observer.Expect('bigneg', '-123,456,789,012.5');
        Observer.Expect('tiny', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Precision()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('p0.01 1.005', Format(Round(1.005, 0.01)));
        Observer.Observe('p0.01 1.015', Format(Round(1.015, 0.01)));
        Observer.Observe('p0.01 -1.005', Format(Round(-1.005, 0.01)));
        Observer.Observe('p0.1 1.25', Format(Round(1.25, 0.1)));
        Observer.Observe('p0.1 1.35', Format(Round(1.35, 0.1)));
        Observer.Observe('p10 15', Format(Round(15, 10)));
        Observer.Observe('p10 14', Format(Round(14, 10)));
        Observer.Observe('p10 -15', Format(Round(-15, 10)));
        Observer.Observe('p100 150', Format(Round(150, 100)));
        Observer.Observe('p0.05 1.02', Format(Round(1.02, 0.05)));
        Observer.Observe('p0.05 1.03', Format(Round(1.03, 0.05)));
        Observer.Observe('p0.25 1.1', Format(Round(1.1, 0.25)));
        Observer.Observe('p1 2.5', Format(Round(2.5, 1)));
        Observer.Observe('p0.00001', Format(Round(3.141592653, 0.00001)));
        Observer.Observe('p0.000000001', Format(Round(3.141592653589, 0.000000001)));
        Observer.Expect('p0.01 1.005', '1.01');
        Observer.Expect('p0.01 1.015', '1.02');
        Observer.Expect('p0.01 -1.005', '-1.01');
        Observer.Expect('p0.1 1.25', '1.3');
        Observer.Expect('p0.1 1.35', '1.4');
        Observer.Expect('p10 15', '20');
        Observer.Expect('p10 14', '10');
        Observer.Expect('p10 -15', '-20');
        Observer.Expect('p100 150', '200');
        Observer.Expect('p0.05 1.02', '1');
        Observer.Expect('p0.05 1.03', '1.05');
        Observer.Expect('p0.25 1.1', '1');
        Observer.Expect('p1 2.5', '3');
        Observer.Expect('p0.00001', '3.14159');
        Observer.Expect('p0.000000001', '3.141592654');
        Observer.Verify();
    end;

    [Test]
    procedure Round_Direction()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('= 2.5', Format(Round(2.5, 1, '=')));
        Observer.Observe('= -2.5', Format(Round(-2.5, 1, '=')));
        Observer.Observe('> 2.1', Format(Round(2.1, 1, '>')));
        Observer.Observe('> -2.1', Format(Round(-2.1, 1, '>')));
        Observer.Observe('> 2', Format(Round(2, 1, '>')));
        Observer.Observe('< 2.9', Format(Round(2.9, 1, '<')));
        Observer.Observe('< -2.9', Format(Round(-2.9, 1, '<')));
        Observer.Observe('< 2', Format(Round(2, 1, '<')));
        Observer.Observe('> 0.001 p0.01', Format(Round(0.001, 0.01, '>')));
        Observer.Observe('< 0.009 p0.01', Format(Round(0.009, 0.01, '<')));
        Observer.Observe('> 11 p10', Format(Round(11, 10, '>')));
        Observer.Observe('< 19 p10', Format(Round(19, 10, '<')));
        Observer.Observe('< -11 p10', Format(Round(-11, 10, '<')));
        Observer.Observe('> 0', Format(Round(0, 1, '>')));
        Observer.Expect('= 2.5', '3');
        Observer.Expect('= -2.5', '-3');
        Observer.Expect('> 2.1', '3');
        Observer.Expect('> -2.1', '-3');
        Observer.Expect('> 2', '2');
        Observer.Expect('< 2.9', '2');
        Observer.Expect('< -2.9', '-2');
        Observer.Expect('< 2', '2');
        Observer.Expect('> 0.001 p0.01', '0.01');
        Observer.Expect('< 0.009 p0.01', '0');
        Observer.Expect('> 11 p10', '20');
        Observer.Expect('< 19 p10', '10');
        Observer.Expect('< -11 p10', '-10');
        Observer.Expect('> 0', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Round_InvalidDirection()
    var
        Observer: Codeunit "Probe Observer";
        Result: Decimal;
    begin
        asserterror Result := Round(2.5, 1, 'x');
        Observer.ObserveError('dir x');
        asserterror Result := Round(2.5, 1, '');
        Observer.ObserveError('dir empty');
        asserterror Result := Round(2.5, 1, '>>');
        Observer.ObserveError('dir two chars');
        asserterror Result := Round(2.5, 0);
        Observer.ObserveError('precision zero');
        asserterror Result := Round(2.5, -1);
        Observer.ObserveError('precision negative');
        Observer.Expect('dir x|text', 'The supplied value is not valid.');
        Observer.Expect('dir x|code', 'InvalidValue');
        Observer.Expect('dir empty|text', 'The supplied value is not valid.');
        Observer.Expect('dir empty|code', 'InvalidValue');
        Observer.Expect('dir two chars|text', 'The supplied value is not valid.');
        Observer.Expect('dir two chars|code', 'InvalidValue');
        Observer.Expect('precision zero|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 0. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('precision zero|code', 'OutsidePermittedRange');
        Observer.Expect('precision negative|text', 'The value of ROUND parameter 2 is outside of the permitted range. The current value is: 1. The permitted range is: from 1 to 2,147,483,647.');
        Observer.Expect('precision negative|code', 'OutsidePermittedRange');
        Observer.Verify();
    end;

    [Test]
    procedure Round_IntegerArguments()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        D: Decimal;
    begin
        I := 7;
        D := 7.5;
        Observer.Observe('int', Format(Round(I)));
        Observer.Observe('int p2', Format(Round(I, 2)));
        Observer.Observe('dec', Format(Round(D)));
        Observer.Observe('dec p0.1', Format(Round(D, 0.1)));
        Observer.Observe('int / int', Format(Round(7 / 2)));
        Observer.Observe('int div int', Format(7 div 2));
        Observer.Observe('big p1', Format(Round(99999999999999.5, 1)));
        Observer.Expect('int', '7');
        Observer.Expect('int p2', '8');
        Observer.Expect('dec', '7.5');
        Observer.Expect('dec p0.1', '7.5');
        Observer.Expect('int / int', '3.5');
        Observer.Expect('int div int', '3');
        Observer.Expect('big p1', '100,000,000,000,000');
        Observer.Verify();
    end;

    [Test]
    procedure Abs_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
        B: BigInteger;
    begin
        Observer.Observe('-1.5', Format(Abs(-1.5)));
        Observer.Observe('1.5', Format(Abs(1.5)));
        Observer.Observe('0', Format(Abs(0)));
        Observer.Observe('-0.0', Format(Abs(-0.0)));
        I := -2147483647;
        Observer.Observe('int min+1', Format(Abs(I)));
        I := -5;
        Observer.Observe('int -5', Format(Abs(I)));
        Evaluate(B, '-9223372036854775807');
        Observer.Observe('big', Format(Abs(B)));
        Observer.Observe('dec big', Format(Abs(-123456789012345.678)));
        I := -2147483647 - 1;
        asserterror Observer.Observe('int min', Format(Abs(I)));
        Observer.ObserveError('int min');
        Observer.Expect('-1.5', '1.5');
        Observer.Expect('1.5', '1.5');
        Observer.Expect('0', '0');
        Observer.Expect('-0.0', '0');
        Observer.Expect('int min+1', '2147483647');
        Observer.Expect('int -5', '5');
        Observer.Expect('big', '9223372036854775807');
        Observer.Expect('dec big', '123,456,789,012,345.678');
        Observer.Expect('int min|text', 'Negating the minimum value of a twos complement number is invalid.');
        Observer.Expect('int min|code', 'AL:Overflow');
        Observer.Verify();
    end;

    [Test]
    procedure Power_Values()
    var
        Observer: Codeunit "Probe Observer";
        R: Decimal;
    begin
        Observer.Observe('2^10', Format(Power(2, 10)));
        Observer.Observe('2^0', Format(Power(2, 0)));
        Observer.Observe('0^0', Format(Power(0, 0)));
        Observer.Observe('0^1', Format(Power(0, 1)));
        Observer.Observe('2^-1', Format(Power(2, -1)));
        Observer.Observe('2^-2', Format(Power(2, -2)));
        Observer.Observe('-2^3', Format(Power(-2, 3)));
        Observer.Observe('-2^2', Format(Power(-2, 2)));
        Observer.Observe('4^0.5', Format(Power(4, 0.5)));
        Observer.Observe('8^(1/3)', Format(Round(Power(8, 1 / 3), 0.00001)));
        Observer.Observe('1.5^2', Format(Power(1.5, 2)));
        asserterror Observer.Observe('10^15', Format(Power(10, 15)));
        Observer.ObserveError('af156');
        Observer.Observe('1^1000', Format(Power(1, 1000)));
        asserterror R := Power(0, -1);
        Observer.ObserveError('0^-1');
        asserterror R := Power(-8, 0.5);
        Observer.ObserveError('-8^0.5');
        asserterror R := Power(10, 1000);
        Observer.ObserveError('10^1000');
        Observer.Expect('2^10', '1,024');
        Observer.Expect('2^0', '1');
        Observer.Expect('0^0', '1');
        Observer.Expect('0^1', '0');
        Observer.Expect('2^-1', '0.5');
        Observer.Expect('2^-2', '0.25');
        Observer.Expect('-2^3', '-8');
        Observer.Expect('-2^2', '4');
        Observer.Expect('4^0.5', '2');
        Observer.Expect('8^(1/3)', '2');
        Observer.Expect('1.5^2', '2.25');
        Observer.Expect('af156|text', 'The value of Decimal parameter  is outside of the permitted range. The current value is: 1,000,000,000,000,000. The permitted range is: from -999,999,999,999,999.99 to 999,999,999,999,999.99.');
        Observer.Expect('af156|code', 'OutsidePermittedRange');
        Observer.Expect('1^1000', '1');
        Observer.Expect('0^-1|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('0^-1|code', 'AL:Overflow');
        Observer.Expect('-8^0.5|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('-8^0.5|code', 'AL:Overflow');
        Observer.Expect('10^1000|text', 'Value was either too large or too small for a Decimal.');
        Observer.Expect('10^1000|code', 'AL:Overflow');
        Observer.Verify();
    end;

    // Corpus issue 672 (odd AL behavior leads, part G), item 33: Round without a precision takes the default from the
    // application (codeunit "Auto Format" OnReadRounding, General Ledger Setup "Amount Rounding Precision"). The test changes
    // the setup and restores it.
    [Test]
    procedure LT_BU_Round_Default_FollowsGLSetup()
    var
        Observer: Codeunit "Probe Observer";
        GLSetup: Record "General Ledger Setup";
        Saved: Decimal;
    begin
        GLSetup.Get();
        Saved := GLSetup."Amount Rounding Precision";
        Observer.Observe('saved precision', Format(Saved, 0, 9));
        ObserveDefaultRounds(Observer, 'start');
        SetAmountRoundingPrecision(1);
        ObserveDefaultRounds(Observer, 'p1');
        SetAmountRoundingPrecision(0.1);
        ObserveDefaultRounds(Observer, 'p0.1');
        SetAmountRoundingPrecision(0.001);
        ObserveDefaultRounds(Observer, 'p0.001');
        SetAmountRoundingPrecision(0);
        ObserveDefaultRounds(Observer, 'p0');
        SetAmountRoundingPrecision(Saved);
        ObserveDefaultRounds(Observer, 'restored');
        Observer.Expect('saved precision', '0.01');
        Observer.Expect('start 1.55', '1.55');
        Observer.Expect('start 2.5', '2.5');
        Observer.Expect('start -2.5', '-2.5');
        Observer.Expect('start 1.23456', '1.23');
        Observer.Expect('p1 1.55', '1.55');
        Observer.Expect('p1 2.5', '2.5');
        Observer.Expect('p1 -2.5', '-2.5');
        Observer.Expect('p1 1.23456', '1.23');
        Observer.Expect('p0.1 1.55', '1.55');
        Observer.Expect('p0.1 2.5', '2.5');
        Observer.Expect('p0.1 -2.5', '-2.5');
        Observer.Expect('p0.1 1.23456', '1.23');
        Observer.Expect('p0.001 1.55', '1.55');
        Observer.Expect('p0.001 2.5', '2.5');
        Observer.Expect('p0.001 -2.5', '-2.5');
        Observer.Expect('p0.001 1.23456', '1.23');
        Observer.Expect('p0 1.55', '1.55');
        Observer.Expect('p0 2.5', '2.5');
        Observer.Expect('p0 -2.5', '-2.5');
        Observer.Expect('p0 1.23456', '1.23');
        Observer.Expect('restored 1.55', '1.55');
        Observer.Expect('restored 2.5', '2.5');
        Observer.Expect('restored -2.5', '-2.5');
        Observer.Expect('restored 1.23456', '1.23');
        Observer.Verify();
    end;

    local procedure SetAmountRoundingPrecision(Precision: Decimal)
    var
        GLSetup: Record "General Ledger Setup";
    begin
        GLSetup.Get();
        GLSetup."Amount Rounding Precision" := Precision;
        GLSetup.Modify();
    end;

    local procedure ObserveDefaultRounds(var Observer: Codeunit "Probe Observer"; Prefix: Text)
    begin
        ObserveDefaultRound(Observer, Prefix + ' 1.55', 1.55);
        ObserveDefaultRound(Observer, Prefix + ' 2.5', 2.5);
        ObserveDefaultRound(Observer, Prefix + ' -2.5', -2.5);
        ObserveDefaultRound(Observer, Prefix + ' 1.23456', 1.23456);
    end;

    local procedure ObserveDefaultRound(var Observer: Codeunit "Probe Observer"; Name: Text; Value: Decimal)
    var
        R: Decimal;
    begin
        ClearLastError();
        if TryRoundDefault(Value, R) then
            Observer.Observe(Name, Format(R, 0, 9))
        else
            Observer.Observe(Name, 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryRoundDefault(Value: Decimal; var R: Decimal)
    begin
        R := Round(Value);
    end;

    // Corpus issue 672, item 41: the Learn example table of Round (precision 1, 10 and 100 on +-1234.56789).
    [Test]
    procedure LT_BU_Round_LearnExampleTable()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('-1234.56789 p1', Format(Round(-1234.56789, 1), 0, 9));
        Observer.Observe('-1234.56789 p10', Format(Round(-1234.56789, 10), 0, 9));
        Observer.Observe('-1234.56789 p100', Format(Round(-1234.56789, 100), 0, 9));
        Observer.Observe('-1234.56789 p0.01', Format(Round(-1234.56789, 0.01), 0, 9));
        Observer.Observe('-1234.56789 p0.001', Format(Round(-1234.56789, 0.001), 0, 9));
        Observer.Observe('1234.56789 p1', Format(Round(1234.56789, 1), 0, 9));
        Observer.Observe('1234.56789 p10', Format(Round(1234.56789, 10), 0, 9));
        Observer.Observe('1234.56789 p100', Format(Round(1234.56789, 100), 0, 9));
        Observer.Observe('-1234.56789 p1 down', Format(Round(-1234.56789, 1, '<'), 0, 9));
        Observer.Observe('-1234.56789 p1 up', Format(Round(-1234.56789, 1, '>'), 0, 9));
        Observer.Expect('-1234.56789 p1', '-1235');
        Observer.Expect('-1234.56789 p10', '-1230');
        Observer.Expect('-1234.56789 p100', '-1200');
        Observer.Expect('-1234.56789 p0.01', '-1234.57');
        Observer.Expect('-1234.56789 p0.001', '-1234.568');
        Observer.Expect('1234.56789 p1', '1235');
        Observer.Expect('1234.56789 p10', '1230');
        Observer.Expect('1234.56789 p100', '1200');
        Observer.Expect('-1234.56789 p1 down', '-1234');
        Observer.Expect('-1234.56789 p1 up', '-1235');
        Observer.Verify();
    end;

    // Corpus issue 672, item 40: Power gives a Decimal; does it keep the last digits of large results (2^63 - 1 against 2^63 - 5)?
    [Test]
    procedure LT_BU_Power_LargeResultPrecision()
    var
        Observer: Codeunit "Probe Observer";
        V1: Decimal;
        V11: Decimal;
        V22: Decimal;
        B: BigInteger;
    begin
        V1 := Power(2, 63);
        V11 := V1 - 1.0;
        V22 := V1 - 5.0;
        Observer.Observe('2^63-1 = 2^63-5', Format(V11 = V22));
        Observer.Observe('2^63-1 <> 2^63-5', Format(V11 <> V22));
        Observer.Observe('2^63 - (2^63-1)', Format(V1 - V11, 0, 9));
        Observer.Observe('2^63 - (2^63-5)', Format(V1 - V22, 0, 9));
        Observer.Observe('2^53+1 - 2^53', Format((Power(2, 53) + 1) - Power(2, 53), 0, 9));
        Observer.Observe('2^60 = literal', Format(Power(2, 60) = 1152921504606846976L));
        Observer.Observe('2^60 - (2^60 - 1)', Format(Power(2, 60) - (Power(2, 60) - 1), 0, 9));
        Observer.Observe('3^40 - (3^40 - 1)', Format(Power(3, 40) - (Power(3, 40) - 1), 0, 9));
        B := Power(2, 62);
        Observer.Observe('2^62 to biginteger', Format(B));
        B := Power(2, 62) - 1;
        Observer.Observe('2^62-1 to biginteger', Format(B));
        B := Power(2, 53) + 1;
        Observer.Observe('2^53+1 to biginteger', Format(B));
        Observer.Expect('2^63-1 = 2^63-5', 'Yes');
        Observer.Expect('2^63-1 <> 2^63-5', 'No');
        Observer.Expect('2^63 - (2^63-1)', '0');
        Observer.Expect('2^63 - (2^63-5)', '0');
        Observer.Expect('2^53+1 - 2^53', '1');
        Observer.Expect('2^60 = literal', 'Yes');
        Observer.Expect('2^60 - (2^60 - 1)', '0');
        Observer.Expect('3^40 - (3^40 - 1)', '0');
        Observer.Expect('2^62 to biginteger', '4611686018427387900');
        Observer.Expect('2^62-1 to biginteger', '4611686018427387900');
        Observer.Expect('2^53+1 to biginteger', '9007199254740993');
        Observer.Verify();
    end;

    // Writer RO (al-runner issue 5746): more invalid direction texts, the direction returned by a procedure, and the error trapped by a
    // TryFunction and by Codeunit.Run (the other invalid texts 'x', '' and '>>' are pinned in Round_InvalidDirection).
    local procedure RoDir(Dir: Text): Text
    begin
        exit(Dir);
    end;

    [TryFunction]
    local procedure RoTryRound(Value: Decimal; Dir: Text; var R: Decimal)
    begin
        R := Round(Value, 1, Dir);
    end;

    local procedure RoRnd(Value: Decimal; Dir: Text): Text
    var
        R: Decimal;
    begin
        ClearLastError();
        if RoTryRound(Value, Dir, R) then
            exit(Format(R, 0, 9));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure RO_Round_InvalidDirection_Texts()
    var
        Observer: Codeunit "Probe Observer";
        Dirs: List of [Text];
        Dir: Text;
        Result: Decimal;
        I: Integer;
        Big: BigInteger;
    begin
        asserterror Result := Round(1.5, 1, RoDir('q'));
        Observer.ObserveError('q from a procedure');
        Dirs.Add('q');
        Dirs.Add('Q');
        Dirs.Add('X');
        Dirs.Add(' ');
        Dirs.Add('  ');
        Dirs.Add('<>');
        Dirs.Add('==');
        Dirs.Add('<<');
        Dirs.Add('=<');
        Dirs.Add('< ');
        Dirs.Add(' <');
        Dirs.Add(' = ');
        Dirs.Add('1');
        Dirs.Add('0');
        Dirs.Add('up');
        foreach Dir in Dirs do
            Observer.Observe('try [' + Dir + ']', RoRnd(1.5, Dir));
        I := 5;
        asserterror I := Round(I, 1, 'q');
        Observer.ObserveError('integer q');
        Big := 5;
        asserterror Big := Round(Big, 1, 'q');
        Observer.ObserveError('biginteger q');
        Observer.Expect('q from a procedure|text', 'The supplied value is not valid.');
        Observer.Expect('q from a procedure|code', 'InvalidValue');
        Observer.Expect('try [q]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [Q]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [X]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [ ]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [  ]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [<>]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [==]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [<<]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [=<]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [< ]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [ <]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [ = ]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [1]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [0]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('try [up]', 'error:The supplied value is not valid.|InvalidValue');
        Observer.Expect('integer q|text', 'The supplied value is not valid.');
        Observer.Expect('integer q|code', 'InvalidValue');
        Observer.Expect('biginteger q|text', 'The supplied value is not valid.');
        Observer.Expect('biginteger q|code', 'InvalidValue');
        Observer.Verify();
    end;

    [Test]
    procedure RO_Round_InvalidDirection_CodeunitRun()
    var
        Observer: Codeunit "Probe Observer";
        Runner: Codeunit "LT RO Round Bad Direction";
    begin
        ClearLastError();
        Observer.Observe('codeunit.run', Format(Runner.Run()));
        Observer.Observe('last error', GetLastErrorText() + '|' + GetLastErrorCode());
        Observer.Expect('codeunit.run', 'No');
        Observer.Expect('last error', 'The supplied value is not valid.|InvalidValue');
        Observer.Verify();
    end;
}

// Writer RO: OnRun rounds with the direction 'q' (al-runner issue 5746).
codeunit 88446 "LT RO Round Bad Direction"
{
    trigger OnRun()
    var
        R: Decimal;
    begin
        R := Round(1.5, 1, 'q');
    end;
}
