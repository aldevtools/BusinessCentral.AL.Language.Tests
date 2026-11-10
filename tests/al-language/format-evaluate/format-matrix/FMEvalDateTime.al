// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of DateTime. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72843 "LT FM Eval DateTime"
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
    local procedure TryEv(Txt: Text; var V: DateTime)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: DateTime;
        Ok: Boolean;
    begin
        V := CreateDateTime(20000101D, 070809T);
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: DateTime;
    begin
        V := CreateDateTime(20000101D, 070809T);
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_DateTime_1()
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
        EvB(O, '0DT|b0', '0DT', 0);
        EvB(O, '0DT|b9', '0DT', 9);
        EvS(O, '0DT|st', '0DT');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, 'D|b0', 'D', 0);
        EvB(O, 'D|b9', 'D', 9);
        EvS(O, 'D|st', 'D');
        EvB(O, '01/01/26|b0', '01/01/26', 0);
        EvB(O, '01/01/26|b9', '01/01/26', 9);
        EvS(O, '01/01/26|st', '01/01/26');
        EvB(O, '01/01/23|b0', '01/01/23', 0);
        EvB(O, '01/01/23|b9', '01/01/23', 9);
        EvS(O, '01/01/23|st', '01/01/23');
        EvB(O, '11/01/26|b0', '11/01/26', 0);
        EvB(O, '11/01/26|b9', '11/01/26', 9);
        EvS(O, '11/01/26|st', '11/01/26');
        EvB(O, '01/01/2026|b0', '01/01/2026', 0);
        EvB(O, '01/01/2026|b9', '01/01/2026', 9);
        EvS(O, '01/01/2026|st', '01/01/2026');
        EvB(O, '01/01/26D|b0', '01/01/26D', 0);
        GlobalLanguage(Saved);
        O.Expect('empty|b0', 'Yes|');
        O.Expect('empty|b9', 'Yes|');
        O.Expect('empty|st', 'ok|');
        O.Expect('blank|b0', 'Yes|');
        O.Expect('blank|b9', 'Yes|');
        O.Expect('blank|st', 'ok|');
        O.Expect('0DT|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('0DT|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('0DT|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Ignore('T|b0'); // depends on today's date or the current time: observed, not asserted
        O.Expect('T|b9', 'No|2000-01-01T07:08:09Z');
        O.Ignore('T|st'); // depends on today's date or the current time: observed, not asserted
        O.Ignore('D|b0'); // depends on today's date or the current time: observed, not asserted
        O.Expect('D|b9', 'No|2000-01-01T07:08:09Z');
        O.Ignore('D|st'); // depends on today's date or the current time: observed, not asserted
        O.Expect('01/01/26|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('01/01/26|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/23|b0', 'Yes|2023-01-01T00:00:00Z');
        O.Expect('01/01/23|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/23|st', 'ok|2023-01-01T00:00:00Z');
        O.Expect('11/01/26|b0', 'Yes|2026-11-01T00:00:00Z');
        O.Expect('11/01/26|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('11/01/26|st', 'ok|2026-11-01T00:00:00Z');
        O.Expect('01/01/2026|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('01/01/2026|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/2026|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/26D|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '01/01/26D|b9', '01/01/26D', 9);
        EvS(O, '01/01/26D|st', '01/01/26D');
        EvB(O, '01/01/26T|b0', '01/01/26T', 0);
        EvB(O, '01/01/26T|b9', '01/01/26T', 9);
        EvS(O, '01/01/26T|st', '01/01/26T');
        EvB(O, '01/01/26 12:00|b0', '01/01/26 12:00', 0);
        EvB(O, '01/01/26 12:00|b9', '01/01/26 12:00', 9);
        EvS(O, '01/01/26 12:00|st', '01/01/26 12:00');
        EvB(O, '01/01/26 12:00:00|b0', '01/01/26 12:00:00', 0);
        EvB(O, '01/01/26 12:00:00|b9', '01/01/26 12:00:00', 9);
        EvS(O, '01/01/26 12:00:00|st', '01/01/26 12:00:00');
        EvB(O, '01/01/26 12:00:00 AM|b0', '01/01/26 12:00:00 AM', 0);
        EvB(O, '01/01/26 12:00:00 AM|b9', '01/01/26 12:00:00 AM', 9);
        EvS(O, '01/01/26 12:00:00 AM|st', '01/01/26 12:00:00 AM');
        EvB(O, '01/01/26 12:00 PM|b0', '01/01/26 12:00 PM', 0);
        EvB(O, '01/01/26 12:00 PM|b9', '01/01/26 12:00 PM', 9);
        EvS(O, '01/01/26 12:00 PM|st', '01/01/26 12:00 PM');
        EvB(O, '01/01/26 12:00:00T|b0', '01/01/26 12:00:00T', 0);
        EvB(O, '01/01/26 12:00:00T|b9', '01/01/26 12:00:00T', 9);
        EvS(O, '01/01/26 12:00:00T|st', '01/01/26 12:00:00T');
        EvB(O, '01/01/26 24:00|b0', '01/01/26 24:00', 0);
        EvB(O, '01/01/26 24:00|b9', '01/01/26 24:00', 9);
        EvS(O, '01/01/26 24:00|st', '01/01/26 24:00');
        GlobalLanguage(Saved);
        O.Expect('01/01/26D|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26D|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/26T|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('01/01/26T|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26T|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/26 12:00|b0', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00|st', 'ok|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00:00|b0', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00|st', 'ok|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00:00 AM|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('01/01/26 12:00:00 AM|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 AM|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/26 12:00 PM|b0', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00 PM|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00 PM|st', 'ok|2026-01-01T12:00:00Z');
        O.Expect('01/01/26 12:00:00T|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00T|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00T|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 24:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 24:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 24:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '01/01/26 25:00|b0', '01/01/26 25:00', 0);
        EvB(O, '01/01/26 25:00|b9', '01/01/26 25:00', 9);
        EvS(O, '01/01/26 25:00|st', '01/01/26 25:00');
        EvB(O, '01/01/26 12:60|b0', '01/01/26 12:60', 0);
        EvB(O, '01/01/26 12:60|b9', '01/01/26 12:60', 9);
        EvS(O, '01/01/26 12:60|st', '01/01/26 12:60');
        EvB(O, '01/01/26 12:00:00.123|b0', '01/01/26 12:00:00.123', 0);
        EvB(O, '01/01/26 12:00:00.123|b9', '01/01/26 12:00:00.123', 9);
        EvS(O, '01/01/26 12:00:00.123|st', '01/01/26 12:00:00.123');
        EvB(O, '13/01/26 12:00|b0', '13/01/26 12:00', 0);
        EvB(O, '13/01/26 12:00|b9', '13/01/26 12:00', 9);
        EvS(O, '13/01/26 12:00|st', '13/01/26 12:00');
        EvB(O, '02/30/26 12:00|b0', '02/30/26 12:00', 0);
        EvB(O, '02/30/26 12:00|b9', '02/30/26 12:00', 9);
        EvS(O, '02/30/26 12:00|st', '02/30/26 12:00');
        EvB(O, '12:00:00|b0', '12:00:00', 0);
        EvB(O, '12:00:00|b9', '12:00:00', 9);
        EvS(O, '12:00:00|st', '12:00:00');
        EvB(O, '12:00 AM|b0', '12:00 AM', 0);
        EvB(O, '12:00 AM|b9', '12:00 AM', 9);
        EvS(O, '12:00 AM|st', '12:00 AM');
        EvB(O, '2026-01-01|b0', '2026-01-01', 0);
        EvB(O, '2026-01-01|b9', '2026-01-01', 9);
        EvS(O, '2026-01-01|st', '2026-01-01');
        GlobalLanguage(Saved);
        O.Expect('01/01/26 25:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 25:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 25:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:60|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:60|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:60|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00.123|b0', 'Yes|2026-01-01T12:00:00.123Z');
        O.Expect('01/01/26 12:00:00.123|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00.123|st', 'ok|2026-01-01T12:00:00.123Z');
        O.Expect('13/01/26 12:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('13/01/26 12:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('13/01/26 12:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('02/30/26 12:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('02/30/26 12:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('02/30/26 12:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('12:00:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Ignore('12:00:00|b9'); // depends on today's date or the current time: observed, not asserted
        O.Expect('12:00:00|st', 'err:DateInvalid|2000-01-01T07:08:09Z');
        O.Expect('12:00 AM|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('12:00 AM|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('12:00 AM|st', 'err:DateInvalid|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('2026-01-01|b9', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('2026-01-01|st', 'ok|2026-01-01T00:00:00Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '2026-01-01T12:00:00|b0', '2026-01-01T12:00:00', 0);
        EvB(O, '2026-01-01T12:00:00|b9', '2026-01-01T12:00:00', 9);
        EvS(O, '2026-01-01T12:00:00|st', '2026-01-01T12:00:00');
        EvB(O, '2026-01-01T12:00:00Z|b0', '2026-01-01T12:00:00Z', 0);
        EvB(O, '2026-01-01T12:00:00Z|b9', '2026-01-01T12:00:00Z', 9);
        EvS(O, '2026-01-01T12:00:00Z|st', '2026-01-01T12:00:00Z');
        EvB(O, '2026-01-01T12:00:00.123Z|b0', '2026-01-01T12:00:00.123Z', 0);
        EvB(O, '2026-01-01T12:00:00.123Z|b9', '2026-01-01T12:00:00.123Z', 9);
        EvS(O, '2026-01-01T12:00:00.123Z|st', '2026-01-01T12:00:00.123Z');
        EvB(O, '2026-13-01T00:00:00Z|b0', '2026-13-01T00:00:00Z', 0);
        EvB(O, '2026-13-01T00:00:00Z|b9', '2026-13-01T00:00:00Z', 9);
        EvS(O, '2026-13-01T00:00:00Z|st', '2026-13-01T00:00:00Z');
        EvB(O, '2026-01-01T12:00:00+01:00|b0', '2026-01-01T12:00:00+01:00', 0);
        EvB(O, '2026-01-01T12:00:00+01:00|b9', '2026-01-01T12:00:00+01:00', 9);
        EvS(O, '2026-01-01T12:00:00+01:00|st', '2026-01-01T12:00:00+01:00');
        EvB(O, '2026-01-01T24:00:00Z|b0', '2026-01-01T24:00:00Z', 0);
        EvB(O, '2026-01-01T24:00:00Z|b9', '2026-01-01T24:00:00Z', 9);
        EvS(O, '2026-01-01T24:00:00Z|st', '2026-01-01T24:00:00Z');
        EvB(O, '20260101T120000Z|b0', '20260101T120000Z', 0);
        EvB(O, '20260101T120000Z|b9', '20260101T120000Z', 9);
        EvS(O, '20260101T120000Z|st', '20260101T120000Z');
        GlobalLanguage(Saved);
        O.Expect('2026-01-01T12:00:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01T12:00:00|b9', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('2026-01-01T12:00:00|st', 'err:DateInvalid|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01T12:00:00Z|b0', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('2026-01-01T12:00:00Z|b9', 'Yes|2026-01-01T12:00:00Z');
        O.Expect('2026-01-01T12:00:00Z|st', 'ok|2026-01-01T12:00:00Z');
        O.Expect('2026-01-01T12:00:00.123Z|b0', 'Yes|2026-01-01T12:00:00.123Z');
        O.Expect('2026-01-01T12:00:00.123Z|b9', 'Yes|2026-01-01T12:00:00.123Z');
        O.Expect('2026-01-01T12:00:00.123Z|st', 'ok|2026-01-01T12:00:00.123Z');
        O.Expect('2026-13-01T00:00:00Z|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('2026-13-01T00:00:00Z|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('2026-13-01T00:00:00Z|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01T12:00:00+01:00|b0', 'Yes|2026-01-01T11:00:00Z');
        O.Expect('2026-01-01T12:00:00+01:00|b9', 'Yes|2026-01-01T11:00:00Z');
        O.Expect('2026-01-01T12:00:00+01:00|st', 'ok|2026-01-01T11:00:00Z');
        O.Expect('2026-01-01T24:00:00Z|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01T24:00:00Z|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('2026-01-01T24:00:00Z|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('20260101T120000Z|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('20260101T120000Z|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('20260101T120000Z|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_5()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, '01/01/26 |b0', '01/01/26 ', 0);
        EvB(O, '01/01/26 |b9', '01/01/26 ', 9);
        EvS(O, '01/01/26 |st', '01/01/26 ');
        EvB(O, ' 01/01/26|b0', ' 01/01/26', 0);
        EvB(O, ' 01/01/26|b9', ' 01/01/26', 9);
        EvS(O, ' 01/01/26|st', ' 01/01/26');
        EvB(O, '01/xx/26|b0', '01/xx/26', 0);
        EvB(O, '01/xx/26|b9', '01/xx/26', 9);
        EvS(O, '01/xx/26|st', '01/xx/26');
        EvB(O, 'Mon, 01 Jan 2026 12:00:00 GMT|b0', 'Mon, 01 Jan 2026 12:00:00 GMT', 0);
        EvB(O, 'Mon, 01 Jan 2026 12:00:00 GMT|b9', 'Mon, 01 Jan 2026 12:00:00 GMT', 9);
        EvS(O, 'Mon, 01 Jan 2026 12:00:00 GMT|st', 'Mon, 01 Jan 2026 12:00:00 GMT');
        EvB(O, '01/01/26 12:00:00 12:00:00|b0', '01/01/26 12:00:00 12:00:00', 0);
        EvB(O, '01/01/26 12:00:00 12:00:00|b9', '01/01/26 12:00:00 12:00:00', 9);
        EvS(O, '01/01/26 12:00:00 12:00:00|st', '01/01/26 12:00:00 12:00:00');
        GlobalLanguage(Saved);
        O.Expect('abc|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('abc|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('abc|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('NUL|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('NUL|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('NUL|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('?|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('?|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('?|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 |b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect('01/01/26 |b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 |st', 'ok|2026-01-01T00:00:00Z');
        O.Expect(' 01/01/26|b0', 'Yes|2026-01-01T00:00:00Z');
        O.Expect(' 01/01/26|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect(' 01/01/26|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/xx/26|b0', 'Yes|2026-01-26T00:00:00Z');
        O.Expect('01/xx/26|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/xx/26|st', 'ok|2026-01-26T00:00:00Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|b0', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|b9', 'No|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_de_1()
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
        EvB(O, '0DT|b0', '0DT', 0);
        EvB(O, '0DT|b9', '0DT', 9);
        EvS(O, '0DT|st', '0DT');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, 'D|b0', 'D', 0);
        EvB(O, 'D|b9', 'D', 9);
        EvS(O, 'D|st', 'D');
        EvB(O, '01/01/26|b0', '01/01/26', 0);
        EvB(O, '01/01/26|b9', '01/01/26', 9);
        EvS(O, '01/01/26|st', '01/01/26');
        EvB(O, '01/01/23|b0', '01/01/23', 0);
        EvB(O, '01/01/23|b9', '01/01/23', 9);
        EvS(O, '01/01/23|st', '01/01/23');
        EvB(O, '11/01/26|b0', '11/01/26', 0);
        EvB(O, '11/01/26|b9', '11/01/26', 9);
        EvS(O, '11/01/26|st', '11/01/26');
        EvB(O, '01/01/2026|b0', '01/01/2026', 0);
        EvB(O, '01/01/2026|b9', '01/01/2026', 9);
        EvS(O, '01/01/2026|st', '01/01/2026');
        EvB(O, '01/01/26D|b0', '01/01/26D', 0);
        GlobalLanguage(Saved);
        O.Expect('empty|b0', 'Ja|');
        O.Expect('empty|b9', 'Ja|');
        O.Expect('empty|st', 'ok|');
        O.Expect('blank|b0', 'Ja|');
        O.Expect('blank|b9', 'Ja|');
        O.Expect('blank|st', 'ok|');
        O.Expect('0DT|b0', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('0DT|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('0DT|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('T|b0', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('T|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('T|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Ignore('D|b0'); // depends on today's date or the current time: observed, not asserted
        O.Expect('D|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Ignore('D|st'); // depends on today's date or the current time: observed, not asserted
        O.Expect('01/01/26|b0', 'Ja|2026-01-01T00:00:00Z');
        O.Expect('01/01/26|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/26|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/23|b0', 'Ja|2023-01-01T00:00:00Z');
        O.Expect('01/01/23|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/23|st', 'ok|2023-01-01T00:00:00Z');
        O.Expect('11/01/26|b0', 'Ja|2026-11-01T00:00:00Z');
        O.Expect('11/01/26|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('11/01/26|st', 'ok|2026-11-01T00:00:00Z');
        O.Expect('01/01/2026|b0', 'Ja|2026-01-01T00:00:00Z');
        O.Expect('01/01/2026|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/2026|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/01/26D|b0', 'Ja|2026-01-01T00:00:00Z');
        O.Verify();
    end;

    [Test]
    procedure Evaluate_DateTime_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '01/01/26D|b9', '01/01/26D', 9);
        EvS(O, '01/01/26D|st', '01/01/26D');
        EvB(O, ' 01/01/26|b0', ' 01/01/26', 0);
        EvB(O, ' 01/01/26|b9', ' 01/01/26', 9);
        EvS(O, ' 01/01/26|st', ' 01/01/26');
        EvB(O, '01/xx/26|b0', '01/xx/26', 0);
        EvB(O, '01/xx/26|b9', '01/xx/26', 9);
        EvS(O, '01/xx/26|st', '01/xx/26');
        EvB(O, 'Mon, 01 Jan 2026 12:00:00 GMT|b0', 'Mon, 01 Jan 2026 12:00:00 GMT', 0);
        EvB(O, 'Mon, 01 Jan 2026 12:00:00 GMT|b9', 'Mon, 01 Jan 2026 12:00:00 GMT', 9);
        EvS(O, 'Mon, 01 Jan 2026 12:00:00 GMT|st', 'Mon, 01 Jan 2026 12:00:00 GMT');
        EvB(O, '01/01/26 12:00:00 12:00:00|b0', '01/01/26 12:00:00 12:00:00', 0);
        EvB(O, '01/01/26 12:00:00 12:00:00|b9', '01/01/26 12:00:00 12:00:00', 9);
        EvS(O, '01/01/26 12:00:00 12:00:00|st', '01/01/26 12:00:00 12:00:00');
        GlobalLanguage(Saved);
        O.Expect('01/01/26D|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/26D|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect(' 01/01/26|b0', 'Ja|2026-01-01T00:00:00Z');
        O.Expect(' 01/01/26|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect(' 01/01/26|st', 'ok|2026-01-01T00:00:00Z');
        O.Expect('01/xx/26|b0', 'Ja|2026-01-26T00:00:00Z');
        O.Expect('01/xx/26|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/xx/26|st', 'ok|2026-01-26T00:00:00Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|b0', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('Mon, 01 Jan 2026 12:00:00 GMT|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|b0', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|b9', 'Nein|2000-01-01T07:08:09Z');
        O.Expect('01/01/26 12:00:00 12:00:00|st', 'err:Evaluate|2000-01-01T07:08:09Z');
        O.Verify();
    end;
}
