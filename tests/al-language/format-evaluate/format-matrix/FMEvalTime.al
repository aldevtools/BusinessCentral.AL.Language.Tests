// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Time. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72842 "LT FM Eval Time"
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
    local procedure TryEv(Txt: Text; var V: Time)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Time;
        Ok: Boolean;
    begin
        V := 070809T;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Time;
    begin
        V := 070809T;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9));
    end;

    [Test]
    procedure Evaluate_Time_1()
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
        EvB(O, '12:00:00|b0', '12:00:00', 0);
        EvB(O, '12:00:00|b9', '12:00:00', 9);
        EvS(O, '12:00:00|st', '12:00:00');
        EvB(O, '12:00|b0', '12:00', 0);
        EvB(O, '12:00|b9', '12:00', 9);
        EvS(O, '12:00|st', '12:00');
        EvB(O, '12:00 AM|b0', '12:00 AM', 0);
        EvB(O, '12:00 AM|b9', '12:00 AM', 9);
        EvS(O, '12:00 AM|st', '12:00 AM');
        EvB(O, '12:00 PM|b0', '12:00 PM', 0);
        EvB(O, '12:00 PM|b9', '12:00 PM', 9);
        EvS(O, '12:00 PM|st', '12:00 PM');
        EvB(O, '12:00:00 AM|b0', '12:00:00 AM', 0);
        EvB(O, '12:00:00 AM|b9', '12:00:00 AM', 9);
        EvS(O, '12:00:00 AM|st', '12:00:00 AM');
        EvB(O, '1:05 pm|b0', '1:05 pm', 0);
        EvB(O, '1:05 pm|b9', '1:05 pm', 9);
        EvS(O, '1:05 pm|st', '1:05 pm');
        EvB(O, '0:00|b0', '0:00', 0);
        EvB(O, '0:00|b9', '0:00', 9);
        EvS(O, '0:00|st', '0:00');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Time_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '24:00:00|b0', '24:00:00', 0);
        EvB(O, '24:00:00|b9', '24:00:00', 9);
        EvS(O, '24:00:00|st', '24:00:00');
        EvB(O, '25:00:00|b0', '25:00:00', 0);
        EvB(O, '25:00:00|b9', '25:00:00', 9);
        EvS(O, '25:00:00|st', '25:00:00');
        EvB(O, '12:60:00|b0', '12:60:00', 0);
        EvB(O, '12:60:00|b9', '12:60:00', 9);
        EvS(O, '12:60:00|st', '12:60:00');
        EvB(O, '12:00:60|b0', '12:00:60', 0);
        EvB(O, '12:00:60|b9', '12:00:60', 9);
        EvS(O, '12:00:60|st', '12:00:60');
        EvB(O, '12:00:00.123|b0', '12:00:00.123', 0);
        EvB(O, '12:00:00.123|b9', '12:00:00.123', 9);
        EvS(O, '12:00:00.123|st', '12:00:00.123');
        EvB(O, '12:00:00.1234|b0', '12:00:00.1234', 0);
        EvB(O, '12:00:00.1234|b9', '12:00:00.1234', 9);
        EvS(O, '12:00:00.1234|st', '12:00:00.1234');
        EvB(O, '12:00:00,123|b0', '12:00:00,123', 0);
        EvB(O, '12:00:00,123|b9', '12:00:00,123', 9);
        EvS(O, '12:00:00,123|st', '12:00:00,123');
        EvB(O, 'T|b0', 'T', 0);
        EvB(O, 'T|b9', 'T', 9);
        EvS(O, 'T|st', 'T');
        EvB(O, '0T|b0', '0T', 0);
        EvB(O, '0T|b9', '0T', 9);
        EvS(O, '0T|st', '0T');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Time_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '12:00:00T|b0', '12:00:00T', 0);
        EvB(O, '12:00:00T|b9', '12:00:00T', 9);
        EvS(O, '12:00:00T|st', '12:00:00T');
        EvB(O, '12:00:00D|b0', '12:00:00D', 0);
        EvB(O, '12:00:00D|b9', '12:00:00D', 9);
        EvS(O, '12:00:00D|st', '12:00:00D');
        EvB(O, '1200|b0', '1200', 0);
        EvB(O, '1200|b9', '1200', 9);
        EvS(O, '1200|st', '1200');
        EvB(O, '120000|b0', '120000', 0);
        EvB(O, '120000|b9', '120000', 9);
        EvS(O, '120000|st', '120000');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
        EvB(O, '-1:00|b0', '-1:00', 0);
        EvB(O, '-1:00|b9', '-1:00', 9);
        EvS(O, '-1:00|st', '-1:00');
        EvB(O, '12.00.00|b0', '12.00.00', 0);
        EvB(O, '12.00.00|b9', '12.00.00', 9);
        EvS(O, '12.00.00|st', '12.00.00');
        EvB(O, '12:00:00 |b0', '12:00:00 ', 0);
        EvB(O, '12:00:00 |b9', '12:00:00 ', 9);
        EvS(O, '12:00:00 |st', '12:00:00 ');
        EvB(O, ' 12:00:00|b0', ' 12:00:00', 0);
        EvB(O, ' 12:00:00|b9', ' 12:00:00', 9);
        EvS(O, ' 12:00:00|st', ' 12:00:00');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Time_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, 'NUL|b0', Nul(), 0);
        EvB(O, 'NUL|b9', Nul(), 9);
        EvS(O, 'NUL|st', Nul());
        EvB(O, '?|b0', '?', 0);
        EvB(O, '?|b9', '?', 9);
        EvS(O, '?|st', '?');
        EvB(O, '12|b0', '12', 0);
        EvB(O, '12|b9', '12', 9);
        EvS(O, '12|st', '12');
        EvB(O, '12:|b0', '12:', 0);
        EvB(O, '12:|b9', '12:', 9);
        EvS(O, '12:|st', '12:');
        EvB(O, ':30|b0', ':30', 0);
        EvB(O, ':30|b9', ':30', 9);
        EvS(O, ':30|st', ':30');
        EvB(O, '1:2:3|b0', '1:2:3', 0);
        EvB(O, '1:2:3|b9', '1:2:3', 9);
        EvS(O, '1:2:3|st', '1:2:3');
        EvB(O, '11:59:59.999 PM|b0', '11:59:59.999 PM', 0);
        EvB(O, '11:59:59.999 PM|b9', '11:59:59.999 PM', 9);
        EvS(O, '11:59:59.999 PM|st', '11:59:59.999 PM');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Time_de_1()
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
        EvB(O, '12:00:00|b0', '12:00:00', 0);
        EvB(O, '12:00:00|b9', '12:00:00', 9);
        EvS(O, '12:00:00|st', '12:00:00');
        EvB(O, '12:00|b0', '12:00', 0);
        EvB(O, '12:00|b9', '12:00', 9);
        EvS(O, '12:00|st', '12:00');
        EvB(O, '12:00 AM|b0', '12:00 AM', 0);
        EvB(O, '12:00 AM|b9', '12:00 AM', 9);
        EvS(O, '12:00 AM|st', '12:00 AM');
        EvB(O, '12:00 PM|b0', '12:00 PM', 0);
        EvB(O, '12:00 PM|b9', '12:00 PM', 9);
        EvS(O, '12:00 PM|st', '12:00 PM');
        EvB(O, '12:00:00 AM|b0', '12:00:00 AM', 0);
        EvB(O, '12:00:00 AM|b9', '12:00:00 AM', 9);
        EvS(O, '12:00:00 AM|st', '12:00:00 AM');
        EvB(O, '1:05 pm|b0', '1:05 pm', 0);
        EvB(O, '1:05 pm|b9', '1:05 pm', 9);
        EvS(O, '1:05 pm|st', '1:05 pm');
        EvB(O, '0:00|b0', '0:00', 0);
        EvB(O, '0:00|b9', '0:00', 9);
        EvS(O, '0:00|st', '0:00');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Time_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '24:00:00|b0', '24:00:00', 0);
        EvB(O, '24:00:00|b9', '24:00:00', 9);
        EvS(O, '24:00:00|st', '24:00:00');
        EvB(O, '12:|b0', '12:', 0);
        EvB(O, '12:|b9', '12:', 9);
        EvS(O, '12:|st', '12:');
        EvB(O, ':30|b0', ':30', 0);
        EvB(O, ':30|b9', ':30', 9);
        EvS(O, ':30|st', ':30');
        EvB(O, '1:2:3|b0', '1:2:3', 0);
        EvB(O, '1:2:3|b9', '1:2:3', 9);
        EvS(O, '1:2:3|st', '1:2:3');
        EvB(O, '11:59:59.999 PM|b0', '11:59:59.999 PM', 0);
        EvB(O, '11:59:59.999 PM|b9', '11:59:59.999 PM', 9);
        EvS(O, '11:59:59.999 PM|st', '11:59:59.999 PM');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
