// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Char. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72861 "LT FM Eval Char"
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
    local procedure TryEv(Txt: Text; var V: Char)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Char;
        Ok: Boolean;
    begin
        V := 90;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Char;
    begin
        V := 90;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9) + '/' + Format(V))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    [Test]
    procedure Evaluate_Char_1()
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
        EvB(O, 'A|b0', 'A', 0);
        EvB(O, 'A|b9', 'A', 9);
        EvS(O, 'A|st', 'A');
        EvB(O, 'AB|b0', 'AB', 0);
        EvB(O, 'AB|b9', 'AB', 9);
        EvS(O, 'AB|st', 'AB');
        EvB(O, '65|b0', '65', 0);
        EvB(O, '65|b9', '65', 9);
        EvS(O, '65|st', '65');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '256|b0', '256', 0);
        EvB(O, '256|b9', '256', 9);
        EvS(O, '256|st', '256');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, 'é|b0', 'é', 0);
        EvB(O, 'é|b9', 'é', 9);
        EvS(O, 'é|st', 'é');
        EvB(O, '¶|b0', '¶', 0);
        EvB(O, '¶|b9', '¶', 9);
        EvS(O, '¶|st', '¶');
        EvB(O, '€|b0', '€', 0);
        GlobalLanguage(Saved);
        O.Expect('|b0', 'No|Z/Z');
        O.Expect('|b9', 'No|Z/Z');
        O.Expect('|st', 'err:Evaluate|Z/Z');
        O.Expect(' |b0', 'Yes| / ');
        O.Expect(' |b9', 'Yes| / ');
        O.Expect(' |st', 'ok| / ');
        O.Expect('A|b0', 'Yes|A/A');
        O.Expect('A|b9', 'Yes|A/A');
        O.Expect('A|st', 'ok|A/A');
        O.Expect('AB|b0', 'No|Z/Z');
        O.Expect('AB|b9', 'No|Z/Z');
        O.Expect('AB|st', 'err:Evaluate|Z/Z');
        O.Expect('65|b0', 'No|Z/Z');
        O.Expect('65|b9', 'No|Z/Z');
        O.Expect('65|st', 'err:Evaluate|Z/Z');
        O.Expect('0|b0', 'Yes|0/0');
        O.Expect('0|b9', 'Yes|0/0');
        O.Expect('0|st', 'ok|0/0');
        O.Expect('256|b0', 'No|Z/Z');
        O.Expect('256|b9', 'No|Z/Z');
        O.Expect('256|st', 'err:Evaluate|Z/Z');
        O.Expect('-1|b0', 'No|Z/Z');
        O.Expect('-1|b9', 'No|Z/Z');
        O.Expect('-1|st', 'err:Evaluate|Z/Z');
        O.Expect('é|b0', 'Yes|é/é');
        O.Expect('é|b9', 'Yes|é/é');
        O.Expect('é|st', 'ok|é/é');
        O.Expect('¶|b0', 'Yes|¶/¶');
        O.Expect('¶|b9', 'Yes|¶/¶');
        O.Expect('¶|st', 'ok|¶/¶');
        O.Expect('€|b0', 'Yes|€/€');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Char_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '€|b9', '€', 9);
        EvS(O, '€|st', '€');
        EvB(O, 'a b|b0', 'a b', 0);
        EvB(O, 'a b|b9', 'a b', 9);
        EvS(O, 'a b|st', 'a b');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        EvB(O, '1T|b0', '1T', 0);
        EvB(O, '1T|b9', '1T', 9);
        EvS(O, '1T|st', '1T');
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        GlobalLanguage(Saved);
        O.Expect('€|b9', 'Yes|€/€');
        O.Expect('€|st', 'ok|€/€');
        O.Expect('a b|b0', 'No|Z/Z');
        O.Expect('a b|b9', 'No|Z/Z');
        O.Expect('a b|st', 'err:Evaluate|Z/Z');
        O.Expect('1D|b0', 'No|Z/Z');
        O.Expect('1D|b9', 'No|Z/Z');
        O.Expect('1D|st', 'err:Evaluate|Z/Z');
        O.Expect('1T|b0', 'No|Z/Z');
        O.Expect('1T|b9', 'No|Z/Z');
        O.Expect('1T|st', 'err:Evaluate|Z/Z');
        O.Expect('?|b0', 'Yes|?/?');
        O.Expect('?|b9', 'Yes|?/?');
        O.Expect('?|st', 'ok|?/?');
        O.Expect('NUL|b0', 'Yes|\u0000/\u0000');
        O.Expect('NUL|b9', 'Yes|\u0000/\u0000');
        O.Expect('NUL|st', 'ok|\u0000/\u0000');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Char_de_1()
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
        EvB(O, 'A|b0', 'A', 0);
        EvB(O, 'A|b9', 'A', 9);
        EvS(O, 'A|st', 'A');
        EvB(O, 'AB|b0', 'AB', 0);
        EvB(O, 'AB|b9', 'AB', 9);
        EvS(O, 'AB|st', 'AB');
        EvB(O, '65|b0', '65', 0);
        EvB(O, '65|b9', '65', 9);
        EvS(O, '65|st', '65');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '256|b0', '256', 0);
        EvB(O, '256|b9', '256', 9);
        EvS(O, '256|st', '256');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Nein|Z/Z');
        O.Expect('|b9', 'Nein|Z/Z');
        O.Expect('|st', 'err:Evaluate|Z/Z');
        O.Expect(' |b0', 'Ja| / ');
        O.Expect(' |b9', 'Ja| / ');
        O.Expect(' |st', 'ok| / ');
        O.Expect('A|b0', 'Ja|A/A');
        O.Expect('A|b9', 'Ja|A/A');
        O.Expect('A|st', 'ok|A/A');
        O.Expect('AB|b0', 'Nein|Z/Z');
        O.Expect('AB|b9', 'Nein|Z/Z');
        O.Expect('AB|st', 'err:Evaluate|Z/Z');
        O.Expect('65|b0', 'Nein|Z/Z');
        O.Expect('65|b9', 'Nein|Z/Z');
        O.Expect('65|st', 'err:Evaluate|Z/Z');
        O.Expect('0|b0', 'Ja|0/0');
        O.Expect('0|b9', 'Ja|0/0');
        O.Expect('0|st', 'ok|0/0');
        O.Expect('256|b0', 'Nein|Z/Z');
        O.Expect('256|b9', 'Nein|Z/Z');
        O.Expect('256|st', 'err:Evaluate|Z/Z');
        O.Expect('-1|b0', 'Nein|Z/Z');
        O.Expect('-1|b9', 'Nein|Z/Z');
        O.Expect('-1|st', 'err:Evaluate|Z/Z');
        O.Verify();
    end;
}
