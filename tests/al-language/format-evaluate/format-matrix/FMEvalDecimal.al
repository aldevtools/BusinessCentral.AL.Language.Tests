// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Decimal. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72833 "LT FM Eval Decimal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Nul(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 0;
        T := '';
        T += C;
        exit(T);
    end;

    local procedure Tab(): Text
    var
        C: Char;
        T: Text;
    begin
        C := 9;
        T += C;
        exit(T);
    end;

    [TryFunction]
    local procedure TryEv(Txt: Text; var V: Decimal)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Decimal;
        Ok: Boolean;
    begin
        V := 7;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Decimal;
    begin
        V := 7;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Decimal_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'empty|b0', '', 0);
        EvB(O, 'empty|b9', '', 9);
        EvS(O, 'empty|st', '');
        EvB(O, 'blank|b0', ' ', 0);
        EvB(O, 'blank|b9', ' ', 9);
        EvS(O, 'blank|st', ' ');
        EvB(O, 'two blanks|b0', '  ', 0);
        EvB(O, 'two blanks|b9', '  ', 9);
        EvS(O, 'two blanks|st', '  ');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '-0|b0', '-0', 0);
        EvB(O, '-0|b9', '-0', 9);
        EvS(O, '-0|st', '-0');
        EvB(O, '+5|b0', '+5', 0);
        EvB(O, '+5|b9', '+5', 9);
        EvS(O, '+5|st', '+5');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, ' 5 |b0', ' 5 ', 0);
        EvB(O, ' 5 |b9', ' 5 ', 9);
        EvS(O, ' 5 |st', ' 5 ');
        EvB(O, '1,234|b0', '1,234', 0);
        EvB(O, '1,234|b9', '1,234', 9);
        EvS(O, '1,234|st', '1,234');
        EvB(O, '1.5|b0', '1.5', 0);
        EvB(O, '1.5|b9', '1.5', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, '1.5|st', '1.5');
        EvB(O, '1,5|b0', '1,5', 0);
        EvB(O, '1,5|b9', '1,5', 9);
        EvS(O, '1,5|st', '1,5');
        EvB(O, '.5|b0', '.5', 0);
        EvB(O, '.5|b9', '.5', 9);
        EvS(O, '.5|st', '.5');
        EvB(O, '5.|b0', '5.', 0);
        EvB(O, '5.|b9', '5.', 9);
        EvS(O, '5.|st', '5.');
        EvB(O, '12abc|b0', '12abc', 0);
        EvB(O, '12abc|b9', '12abc', 9);
        EvS(O, '12abc|st', '12abc');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, '--1|b0', '--1', 0);
        EvB(O, '--1|b9', '--1', 9);
        EvS(O, '--1|st', '--1');
        EvB(O, '1e3|b0', '1e3', 0);
        EvB(O, '1e3|b9', '1e3', 9);
        EvS(O, '1e3|st', '1e3');
        EvB(O, '1E3|b0', '1E3', 0);
        EvB(O, '1E3|b9', '1E3', 9);
        EvS(O, '1E3|st', '1E3');
        EvB(O, '09e738195|b0', '09e738195', 0);
        EvB(O, '09e738195|b9', '09e738195', 9);
        EvS(O, '09e738195|st', '09e738195');
        EvB(O, '1e-5|b0', '1e-5', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '1e-5|b9', '1e-5', 9);
        EvS(O, '1e-5|st', '1e-5');
        EvB(O, '0x10|b0', '0x10', 0);
        EvB(O, '0x10|b9', '0x10', 9);
        EvS(O, '0x10|st', '0x10');
        EvB(O, '5D|b0', '5D', 0);
        EvB(O, '5D|b9', '5D', 9);
        EvS(O, '5D|st', '5D');
        EvB(O, '5T|b0', '5T', 0);
        EvB(O, '5T|b9', '5T', 9);
        EvS(O, '5T|st', '5T');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, 'tab 5|b0', ''+Tab()+'5', 0);
        EvB(O, 'tab 5|b9', ''+Tab()+'5', 9);
        EvS(O, 'tab 5|st', ''+Tab()+'5');
        EvB(O, '2147483647|b0', '2147483647', 0);
        EvB(O, '2147483647|b9', '2147483647', 9);
        EvS(O, '2147483647|st', '2147483647');
        EvB(O, '2147483648|b0', '2147483648', 0);
        EvB(O, '2147483648|b9', '2147483648', 9);
        EvS(O, '2147483648|st', '2147483648');
        EvB(O, '-2147483648|b0', '-2147483648', 0);
        EvB(O, '-2147483648|b9', '-2147483648', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, '-2147483648|st', '-2147483648');
        EvB(O, '-2147483649|b0', '-2147483649', 0);
        EvB(O, '-2147483649|b9', '-2147483649', 9);
        EvS(O, '-2147483649|st', '-2147483649');
        EvB(O, '9223372036854775807|b0', '9223372036854775807', 0);
        EvB(O, '9223372036854775807|b9', '9223372036854775807', 9);
        EvS(O, '9223372036854775807|st', '9223372036854775807');
        EvB(O, '9223372036854775808|b0', '9223372036854775808', 0);
        EvB(O, '9223372036854775808|b9', '9223372036854775808', 9);
        EvS(O, '9223372036854775808|st', '9223372036854775808');
        EvB(O, '79228162514264337593543950335|b0', '79228162514264337593543950335', 0);
        EvB(O, '79228162514264337593543950335|b9', '79228162514264337593543950335', 9);
        EvS(O, '79228162514264337593543950335|st', '79228162514264337593543950335');
        EvB(O, '99999999999999999999999999999|b0', '99999999999999999999999999999', 0);
        EvB(O, '99999999999999999999999999999|b9', '99999999999999999999999999999', 9);
        EvS(O, '99999999999999999999999999999|st', '99999999999999999999999999999');
        EvB(O, '1 000|b0', '1 000', 0);
        EvB(O, '1 000|b9', '1 000', 9);
        EvS(O, '1 000|st', '1 000');
        EvB(O, '1000|b0', '1''''000', 0);
        EvB(O, '1000|b9', '1''''000', 9);
        EvS(O, '1000|st', '1''''000');
        EvB(O, '(5)|b0', '(5)', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_5()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '(5)|b9', '(5)', 9);
        EvS(O, '(5)|st', '(5)');
        EvB(O, '5-|b0', '5-', 0);
        EvB(O, '5-|b9', '5-', 9);
        EvS(O, '5-|st', '5-');
        EvB(O, 'true|b0', 'true', 0);
        EvB(O, 'true|b9', 'true', 9);
        EvS(O, 'true|st', 'true');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, 'empty|b0', '', 0);
        EvB(O, 'empty|b9', '', 9);
        EvS(O, 'empty|st', '');
        EvB(O, 'blank|b0', ' ', 0);
        EvB(O, 'blank|b9', ' ', 9);
        EvS(O, 'blank|st', ' ');
        EvB(O, 'two blanks|b0', '  ', 0);
        EvB(O, 'two blanks|b9', '  ', 9);
        EvS(O, 'two blanks|st', '  ');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '-0|b0', '-0', 0);
        EvB(O, '-0|b9', '-0', 9);
        EvS(O, '-0|st', '-0');
        EvB(O, '+5|b0', '+5', 0);
        EvB(O, '+5|b9', '+5', 9);
        EvS(O, '+5|st', '+5');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, ' 5 |b0', ' 5 ', 0);
        EvB(O, ' 5 |b9', ' 5 ', 9);
        EvS(O, ' 5 |st', ' 5 ');
        EvB(O, '1,234|b0', '1,234', 0);
        EvB(O, '1,234|b9', '1,234', 9);
        EvS(O, '1,234|st', '1,234');
        EvB(O, '1.5|b0', '1.5', 0);
        EvB(O, '1.5|b9', '1.5', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Decimal_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvS(O, '1.5|st', '1.5');
        EvB(O, '1,5|b0', '1,5', 0);
        EvB(O, '1,5|b9', '1,5', 9);
        EvS(O, '1,5|st', '1,5');
        EvB(O, '.5|b0', '.5', 0);
        EvB(O, '.5|b9', '.5', 9);
        EvS(O, '.5|st', '.5');
        EvB(O, '5T|b0', '5T', 0);
        EvB(O, '5T|b9', '5T', 9);
        EvS(O, '5T|st', '5T');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
