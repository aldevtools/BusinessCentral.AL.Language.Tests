// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Code3. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72863 "LT FM Eval Code3"
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
    local procedure TryEv(Txt: Text; var V: Code[3])
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Code[3];
        Ok: Boolean;
    begin
        V := 'SEN';
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Code[3];
    begin
        V := 'SEN';
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Code3_1()
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
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, ' abc |b0', ' abc ', 0);
        EvB(O, ' abc |b9', ' abc ', 9);
        EvS(O, ' abc |st', ' abc ');
        EvB(O, 'a,b|b0', 'a,b', 0);
        EvB(O, 'a,b|b9', 'a,b', 9);
        EvS(O, 'a,b|st', 'a,b');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        EvB(O, '1T|b0', '1T', 0);
        EvB(O, '1T|b9', '1T', 9);
        EvS(O, '1T|st', '1T');
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ|b0', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 0);
        EvB(O, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ|b9', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ', 9);
        EvS(O, 'ABCDEFGHIJKLMNOPQRSTUVWXYZ|st', 'ABCDEFGHIJKLMNOPQRSTUVWXYZ');
        EvB(O, 'ä|b0', 'ä', 0);
        EvB(O, 'ä|b9', 'ä', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Code3_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, 'ä|st', 'ä');
        EvB(O, '"q"|b0', '"q"', 0);
        EvB(O, '"q"|b9', '"q"', 9);
        EvS(O, '"q"|st', '"q"');
        EvB(O, 'it''s|b0', 'it''s', 0);
        EvB(O, 'it''s|b9', 'it''s', 9);
        EvS(O, 'it''s|st', 'it''s');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Code3_de_1()
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
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, ' abc |b0', ' abc ', 0);
        EvB(O, ' abc |b9', ' abc ', 9);
        EvS(O, ' abc |st', ' abc ');
        EvB(O, 'a,b|b0', 'a,b', 0);
        EvB(O, 'a,b|b9', 'a,b', 9);
        EvS(O, 'a,b|st', 'a,b');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        EvB(O, '1T|b0', '1T', 0);
        EvB(O, '1T|b9', '1T', 9);
        EvS(O, '1T|st', '1T');
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
