// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Date. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72841 "LT FM Eval Date"
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
    local procedure TryEv(Txt: Text; var V: Date)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Date;
        Ok: Boolean;
    begin
        V := 20000101D;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Date;
    begin
        V := 20000101D;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Date_1()
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
        EvB(O, '0D|b0', '0D', 0);
        EvB(O, '0D|b9', '0D', 9);
        EvS(O, '0D|st', '0D');
        EvB(O, 'D|b0', 'D', 0);
        EvB(O, 'D|b9', 'D', 9);
        EvS(O, 'D|st', 'D');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, '12/09/26|b0', '12/09/26', 0);
        EvB(O, '12/09/26|b9', '12/09/26', 9);
        EvS(O, '12/09/26|st', '12/09/26');
        EvB(O, '12/09/26D|b0', '12/09/26D', 0);
        EvB(O, '12/09/26D|b9', '12/09/26D', 9);
        EvS(O, '12/09/26D|st', '12/09/26D');
        EvB(O, '12/09/26T|b0', '12/09/26T', 0);
        EvB(O, '12/09/26T|b9', '12/09/26T', 9);
        EvS(O, '12/09/26T|st', '12/09/26T');
        EvB(O, '12/09/2026D|b0', '12/09/2026D', 0);
        EvB(O, '12/09/2026D|b9', '12/09/2026D', 9);
        EvS(O, '12/09/2026D|st', '12/09/2026D');
        EvB(O, '12.09.26D|b0', '12.09.26D', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '12.09.26D|b9', '12.09.26D', 9);
        EvS(O, '12.09.26D|st', '12.09.26D');
        EvB(O, '12/09/26 D|b0', '12/09/26 D', 0);
        EvB(O, '12/09/26 D|b9', '12/09/26 D', 9);
        EvS(O, '12/09/26 D|st', '12/09/26 D');
        EvB(O, '32/01/26|b0', '32/01/26', 0);
        EvB(O, '32/01/26|b9', '32/01/26', 9);
        EvS(O, '32/01/26|st', '32/01/26');
        EvB(O, '02/30/26|b0', '02/30/26', 0);
        EvB(O, '02/30/26|b9', '02/30/26', 9);
        EvS(O, '02/30/26|st', '02/30/26');
        EvB(O, '00/00/00|b0', '00/00/00', 0);
        EvB(O, '00/00/00|b9', '00/00/00', 9);
        EvS(O, '00/00/00|st', '00/00/00');
        EvB(O, '13/01/26|b0', '13/01/26', 0);
        EvB(O, '13/01/26|b9', '13/01/26', 9);
        EvS(O, '13/01/26|st', '13/01/26');
        EvB(O, '01/13/26|b0', '01/13/26', 0);
        EvB(O, '01/13/26|b9', '01/13/26', 9);
        EvS(O, '01/13/26|st', '01/13/26');
        EvB(O, '1/1/1753|b0', '1/1/1753', 0);
        EvB(O, '1/1/1753|b9', '1/1/1753', 9);
        EvS(O, '1/1/1753|st', '1/1/1753');
        EvB(O, '12/31/9999|b0', '12/31/9999', 0);
        EvB(O, '12/31/9999|b9', '12/31/9999', 9);
        EvS(O, '12/31/9999|st', '12/31/9999');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '1/1/0001|b0', '1/1/0001', 0);
        EvB(O, '1/1/0001|b9', '1/1/0001', 9);
        EvS(O, '1/1/0001|st', '1/1/0001');
        EvB(O, '12/31/10000|b0', '12/31/10000', 0);
        EvB(O, '12/31/10000|b9', '12/31/10000', 9);
        EvS(O, '12/31/10000|st', '12/31/10000');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, '<=11/09/26|b0', '<=11/09/26', 0);
        EvB(O, '<=11/09/26|b9', '<=11/09/26', 9);
        EvS(O, '<=11/09/26|st', '<=11/09/26');
        EvB(O, '>=11/09/26|b0', '>=11/09/26', 0);
        EvB(O, '>=11/09/26|b9', '>=11/09/26', 9);
        EvS(O, '>=11/09/26|st', '>=11/09/26');
        EvB(O, '11/09/26..12/09/26|b0', '11/09/26..12/09/26', 0);
        EvB(O, '11/09/26..12/09/26|b9', '11/09/26..12/09/26', 9);
        EvS(O, '11/09/26..12/09/26|st', '11/09/26..12/09/26');
        EvB(O, '%today|b0', '%today', 0);
        EvB(O, '%today|b9', '%today', 9);
        EvS(O, '%today|st', '%today');
        EvB(O, 'W|b0', 'W', 0);
        EvB(O, 'W|b9', 'W', 9);
        EvS(O, 'W|st', 'W');
        EvB(O, '1D|b0', '1D', 0);
        EvB(O, '1D|b9', '1D', 9);
        EvS(O, '1D|st', '1D');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'CM|b0', 'CM', 0);
        EvB(O, 'CM|b9', 'CM', 9);
        EvS(O, 'CM|st', 'CM');
        EvB(O, '12-09-26|b0', '12-09-26', 0);
        EvB(O, '12-09-26|b9', '12-09-26', 9);
        EvS(O, '12-09-26|st', '12-09-26');
        EvB(O, '2026-12-09|b0', '2026-12-09', 0);
        EvB(O, '2026-12-09|b9', '2026-12-09', 9);
        EvS(O, '2026-12-09|st', '2026-12-09');
        EvB(O, '20261209|b0', '20261209', 0);
        EvB(O, '20261209|b9', '20261209', 9);
        EvS(O, '20261209|st', '20261209');
        EvB(O, '121226|b0', '121226', 0);
        EvB(O, '121226|b9', '121226', 9);
        EvS(O, '121226|st', '121226');
        EvB(O, '12/09|b0', '12/09', 0);
        EvB(O, '12/09|b9', '12/09', 9);
        EvS(O, '12/09|st', '12/09');
        EvB(O, '12|b0', '12', 0);
        EvB(O, '12|b9', '12', 9);
        EvS(O, '12|st', '12');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, 'Monday|b0', 'Monday', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_5()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'Monday|b9', 'Monday', 9);
        EvS(O, 'Monday|st', 'Monday');
        EvB(O, '9 Mar 2026|b0', '9 Mar 2026', 0);
        EvB(O, '9 Mar 2026|b9', '9 Mar 2026', 9);
        EvS(O, '9 Mar 2026|st', '9 Mar 2026');
        EvB(O, 'March 9, 2026|b0', 'March 9, 2026', 0);
        EvB(O, 'March 9, 2026|b9', 'March 9, 2026', 9);
        EvS(O, 'March 9, 2026|st', 'March 9, 2026');
        EvB(O, '12/09/26 12:00|b0', '12/09/26 12:00', 0);
        EvB(O, '12/09/26 12:00|b9', '12/09/26 12:00', 9);
        EvS(O, '12/09/26 12:00|st', '12/09/26 12:00');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_de_1()
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
        EvB(O, '0D|b0', '0D', 0);
        EvB(O, '0D|b9', '0D', 9);
        EvS(O, '0D|st', '0D');
        EvB(O, 'D|b0', 'D', 0);
        EvB(O, 'D|b9', 'D', 9);
        EvS(O, 'D|st', 'D');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, '12/09/26|b0', '12/09/26', 0);
        EvB(O, '12/09/26|b9', '12/09/26', 9);
        EvS(O, '12/09/26|st', '12/09/26');
        EvB(O, '12/09/26D|b0', '12/09/26D', 0);
        EvB(O, '12/09/26D|b9', '12/09/26D', 9);
        EvS(O, '12/09/26D|st', '12/09/26D');
        EvB(O, '12/09/26T|b0', '12/09/26T', 0);
        EvB(O, '12/09/26T|b9', '12/09/26T', 9);
        EvS(O, '12/09/26T|st', '12/09/26T');
        EvB(O, '12/09/2026D|b0', '12/09/2026D', 0);
        EvB(O, '12/09/2026D|b9', '12/09/2026D', 9);
        EvS(O, '12/09/2026D|st', '12/09/2026D');
        EvB(O, '12.09.26D|b0', '12.09.26D', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Date_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '12.09.26D|b9', '12.09.26D', 9);
        EvS(O, '12.09.26D|st', '12.09.26D');
        EvB(O, 'Monday|b0', 'Monday', 0);
        EvB(O, 'Monday|b9', 'Monday', 9);
        EvS(O, 'Monday|st', 'Monday');
        EvB(O, '9 Mar 2026|b0', '9 Mar 2026', 0);
        EvB(O, '9 Mar 2026|b9', '9 Mar 2026', 9);
        EvS(O, '9 Mar 2026|st', '9 Mar 2026');
        EvB(O, 'March 9, 2026|b0', 'March 9, 2026', 0);
        EvB(O, 'March 9, 2026|b9', 'March 9, 2026', 9);
        EvS(O, 'March 9, 2026|st', 'March 9, 2026');
        EvB(O, '12/09/26 12:00|b0', '12/09/26 12:00', 0);
        EvB(O, '12/09/26 12:00|b9', '12/09/26 12:00', 9);
        EvS(O, '12/09/26 12:00|st', '12/09/26 12:00');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
