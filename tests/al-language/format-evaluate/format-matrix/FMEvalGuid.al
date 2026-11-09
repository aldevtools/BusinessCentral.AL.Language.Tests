// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Guid. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72860 "LT FM Eval Guid"
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
    local procedure TryEv(Txt: Text; var V: Guid)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Guid;
        Ok: Boolean;
    begin
        Clear(V);
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Guid;
    begin
        Clear(V);
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Guid_1()
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
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678}|b0', '{12345678-1234-5678-9ABC-DEF012345678}', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678}|b9', '{12345678-1234-5678-9ABC-DEF012345678}', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF012345678}|st', '{12345678-1234-5678-9ABC-DEF012345678}');
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678|b0', '12345678-1234-5678-9ABC-DEF012345678', 0);
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678|b9', '12345678-1234-5678-9ABC-DEF012345678', 9);
        EvS(O, '12345678-1234-5678-9ABC-DEF012345678|st', '12345678-1234-5678-9ABC-DEF012345678');
        EvB(O, '{12345678-1234-5678-9abc-def012345678}|b0', '{12345678-1234-5678-9abc-def012345678}', 0);
        EvB(O, '{12345678-1234-5678-9abc-def012345678}|b9', '{12345678-1234-5678-9abc-def012345678}', 9);
        EvS(O, '{12345678-1234-5678-9abc-def012345678}|st', '{12345678-1234-5678-9abc-def012345678}');
        EvB(O, '12345678123456789ABCDEF012345678|b0', '12345678123456789ABCDEF012345678', 0);
        EvB(O, '12345678123456789ABCDEF012345678|b9', '12345678123456789ABCDEF012345678', 9);
        EvS(O, '12345678123456789ABCDEF012345678|st', '12345678123456789ABCDEF012345678');
        EvB(O, '{00000000-0000-0000-0000-000000000000}|b0', '{00000000-0000-0000-0000-000000000000}', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '{00000000-0000-0000-0000-000000000000}|b9', '{00000000-0000-0000-0000-000000000000}', 9);
        EvS(O, '{00000000-0000-0000-0000-000000000000}|st', '{00000000-0000-0000-0000-000000000000}');
        EvB(O, '00000000-0000-0000-0000-000000000000|b0', '00000000-0000-0000-0000-000000000000', 0);
        EvB(O, '00000000-0000-0000-0000-000000000000|b9', '00000000-0000-0000-0000-000000000000', 9);
        EvS(O, '00000000-0000-0000-0000-000000000000|st', '00000000-0000-0000-0000-000000000000');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, '{12345678-1234-5678-9ABC-DEF01234567}|b0', '{12345678-1234-5678-9ABC-DEF01234567}', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF01234567}|b9', '{12345678-1234-5678-9ABC-DEF01234567}', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF01234567}|st', '{12345678-1234-5678-9ABC-DEF01234567}');
        EvB(O, '{12345678-1234-5678-9ABC-DEF0123456789}|b0', '{12345678-1234-5678-9ABC-DEF0123456789}', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF0123456789}|b9', '{12345678-1234-5678-9ABC-DEF0123456789}', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF0123456789}|st', '{12345678-1234-5678-9ABC-DEF0123456789}');
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678|b0', '{12345678-1234-5678-9ABC-DEF012345678', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678|b9', '{12345678-1234-5678-9ABC-DEF012345678', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF012345678|st', '{12345678-1234-5678-9ABC-DEF012345678');
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678}|b0', '12345678-1234-5678-9ABC-DEF012345678}', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678}|b9', '12345678-1234-5678-9ABC-DEF012345678}', 9);
        EvS(O, '12345678-1234-5678-9ABC-DEF012345678}|st', '12345678-1234-5678-9ABC-DEF012345678}');
        EvB(O, '{GGGGGGGG-1234-5678-9ABC-DEF012345678}|b0', '{GGGGGGGG-1234-5678-9ABC-DEF012345678}', 0);
        EvB(O, '{GGGGGGGG-1234-5678-9ABC-DEF012345678}|b9', '{GGGGGGGG-1234-5678-9ABC-DEF012345678}', 9);
        EvS(O, '{GGGGGGGG-1234-5678-9ABC-DEF012345678}|st', '{GGGGGGGG-1234-5678-9ABC-DEF012345678}');
        EvB(O, ' {12345678-1234-5678-9ABC-DEF012345678}|b0', ' {12345678-1234-5678-9ABC-DEF012345678}', 0);
        EvB(O, ' {12345678-1234-5678-9ABC-DEF012345678}|b9', ' {12345678-1234-5678-9ABC-DEF012345678}', 9);
        EvS(O, ' {12345678-1234-5678-9ABC-DEF012345678}|st', ' {12345678-1234-5678-9ABC-DEF012345678}');
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678} |b0', '{12345678-1234-5678-9ABC-DEF012345678} ', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678} |b9', '{12345678-1234-5678-9ABC-DEF012345678} ', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF012345678} |st', '{12345678-1234-5678-9ABC-DEF012345678} ');
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
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_de_1()
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
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678}|b0', '{12345678-1234-5678-9ABC-DEF012345678}', 0);
        EvB(O, '{12345678-1234-5678-9ABC-DEF012345678}|b9', '{12345678-1234-5678-9ABC-DEF012345678}', 9);
        EvS(O, '{12345678-1234-5678-9ABC-DEF012345678}|st', '{12345678-1234-5678-9ABC-DEF012345678}');
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678|b0', '12345678-1234-5678-9ABC-DEF012345678', 0);
        EvB(O, '12345678-1234-5678-9ABC-DEF012345678|b9', '12345678-1234-5678-9ABC-DEF012345678', 9);
        EvS(O, '12345678-1234-5678-9ABC-DEF012345678|st', '12345678-1234-5678-9ABC-DEF012345678');
        EvB(O, '{12345678-1234-5678-9abc-def012345678}|b0', '{12345678-1234-5678-9abc-def012345678}', 0);
        EvB(O, '{12345678-1234-5678-9abc-def012345678}|b9', '{12345678-1234-5678-9abc-def012345678}', 9);
        EvS(O, '{12345678-1234-5678-9abc-def012345678}|st', '{12345678-1234-5678-9abc-def012345678}');
        EvB(O, '12345678123456789ABCDEF012345678|b0', '12345678123456789ABCDEF012345678', 0);
        EvB(O, '12345678123456789ABCDEF012345678|b9', '12345678123456789ABCDEF012345678', 9);
        EvS(O, '12345678123456789ABCDEF012345678|st', '12345678123456789ABCDEF012345678');
        EvB(O, '{00000000-0000-0000-0000-000000000000}|b0', '{00000000-0000-0000-0000-000000000000}', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Guid_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '{00000000-0000-0000-0000-000000000000}|b9', '{00000000-0000-0000-0000-000000000000}', 9);
        EvS(O, '{00000000-0000-0000-0000-000000000000}|st', '{00000000-0000-0000-0000-000000000000}');
        EvB(O, '00000000-0000-0000-0000-000000000000|b0', '00000000-0000-0000-0000-000000000000', 0);
        EvB(O, '00000000-0000-0000-0000-000000000000|b9', '00000000-0000-0000-0000-000000000000', 9);
        EvS(O, '00000000-0000-0000-0000-000000000000|st', '00000000-0000-0000-0000-000000000000');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
