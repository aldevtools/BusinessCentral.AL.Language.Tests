// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-operators
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunit 67292
// Binary operators: precedence and associativity (* / div mod and before + - or xor, comparison last), the result type for mixed operand types (read through a Variant), division, text and date arithmetic;
// unary minus, plus and not on each supported type. Operand combinations the compiler rejects are in tests/must-not-compile/cases (0580 and up).
// BC versions: 27, 28, 29
codeunit 67292 "LT P Binary Unary Expressions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure TypeOf(V: Variant): Text
    begin
        case true of
            V.IsInteger():
                exit('Integer');
            V.IsBigInteger():
                exit('BigInteger');
            V.IsDecimal():
                exit('Decimal');
            V.IsBoolean():
                exit('Boolean');
            V.IsDate():
                exit('Date');
            V.IsTime():
                exit('Time');
            V.IsDateTime():
                exit('DateTime');
            V.IsDuration():
                exit('Duration');
            V.IsChar():
                exit('Char');
            V.IsCode():
                exit('Code');
            V.IsText():
                exit('Text');
            V.IsOption():
                exit('Option');
        end;
        exit('other');
    end;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; V: Variant)
    var
        T: Text;
    begin
        T := TypeOf(V);
        Observer.Observe(Name, T + ' ' + Format(V, 0, 9));
    end;

    [Test]
    procedure PBinary_Precedence()
    var
        Observer: Codeunit "Probe Observer";
        A: Integer;
        B: Integer;
        C: Integer;
    begin
        A := 2;
        B := 3;
        C := 4;
        Show(Observer, 'add_mul', A + B * C);
        Show(Observer, 'parens', (A + B) * C);
        Show(Observer, 'sub_left_assoc', 10 - B - A);
        Show(Observer, 'mul_mod', A * B mod C);
        Show(Observer, 'mod_mul', C mod B * A);
        Show(Observer, 'div_mul', 20 div A * B);
        Show(Observer, 'slash_mul', 20 / A * B);
        Show(Observer, 'sub_neg', A - -B);
        Show(Observer, 'not_and', not true and false);
        Show(Observer, 'or_and', true or false and false);
        Show(Observer, 'xor_and', true xor true and false);
        Show(Observer, 'cmp_after_add', A + B = 5);
        Show(Observer, 'cmp_and', (A < B) and (B < C));
        Show(Observer, 'text_cmp_case', 'abc' = 'ABC');
        Show(Observer, 'text_less', 'abc' < 'abd');
        Show(Observer, 'in_set', B in [1 .. 3]);
        Show(Observer, 'in_set_text', 'b' in ['a', 'c']);
        Observer.Expect('add_mul', 'Integer 14');
        Observer.Expect('parens', 'Integer 20');
        Observer.Expect('sub_left_assoc', 'Integer 5');
        Observer.Expect('mul_mod', 'Integer 2');
        Observer.Expect('mod_mul', 'Integer 2');
        Observer.Expect('div_mul', 'Integer 30');
        Observer.Expect('slash_mul', 'Decimal 30');
        Observer.Expect('sub_neg', 'Integer 5');
        Observer.Expect('not_and', 'Boolean false');
        Observer.Expect('or_and', 'Boolean true');
        Observer.Expect('xor_and', 'Boolean true');
        Observer.Expect('cmp_after_add', 'Boolean true');
        Observer.Expect('cmp_and', 'Boolean true');
        Observer.Expect('text_cmp_case', 'Boolean false');
        Observer.Expect('text_less', 'Boolean true');
        Observer.Expect('in_set', 'Boolean true');
        Observer.Expect('in_set_text', 'Boolean false');
        Observer.Verify();
    end;

    [Test]
    procedure PBinary_ResultTypes()
    var
        Observer: Codeunit "Probe Observer";
        Int: Integer;
        Dec: Decimal;
        Big: BigInteger;
        D1: Date;
        D2: Date;
        T1: Time;
        T2: Time;
        Dt1: DateTime;
        Dt2: DateTime;
        Dur: Duration;
        Txt: Text;
        Cd: Code[10];
        Ch: Char;
    begin
        Int := 7;
        Dec := 2;
        Big := 5;
        D1 := 20260115D;
        D2 := 20260110D;
        T1 := 120000T;
        T2 := 110000T;
        Dt1 := CreateDateTime(20260115D, 120000T);
        Dt2 := CreateDateTime(20260115D, 110000T);
        Dur := 3600000;
        Txt := 'ab';
        Cd := 'cd';
        Ch := 65;
        Show(Observer, 'int_plus_int', Int + 2);
        Show(Observer, 'int_div_int', Int div 2);
        Show(Observer, 'int_slash_int', Int / 2);
        Show(Observer, 'int_slash_int_exact', 8 / 2);
        Show(Observer, 'int_mod_int', Int mod 3);
        Show(Observer, 'neg_div', -7 div 2);
        Show(Observer, 'neg_mod', -7 mod 3);
        Show(Observer, 'int_times_dec', Int * Dec);
        Show(Observer, 'int_plus_dec', Int + Dec);
        Show(Observer, 'int_plus_big', Int + Big);
        Show(Observer, 'big_times_big', Big * Big);
        Show(Observer, 'big_div_int', Big div 2);
        Show(Observer, 'big_slash_int', Big / 2);
        Show(Observer, 'dec_plus_big', Dec + Big);
        Show(Observer, 'date_minus_date', D1 - D2);
        Show(Observer, 'date_plus_int', D2 + 5);
        Show(Observer, 'date_minus_int', D1 - 5);
        Show(Observer, 'time_minus_time', T1 - T2);
        Show(Observer, 'time_plus_int', T2 + 60000);
        Show(Observer, 'time_plus_dur', T2 + Dur);
        Show(Observer, 'datetime_minus_datetime', Dt1 - Dt2);
        Show(Observer, 'datetime_plus_dur', Dt2 + Dur);
        Show(Observer, 'datetime_plus_int', Dt2 + 1000);
        Show(Observer, 'datetime_minus_dur', Dt1 - Dur);
        Show(Observer, 'dur_plus_dur', Dur + Dur);
        Show(Observer, 'dur_times_int', Dur * 2);
        Show(Observer, 'dur_div_int', Dur div 2);
        Show(Observer, 'text_plus_text', Txt + 'cd');
        Show(Observer, 'text_plus_code', Txt + Cd);
        Show(Observer, 'code_plus_text', Cd + Txt);
        Show(Observer, 'code_plus_code', Cd + Cd);
        Show(Observer, 'text_plus_char', Txt + Ch);
        Show(Observer, 'char_plus_char', Ch + Ch);
        Show(Observer, 'text_plus_empty', Txt + '');
        Show(Observer, 'int_cmp_dec', Int > Dec);
        Show(Observer, 'date_cmp_date', D1 > D2);
        Show(Observer, 'bool_and_bool', true and false);
        Show(Observer, 'bool_or_bool', false or true);
        Show(Observer, 'bool_xor_bool', true xor false);
        Observer.Expect('int_plus_int', 'Integer 9');
        Observer.Expect('int_div_int', 'Integer 3');
        Observer.Expect('int_slash_int', 'Decimal 3.5');
        Observer.Expect('int_slash_int_exact', 'Decimal 4');
        Observer.Expect('int_mod_int', 'Integer 1');
        Observer.Expect('neg_div', 'Integer -3');
        Observer.Expect('neg_mod', 'Integer -1');
        Observer.Expect('int_times_dec', 'Decimal 14');
        Observer.Expect('int_plus_dec', 'Decimal 9');
        Observer.Expect('int_plus_big', 'BigInteger 12');
        Observer.Expect('big_times_big', 'BigInteger 25');
        Observer.Expect('big_div_int', 'BigInteger 2');
        Observer.Expect('big_slash_int', 'Decimal 2.5');
        Observer.Expect('dec_plus_big', 'Decimal 7');
        Observer.Expect('date_minus_date', 'Integer 5');
        Observer.Expect('date_plus_int', 'Date 2026-01-15');
        Observer.Expect('date_minus_int', 'Date 2026-01-10');
        Observer.Expect('time_minus_time', 'Integer 3600000');
        Observer.Expect('time_plus_int', 'Time 11:01:00');
        Observer.Expect('time_plus_dur', 'Time 12:00:00');
        Observer.Expect('datetime_minus_datetime', 'Duration P0DT1H0M0.0S');
        Observer.Expect('datetime_plus_dur', 'DateTime 2026-01-15T12:00:00Z');
        Observer.Expect('datetime_plus_int', 'DateTime 2026-01-15T11:00:01Z');
        Observer.Expect('datetime_minus_dur', 'DateTime 2026-01-15T11:00:00Z');
        Observer.Expect('dur_plus_dur', 'BigInteger 7200000');
        Observer.Expect('dur_times_int', 'BigInteger 7200000');
        Observer.Expect('dur_div_int', 'Decimal 1800000');
        Observer.Expect('text_plus_text', 'Text abcd');
        Observer.Expect('text_plus_code', 'Text abCD');
        Observer.Expect('code_plus_text', 'Text CDab');
        Observer.Expect('code_plus_code', 'Text CDCD');
        Observer.Expect('text_plus_char', 'Text abA');
        Observer.Expect('char_plus_char', 'Integer 130');
        Observer.Expect('text_plus_empty', 'Text ab');
        Observer.Expect('int_cmp_dec', 'Boolean true');
        Observer.Expect('date_cmp_date', 'Boolean true');
        Observer.Expect('bool_and_bool', 'Boolean false');
        Observer.Expect('bool_or_bool', 'Boolean true');
        Observer.Expect('bool_xor_bool', 'Boolean true');
        Observer.Verify();
    end;

    [Test]
    procedure PUnary_Operators()
    var
        Observer: Codeunit "Probe Observer";
        Int: Integer;
        Dec: Decimal;
        Big: BigInteger;
        Flag: Boolean;
    begin
        Int := 5;
        Dec := 2.5;
        Big := 9000000000L;
        Flag := true;
        Show(Observer, 'minus_int', -Int);
        Show(Observer, 'plus_int', +Int);
        Show(Observer, 'minus_minus_int', -(-Int));
        Show(Observer, 'minus_literal', -7);
        Show(Observer, 'minus_expr', -(Int + 2));
        Show(Observer, 'minus_zero', -0);
        Show(Observer, 'minus_dec', -Dec);
        Show(Observer, 'plus_dec', +Dec);
        Show(Observer, 'minus_dec_zero', -(Dec - Dec));
        Show(Observer, 'minus_big', -Big);
        Show(Observer, 'plus_big', +Big);
        Show(Observer, 'not_true', not Flag);
        Show(Observer, 'not_false', not not Flag);
        Show(Observer, 'not_literal', not false);
        Show(Observer, 'not_compare', not (Int = 5));
        Show(Observer, 'minus_binds_tight', -Int * 2);
        Show(Observer, 'minus_before_mod', -7 mod 3);
        Observer.Expect('minus_int', 'Integer -5');
        Observer.Expect('plus_int', 'Integer 5');
        Observer.Expect('minus_minus_int', 'Integer 5');
        Observer.Expect('minus_literal', 'Integer -7');
        Observer.Expect('minus_expr', 'Integer -7');
        Observer.Expect('minus_zero', 'Integer 0');
        Observer.Expect('minus_dec', 'Decimal -2.5');
        Observer.Expect('plus_dec', 'Decimal 2.5');
        Observer.Expect('minus_dec_zero', 'Decimal 0');
        Observer.Expect('minus_big', 'BigInteger -9000000000');
        Observer.Expect('plus_big', 'BigInteger 9000000000');
        Observer.Expect('not_true', 'Boolean false');
        Observer.Expect('not_false', 'Boolean true');
        Observer.Expect('not_literal', 'Boolean true');
        Observer.Expect('not_compare', 'Boolean false');
        Observer.Expect('minus_binds_tight', 'Integer -10');
        Observer.Expect('minus_before_mod', 'Integer -1');
        Observer.Verify();
    end;
}
