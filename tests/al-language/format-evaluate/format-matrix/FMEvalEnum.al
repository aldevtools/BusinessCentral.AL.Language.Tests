// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Enum. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72858 "LT FM Eval Enum"
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
    local procedure TryEv(Txt: Text; var V: Enum "Warehouse Activity Type")
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Enum "Warehouse Activity Type";
        Ok: Boolean;
    begin
        V := Enum::"Warehouse Activity Type"::Pick;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Enum "Warehouse Activity Type";
    begin
        V := Enum::"Warehouse Activity Type"::Pick;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9) + '/' + Format(V))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    [Test]
    procedure Evaluate_Enum_1()
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
        EvB(O, 'Put-away|b0', 'Put-away', 0);
        EvB(O, 'Put-away|b9', 'Put-away', 9);
        EvS(O, 'Put-away|st', 'Put-away');
        EvB(O, 'put-away|b0', 'put-away', 0);
        EvB(O, 'put-away|b9', 'put-away', 9);
        EvS(O, 'put-away|st', 'put-away');
        EvB(O, 'PUT-AWAY|b0', 'PUT-AWAY', 0);
        EvB(O, 'PUT-AWAY|b9', 'PUT-AWAY', 9);
        EvS(O, 'PUT-AWAY|st', 'PUT-AWAY');
        EvB(O, 'Pick|b0', 'Pick', 0);
        EvB(O, 'Pick|b9', 'Pick', 9);
        EvS(O, 'Pick|st', 'Pick');
        EvB(O, 'Movement|b0', 'Movement', 0);
        EvB(O, 'Movement|b9', 'Movement', 9);
        EvS(O, 'Movement|st', 'Movement');
        EvB(O, 'Invt. Pick|b0', 'Invt. Pick', 0);
        EvB(O, 'Invt. Pick|b9', 'Invt. Pick', 9);
        EvS(O, 'Invt. Pick|st', 'Invt. Pick');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, '2|b0', '2', 0);
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Yes|0/ ');
        O.Expect('|b9', 'Yes|0/ ');
        O.Expect('|st', 'ok|0/ ');
        O.Expect(' |b0', 'Yes|0/ ');
        O.Expect(' |b9', 'Yes|0/ ');
        O.Expect(' |st', 'ok|0/ ');
        O.Expect('Put-away|b0', 'Yes|1/Put-away');
        O.Expect('Put-away|b9', 'Yes|1/Put-away');
        O.Expect('Put-away|st', 'ok|1/Put-away');
        O.Expect('put-away|b0', 'Yes|1/Put-away');
        O.Expect('put-away|b9', 'Yes|1/Put-away');
        O.Expect('put-away|st', 'ok|1/Put-away');
        O.Expect('PUT-AWAY|b0', 'Yes|1/Put-away');
        O.Expect('PUT-AWAY|b9', 'Yes|1/Put-away');
        O.Expect('PUT-AWAY|st', 'ok|1/Put-away');
        O.Expect('Pick|b0', 'Yes|2/Pick');
        O.Expect('Pick|b9', 'Yes|2/Pick');
        O.Expect('Pick|st', 'ok|2/Pick');
        O.Expect('Movement|b0', 'Yes|3/Movement');
        O.Expect('Movement|b9', 'Yes|3/Movement');
        O.Expect('Movement|st', 'ok|3/Movement');
        O.Expect('Invt. Pick|b0', 'Yes|5/Invt. Pick');
        O.Expect('Invt. Pick|b9', 'Yes|5/Invt. Pick');
        O.Expect('Invt. Pick|st', 'ok|5/Invt. Pick');
        O.Expect('1|b0', 'Yes|1/Put-away');
        O.Expect('1|b9', 'Yes|1/Put-away');
        O.Expect('1|st', 'ok|1/Put-away');
        O.Expect('2|b0', 'Yes|2/Pick');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Enum_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '2|b9', '2', 9);
        EvS(O, '2|st', '2');
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '99|b0', '99', 0);
        EvB(O, '99|b9', '99', 9);
        EvS(O, '99|st', '99');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, '1.0|b0', '1.0', 0);
        EvB(O, '1.0|b9', '1.0', 9);
        EvS(O, '1.0|st', '1.0');
        EvB(O, ' 1|b0', ' 1', 0);
        EvB(O, ' 1|b9', ' 1', 9);
        EvS(O, ' 1|st', ' 1');
        EvB(O, '1 |b0', '1 ', 0);
        EvB(O, '1 |b9', '1 ', 9);
        EvS(O, '1 |st', '1 ');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, 'Put_away|b0', 'Put_away', 0);
        EvB(O, 'Put_away|b9', 'Put_away', 9);
        EvS(O, 'Put_away|st', 'Put_away');
        EvB(O, 'Putaway|b0', 'Putaway', 0);
        EvB(O, 'Putaway|b9', 'Putaway', 9);
        EvS(O, 'Putaway|st', 'Putaway');
        GlobalLanguage(Saved);
        O.Expect('2|b9', 'Yes|2/Pick');
        O.Expect('2|st', 'ok|2/Pick');
        O.Expect('0|b0', 'Yes|0/ ');
        O.Expect('0|b9', 'Yes|0/ ');
        O.Expect('0|st', 'ok|0/ ');
        O.Expect('99|b0', 'Yes|99/99');
        O.Expect('99|b9', 'Yes|99/99');
        O.Expect('99|st', 'ok|99/99');
        O.Expect('-1|b0', 'No|2/Pick');
        O.Expect('-1|b9', 'No|2/Pick');
        O.Expect('-1|st', 'err:InvalidOptionString|2/Pick');
        O.Expect('1.0|b0', 'No|2/Pick');
        O.Expect('1.0|b9', 'No|2/Pick');
        O.Expect('1.0|st', 'err:InvalidOptionString|2/Pick');
        O.Expect(' 1|b0', 'Yes|1/Put-away');
        O.Expect(' 1|b9', 'Yes|1/Put-away');
        O.Expect(' 1|st', 'ok|1/Put-away');
        O.Expect('1 |b0', 'Yes|1/Put-away');
        O.Expect('1 |b9', 'Yes|1/Put-away');
        O.Expect('1 |st', 'ok|1/Put-away');
        O.Expect('abc|b0', 'No|2/Pick');
        O.Expect('abc|b9', 'No|2/Pick');
        O.Expect('abc|st', 'err:InvalidOptionString|2/Pick');
        O.Expect('Put_away|b0', 'No|2/Pick');
        O.Expect('Put_away|b9', 'No|2/Pick');
        O.Expect('Put_away|st', 'err:InvalidOptionString|2/Pick');
        O.Expect('Putaway|b0', 'No|2/Pick');
        O.Expect('Putaway|b9', 'No|2/Pick');
        O.Expect('Putaway|st', 'err:InvalidOptionString|2/Pick');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Enum_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'Put-away |b0', 'Put-away ', 0);
        EvB(O, 'Put-away |b9', 'Put-away ', 9);
        EvS(O, 'Put-away |st', 'Put-away ');
        EvB(O, ' Put-away|b0', ' Put-away', 0);
        EvB(O, ' Put-away|b9', ' Put-away', 9);
        EvS(O, ' Put-away|st', ' Put-away');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        EvB(O, '1T|b0', '1T', 0);
        EvB(O, '1T|b9', '1T', 9);
        EvS(O, '1T|st', '1T');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Expect('Put-away |b0', 'Yes|1/Put-away');
        O.Expect('Put-away |b9', 'Yes|1/Put-away');
        O.Expect('Put-away |st', 'ok|1/Put-away');
        O.Expect(' Put-away|b0', 'Yes|1/Put-away');
        O.Expect(' Put-away|b9', 'Yes|1/Put-away');
        O.Expect(' Put-away|st', 'ok|1/Put-away');
        O.Expect('1D|b0', 'No|2/Pick');
        O.Expect('1D|b9', 'No|2/Pick');
        O.Expect('1D|st', 'err:InvalidOptionString|2/Pick');
        O.Expect('1T|b0', 'No|2/Pick');
        O.Expect('1T|b9', 'No|2/Pick');
        O.Expect('1T|st', 'err:InvalidOptionString|2/Pick');
        O.Expect('NUL|b0', 'Yes|0/ ');
        O.Expect('NUL|b9', 'Yes|0/ ');
        O.Expect('NUL|st', 'ok|0/ ');
        O.Expect('?|b0', 'No|2/Pick');
        O.Expect('?|b9', 'No|2/Pick');
        O.Expect('?|st', 'err:InvalidOptionString|2/Pick');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_Enum_de_1()
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
        EvB(O, 'Put-away|b0', 'Put-away', 0);
        EvB(O, 'Put-away|b9', 'Put-away', 9);
        EvS(O, 'Put-away|st', 'Put-away');
        EvB(O, 'put-away|b0', 'put-away', 0);
        EvB(O, 'put-away|b9', 'put-away', 9);
        EvS(O, 'put-away|st', 'put-away');
        EvB(O, 'PUT-AWAY|b0', 'PUT-AWAY', 0);
        EvB(O, 'PUT-AWAY|b9', 'PUT-AWAY', 9);
        EvS(O, 'PUT-AWAY|st', 'PUT-AWAY');
        EvB(O, 'Pick|b0', 'Pick', 0);
        EvB(O, 'Pick|b9', 'Pick', 9);
        EvS(O, 'Pick|st', 'Pick');
        EvB(O, 'Movement|b0', 'Movement', 0);
        EvB(O, 'Movement|b9', 'Movement', 9);
        EvS(O, 'Movement|st', 'Movement');
        EvB(O, 'Invt. Pick|b0', 'Invt. Pick', 0);
        EvB(O, 'Invt. Pick|b9', 'Invt. Pick', 9);
        EvS(O, 'Invt. Pick|st', 'Invt. Pick');
        GlobalLanguage(Saved);
        O.Expect('|b0', 'Ja|0/ ');
        O.Expect('|b9', 'Ja|0/ ');
        O.Expect('|st', 'ok|0/ ');
        O.Expect(' |b0', 'Ja|0/ ');
        O.Expect(' |b9', 'Ja|0/ ');
        O.Expect(' |st', 'ok|0/ ');
        O.Expect('Put-away|b0', 'Ja|1/Put-away');
        O.Expect('Put-away|b9', 'Ja|1/Put-away');
        O.Expect('Put-away|st', 'ok|1/Put-away');
        O.Expect('put-away|b0', 'Ja|1/Put-away');
        O.Expect('put-away|b9', 'Ja|1/Put-away');
        O.Expect('put-away|st', 'ok|1/Put-away');
        O.Expect('PUT-AWAY|b0', 'Ja|1/Put-away');
        O.Expect('PUT-AWAY|b9', 'Ja|1/Put-away');
        O.Expect('PUT-AWAY|st', 'ok|1/Put-away');
        O.Expect('Pick|b0', 'Ja|2/Pick');
        O.Expect('Pick|b9', 'Ja|2/Pick');
        O.Expect('Pick|st', 'ok|2/Pick');
        O.Expect('Movement|b0', 'Ja|3/Movement');
        O.Expect('Movement|b9', 'Ja|3/Movement');
        O.Expect('Movement|st', 'ok|3/Movement');
        O.Expect('Invt. Pick|b0', 'Ja|5/Invt. Pick');
        O.Expect('Invt. Pick|b9', 'Ja|5/Invt. Pick');
        O.Expect('Invt. Pick|st', 'ok|5/Invt. Pick');
        O.Verify();
    end;
}
