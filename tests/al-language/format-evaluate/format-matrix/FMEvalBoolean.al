// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Boolean. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72857 "LT FM Eval Boolean"
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

    [TryFunction]
    local procedure TryEv(Txt: Text; var V: Boolean)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Boolean;
        Ok: Boolean;
    begin
        V := true;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Boolean;
    begin
        V := true;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Boolean_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '|b0', '', 0);
        EvB(O, '|b9', '', 9);
        EvS(O, '|st', '');
        EvB(O, ' |b0', ' ', 0);
        EvB(O, ' |b9', ' ', 9);
        EvS(O, ' |st', ' ');
        EvB(O, 'Yes|b0', 'Yes', 0);
        EvB(O, 'Yes|b9', 'Yes', 9);
        EvS(O, 'Yes|st', 'Yes');
        EvB(O, 'No|b0', 'No', 0);
        EvB(O, 'No|b9', 'No', 9);
        EvS(O, 'No|st', 'No');
        EvB(O, 'yes|b0', 'yes', 0);
        EvB(O, 'yes|b9', 'yes', 9);
        EvS(O, 'yes|st', 'yes');
        EvB(O, 'YES|b0', 'YES', 0);
        EvB(O, 'YES|b9', 'YES', 9);
        EvS(O, 'YES|st', 'YES');
        EvB(O, 'true|b0', 'true', 0);
        EvB(O, 'true|b9', 'true', 9);
        EvS(O, 'true|st', 'true');
        EvB(O, 'false|b0', 'false', 0);
        EvB(O, 'false|b9', 'false', 9);
        EvS(O, 'false|st', 'false');
        EvB(O, 'True|b0', 'True', 0);
        EvB(O, 'True|b9', 'True', 9);
        EvS(O, 'True|st', 'True');
        EvB(O, 'FALSE|b0', 'FALSE', 0);
        EvB(O, 'FALSE|b9', 'FALSE', 9);
        EvS(O, 'FALSE|st', 'FALSE');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'No|true');
        O.Expect('|b9', 'No|true');
        O.Expect('|st', 'err:Evaluate|true');
        O.Expect(' |b0', 'No|true');
        O.Expect(' |b9', 'No|true');
        O.Expect(' |st', 'err:Evaluate|true');
        O.Expect('Yes|b0', 'Yes|true');
        O.Expect('Yes|b9', 'No|true');
        O.Expect('Yes|st', 'ok|true');
        O.Expect('No|b0', 'Yes|false');
        O.Expect('No|b9', 'No|true');
        O.Expect('No|st', 'ok|false');
        O.Expect('yes|b0', 'Yes|true');
        O.Expect('yes|b9', 'No|true');
        O.Expect('yes|st', 'ok|true');
        O.Expect('YES|b0', 'Yes|true');
        O.Expect('YES|b9', 'No|true');
        O.Expect('YES|st', 'ok|true');
        O.Expect('true|b0', 'Yes|true');
        O.Expect('true|b9', 'Yes|true');
        O.Expect('true|st', 'ok|true');
        O.Expect('false|b0', 'Yes|false');
        O.Expect('false|b9', 'Yes|false');
        O.Expect('false|st', 'ok|false');
        O.Expect('True|b0', 'Yes|true');
        O.Expect('True|b9', 'Yes|true');
        O.Expect('True|st', 'ok|true');
        O.Expect('FALSE|b0', 'Yes|false');
        O.Expect('FALSE|b9', 'Yes|false');
        O.Expect('FALSE|st', 'ok|false');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Boolean_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, '2|b0', '2', 0);
        EvB(O, '2|b9', '2', 9);
        EvS(O, '2|st', '2');
        EvB(O, 'Ja|b0', 'Ja', 0);
        EvB(O, 'Ja|b9', 'Ja', 9);
        EvS(O, 'Ja|st', 'Ja');
        EvB(O, 'Nein|b0', 'Nein', 0);
        EvB(O, 'Nein|b9', 'Nein', 9);
        EvS(O, 'Nein|st', 'Nein');
        EvB(O, 'y|b0', 'y', 0);
        EvB(O, 'y|b9', 'y', 9);
        EvS(O, 'y|st', 'y');
        EvB(O, 'n|b0', 'n', 0);
        EvB(O, 'n|b9', 'n', 9);
        EvS(O, 'n|st', 'n');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, 'Yes |b0', 'Yes ', 0);
        EvB(O, 'Yes |b9', 'Yes ', 9);
        EvS(O, 'Yes |st', 'Yes ');
        GlobalLanguage(Saved);
        O.Expect('1|b0', 'Yes|true');
        O.Expect('1|b9', 'Yes|true');
        O.Expect('1|st', 'ok|true');
        O.Expect('0|b0', 'Yes|false');
        O.Expect('0|b9', 'Yes|false');
        O.Expect('0|st', 'ok|false');
        O.Expect('-1|b0', 'No|true');
        O.Expect('-1|b9', 'No|true');
        O.Expect('-1|st', 'err:Evaluate|true');
        O.Expect('2|b0', 'No|true');
        O.Expect('2|b9', 'No|true');
        O.Expect('2|st', 'err:Evaluate|true');
        O.Expect('Ja|b0', 'No|true');
        O.Expect('Ja|b9', 'No|true');
        O.Expect('Ja|st', 'err:Evaluate|true');
        O.Expect('Nein|b0', 'No|true');
        O.Expect('Nein|b9', 'No|true');
        O.Expect('Nein|st', 'err:Evaluate|true');
        O.Expect('y|b0', 'Yes|true');
        O.Expect('y|b9', 'No|true');
        O.Expect('y|st', 'ok|true');
        O.Expect('n|b0', 'Yes|false');
        O.Expect('n|b9', 'No|true');
        O.Expect('n|st', 'ok|false');
        O.Expect('abc|b0', 'No|true');
        O.Expect('abc|b9', 'No|true');
        O.Expect('abc|st', 'err:Evaluate|true');
        O.Expect('Yes |b0', 'Yes|true');
        O.Expect('Yes |b9', 'No|true');
        O.Expect('Yes |st', 'ok|true');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Boolean_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, ' No|b0', ' No', 0);
        EvB(O, ' No|b9', ' No', 9);
        EvS(O, ' No|st', ' No');
        EvB(O, 'Y|b0', 'Y', 0);
        EvB(O, 'Y|b9', 'Y', 9);
        EvS(O, 'Y|st', 'Y');
        EvB(O, 'N|b0', 'N', 0);
        EvB(O, 'N|b9', 'N', 9);
        EvS(O, 'N|st', 'N');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, 'F|b0', 'F', 0);
        EvB(O, 'F|b9', 'F', 9);
        EvS(O, 'F|st', 'F');
        EvB(O, 'on|b0', 'on', 0);
        EvB(O, 'on|b9', 'on', 9);
        EvS(O, 'on|st', 'on');
        EvB(O, 'off|b0', 'off', 0);
        EvB(O, 'off|b9', 'off', 9);
        EvS(O, 'off|st', 'off');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Expect(' No|b0', 'Yes|false');
        O.Expect(' No|b9', 'No|true');
        O.Expect(' No|st', 'ok|false');
        O.Expect('Y|b0', 'Yes|true');
        O.Expect('Y|b9', 'No|true');
        O.Expect('Y|st', 'ok|true');
        O.Expect('N|b0', 'Yes|false');
        O.Expect('N|b9', 'No|true');
        O.Expect('N|st', 'ok|false');
        O.Expect('T|b0', 'Yes|true');
        O.Expect('T|b9', 'Yes|true');
        O.Expect('T|st', 'ok|true');
        O.Expect('F|b0', 'Yes|false');
        O.Expect('F|b9', 'Yes|false');
        O.Expect('F|st', 'ok|false');
        O.Expect('on|b0', 'No|true');
        O.Expect('on|b9', 'No|true');
        O.Expect('on|st', 'err:Evaluate|true');
        O.Expect('off|b0', 'No|true');
        O.Expect('off|b9', 'No|true');
        O.Expect('off|st', 'err:Evaluate|true');
        O.Expect('NUL|b0', 'No|true');
        O.Expect('NUL|b9', 'No|true');
        O.Expect('NUL|st', 'err:Evaluate|true');
        O.Expect('?|b0', 'No|true');
        O.Expect('?|b9', 'No|true');
        O.Expect('?|st', 'err:Evaluate|true');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Boolean_de_1()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '|b0', '', 0);
        EvB(O, '|b9', '', 9);
        EvS(O, '|st', '');
        EvB(O, ' |b0', ' ', 0);
        EvB(O, ' |b9', ' ', 9);
        EvS(O, ' |st', ' ');
        EvB(O, 'Yes|b0', 'Yes', 0);
        EvB(O, 'Yes|b9', 'Yes', 9);
        EvS(O, 'Yes|st', 'Yes');
        EvB(O, 'No|b0', 'No', 0);
        EvB(O, 'No|b9', 'No', 9);
        EvS(O, 'No|st', 'No');
        EvB(O, 'yes|b0', 'yes', 0);
        EvB(O, 'yes|b9', 'yes', 9);
        EvS(O, 'yes|st', 'yes');
        EvB(O, 'YES|b0', 'YES', 0);
        EvB(O, 'YES|b9', 'YES', 9);
        EvS(O, 'YES|st', 'YES');
        EvB(O, 'true|b0', 'true', 0);
        EvB(O, 'true|b9', 'true', 9);
        EvS(O, 'true|st', 'true');
        EvB(O, 'false|b0', 'false', 0);
        EvB(O, 'false|b9', 'false', 9);
        EvS(O, 'false|st', 'false');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Nein|true');
        O.Expect('|b9', 'Nein|true');
        O.Expect('|st', 'err:Evaluate|true');
        O.Expect(' |b0', 'Nein|true');
        O.Expect(' |b9', 'Nein|true');
        O.Expect(' |st', 'err:Evaluate|true');
        O.Expect('Yes|b0', 'Nein|true');
        O.Expect('Yes|b9', 'Nein|true');
        O.Expect('Yes|st', 'err:Evaluate|true');
        O.Expect('No|b0', 'Nein|true');
        O.Expect('No|b9', 'Nein|true');
        O.Expect('No|st', 'err:Evaluate|true');
        O.Expect('yes|b0', 'Nein|true');
        O.Expect('yes|b9', 'Nein|true');
        O.Expect('yes|st', 'err:Evaluate|true');
        O.Expect('YES|b0', 'Nein|true');
        O.Expect('YES|b9', 'Nein|true');
        O.Expect('YES|st', 'err:Evaluate|true');
        O.Expect('true|b0', 'Ja|true');
        O.Expect('true|b9', 'Ja|true');
        O.Expect('true|st', 'ok|true');
        O.Expect('false|b0', 'Ja|false');
        O.Expect('false|b9', 'Ja|false');
        O.Expect('false|st', 'ok|false');
        O.Verify();
    end;
}
