// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/text/text-format-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: matrix of Format (every standard format number 0..10 and a list of format-string elements) and Evaluate (boolean and statement form, format 0 and 9)
//        on the Evaluate texts of Duration. Session language 1033 (restored); a de-DE test per type shows what changes under GlobalLanguage 1031.
//        Cell names are the value or text and the format; an error cell is err:<error code>. Generated; Evaluate texts include empty, blanks, out-of-range and trailing D/T.
// BC versions: 27, 28, 29

codeunit 72844 "LT FM Eval Duration"
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
    local procedure TryEv(Txt: Text; var V: Duration)
    begin
        Evaluate(V, Txt);
    end;

    local procedure EvB(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text; N: Integer)
    var
        V: Duration;
        Ok: Boolean;
    begin
        V := 7;
        if N = 0 then
            Ok := Evaluate(V, Txt)
        else
            Ok := Evaluate(V, Txt, N);
        O.Observe(Name, Format(Ok) + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    local procedure EvS(var O: Codeunit "Probe Observer"; Name: Text; Txt: Text)
    var
        V: Duration;
    begin
        V := 7;
        ClearLastError();
        if TryEv(Txt, V) then
            O.Observe(Name, 'ok|' + Format(V, 0, 9) + '/' + Format(V))
        else
            O.Observe(Name, 'err:' + GetLastErrorCode() + '|' + Format(V, 0, 9) + '/' + Format(V));
    end;

    [Test]
    procedure Evaluate_Duration_1()
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
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, '1000|b0', '1000', 0);
        EvB(O, '1000|b9', '1000', 9);
        EvS(O, '1000|st', '1000');
        EvB(O, '90061001|b0', '90061001', 0);
        EvB(O, '90061001|b9', '90061001', 9);
        EvS(O, '90061001|st', '90061001');
        EvB(O, '1 millisecond|b0', '1 millisecond', 0);
        EvB(O, '1 millisecond|b9', '1 millisecond', 9);
        EvS(O, '1 millisecond|st', '1 millisecond');
        EvB(O, '-1 millisecond|b0', '-1 millisecond', 0);
        EvB(O, '-1 millisecond|b9', '-1 millisecond', 9);
        EvS(O, '-1 millisecond|st', '-1 millisecond');
        EvB(O, '1 milliseconds|b0', '1 milliseconds', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '1 milliseconds|b9', '1 milliseconds', 9);
        EvS(O, '1 milliseconds|st', '1 milliseconds');
        EvB(O, '1 second|b0', '1 second', 0);
        EvB(O, '1 second|b9', '1 second', 9);
        EvS(O, '1 second|st', '1 second');
        EvB(O, '2 seconds|b0', '2 seconds', 0);
        EvB(O, '2 seconds|b9', '2 seconds', 9);
        EvS(O, '2 seconds|st', '2 seconds');
        EvB(O, '1 minute|b0', '1 minute', 0);
        EvB(O, '1 minute|b9', '1 minute', 9);
        EvS(O, '1 minute|st', '1 minute');
        EvB(O, '1 hour|b0', '1 hour', 0);
        EvB(O, '1 hour|b9', '1 hour', 9);
        EvS(O, '1 hour|st', '1 hour');
        EvB(O, '1 day|b0', '1 day', 0);
        EvB(O, '1 day|b9', '1 day', 9);
        EvS(O, '1 day|st', '1 day');
        EvB(O, '2 days|b0', '2 days', 0);
        EvB(O, '2 days|b9', '2 days', 9);
        EvS(O, '2 days|st', '2 days');
        EvB(O, '1 day 2 hours|b0', '1 day 2 hours', 0);
        EvB(O, '1 day 2 hours|b9', '1 day 2 hours', 9);
        EvS(O, '1 day 2 hours|st', '1 day 2 hours');
        EvB(O, '1 day 2 hours 3 minutes 4 seconds 5 milliseconds|b0', '1 day 2 hours 3 minutes 4 seconds 5 milliseconds', 0);
        EvB(O, '1 day 2 hours 3 minutes 4 seconds 5 milliseconds|b9', '1 day 2 hours 3 minutes 4 seconds 5 milliseconds', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_3()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, '1 day 2 hours 3 minutes 4 seconds 5 milliseconds|st', '1 day 2 hours 3 minutes 4 seconds 5 milliseconds');
        EvB(O, '-1 day 2 hours|b0', '-1 day 2 hours', 0);
        EvB(O, '-1 day 2 hours|b9', '-1 day 2 hours', 9);
        EvS(O, '-1 day 2 hours|st', '-1 day 2 hours');
        EvB(O, '1.5 seconds|b0', '1.5 seconds', 0);
        EvB(O, '1.5 seconds|b9', '1.5 seconds', 9);
        EvS(O, '1.5 seconds|st', '1.5 seconds');
        EvB(O, '1h|b0', '1h', 0);
        EvB(O, '1h|b9', '1h', 9);
        EvS(O, '1h|st', '1h');
        EvB(O, '1h 2m|b0', '1h 2m', 0);
        EvB(O, '1h 2m|b9', '1h 2m', 9);
        EvS(O, '1h 2m|st', '1h 2m');
        EvB(O, '1s|b0', '1s', 0);
        EvB(O, '1s|b9', '1s', 9);
        EvS(O, '1s|st', '1s');
        EvB(O, '1 ms|b0', '1 ms', 0);
        EvB(O, '1 ms|b9', '1 ms', 9);
        EvS(O, '1 ms|st', '1 ms');
        EvB(O, '1 sec|b0', '1 sec', 0);
        EvB(O, '1 sec|b9', '1 sec', 9);
        EvS(O, '1 sec|st', '1 sec');
        EvB(O, '1 min|b0', '1 min', 0);
        EvB(O, '1 min|b9', '1 min', 9);
        EvS(O, '1 min|st', '1 min');
        EvB(O, '1 Second|b0', '1 Second', 0);
        EvB(O, '1 Second|b9', '1 Second', 9);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_4()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvS(O, '1 Second|st', '1 Second');
        EvB(O, 'abc|b0', 'abc', 0);
        EvB(O, 'abc|b9', 'abc', 9);
        EvS(O, 'abc|st', 'abc');
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
        EvB(O, 'P1DT2H|b0', 'P1DT2H', 0);
        EvB(O, 'P1DT2H|b9', 'P1DT2H', 9);
        EvS(O, 'P1DT2H|st', 'P1DT2H');
        EvB(O, 'PT1.5S|b0', 'PT1.5S', 0);
        EvB(O, 'PT1.5S|b9', 'PT1.5S', 9);
        EvS(O, 'PT1.5S|st', 'PT1.5S');
        EvB(O, '0 milliseconds|b0', '0 milliseconds', 0);
        EvB(O, '0 milliseconds|b9', '0 milliseconds', 9);
        EvS(O, '0 milliseconds|st', '0 milliseconds');
        EvB(O, '9223372036854775807|b0', '9223372036854775807', 0);
        EvB(O, '9223372036854775807|b9', '9223372036854775807', 9);
        EvS(O, '9223372036854775807|st', '9223372036854775807');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_5()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1033);
        EvB(O, '9223372036854775808|b0', '9223372036854775808', 0);
        EvB(O, '9223372036854775808|b9', '9223372036854775808', 9);
        EvS(O, '9223372036854775808|st', '9223372036854775808');
        EvB(O, '999999999999 days|b0', '999999999999 days', 0);
        EvB(O, '999999999999 days|b9', '999999999999 days', 9);
        EvS(O, '999999999999 days|st', '999999999999 days');
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_de_1()
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
        EvB(O, '0|b0', '0', 0);
        EvB(O, '0|b9', '0', 9);
        EvS(O, '0|st', '0');
        EvB(O, '1|b0', '1', 0);
        EvB(O, '1|b9', '1', 9);
        EvS(O, '1|st', '1');
        EvB(O, '-1|b0', '-1', 0);
        EvB(O, '-1|b9', '-1', 9);
        EvS(O, '-1|st', '-1');
        EvB(O, '1000|b0', '1000', 0);
        EvB(O, '1000|b9', '1000', 9);
        EvS(O, '1000|st', '1000');
        EvB(O, '90061001|b0', '90061001', 0);
        EvB(O, '90061001|b9', '90061001', 9);
        EvS(O, '90061001|st', '90061001');
        EvB(O, '1 millisecond|b0', '1 millisecond', 0);
        EvB(O, '1 millisecond|b9', '1 millisecond', 9);
        EvS(O, '1 millisecond|st', '1 millisecond');
        EvB(O, '-1 millisecond|b0', '-1 millisecond', 0);
        EvB(O, '-1 millisecond|b9', '-1 millisecond', 9);
        EvS(O, '-1 millisecond|st', '-1 millisecond');
        EvB(O, '1 milliseconds|b0', '1 milliseconds', 0);
        GlobalLanguage(Saved);
        O.Finish();
    end;

    [Test]
    procedure Evaluate_Duration_de_2()
    var
        O: Codeunit "Probe Observer";
        Saved: Integer;
    begin
        Saved := GlobalLanguage();
        GlobalLanguage(1031);
        EvB(O, '1 milliseconds|b9', '1 milliseconds', 9);
        EvS(O, '1 milliseconds|st', '1 milliseconds');
        EvB(O, '0 milliseconds|b0', '0 milliseconds', 0);
        EvB(O, '0 milliseconds|b9', '0 milliseconds', 9);
        EvS(O, '0 milliseconds|st', '0 milliseconds');
        EvB(O, '9223372036854775807|b0', '9223372036854775807', 0);
        EvB(O, '9223372036854775807|b9', '9223372036854775807', 9);
        EvS(O, '9223372036854775807|st', '9223372036854775807');
        EvB(O, '9223372036854775808|b0', '9223372036854775808', 0);
        EvB(O, '9223372036854775808|b9', '9223372036854775808', 9);
        EvS(O, '9223372036854775808|st', '9223372036854775808');
        EvB(O, '999999999999 days|b0', '999999999999 days', 0);
        EvB(O, '999999999999 days|b9', '999999999999 days', 9);
        EvS(O, '999999999999 days|st', '999999999999 days');
        GlobalLanguage(Saved);
        O.Finish();
    end;
}
