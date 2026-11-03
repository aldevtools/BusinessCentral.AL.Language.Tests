// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-joker-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: Evaluate of Date, Time, DateTime, Duration, DateFormula with valid and invalid input
// BC versions: 29 (27 and 28 by CI)

codeunit 73805 "LT DtT Evaluate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure ED(Txt: Text; Fmt: Integer): Text
    var
        D: Date;
        Ok: Boolean;
    begin
        Ok := Evaluate(D, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(D, 0, 9));
    end;

    local procedure ET(Txt: Text; Fmt: Integer): Text
    var
        T: Time;
        Ok: Boolean;
    begin
        Ok := Evaluate(T, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(T, 0, 9));
    end;

    local procedure EDT(Txt: Text; Fmt: Integer): Text
    var
        DT: DateTime;
        Ok: Boolean;
    begin
        Ok := Evaluate(DT, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(DT, 0, 9));
    end;

    local procedure EDU(Txt: Text; Fmt: Integer): Text
    var
        Du: Duration;
        Ok: Boolean;
    begin
        Ok := Evaluate(Du, Txt, Fmt);
        exit(Format(Ok) + '|' + Format(Du, 0, 9));
    end;

    [Test]
    procedure Date_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('iso', ED('2024-03-05', 9));
        Observer.Observe('iso min', ED('0001-01-01', 9));
        Observer.Observe('iso max', ED('9999-12-31', 9));
        Observer.Observe('iso leap', ED('2024-02-29', 9));
        Observer.Observe('iso nonleap', ED('2023-02-29', 9));
        Observer.Observe('iso closing', ED('2024-12-31Z', 9));
        Observer.Observe('iso empty', ED('', 9));
        Observer.Observe('iso blank', ED('   ', 9));
        Observer.Observe('iso 0D', ED('0001-01-01', 9));
        Observer.Observe('iso no leading zero', ED('2024-3-5', 9));
        Observer.Observe('iso slash', ED('2024/03/05', 9));
        Observer.Observe('iso dmy', ED('05-03-2024', 9));
        Observer.Observe('iso two digit year', ED('24-03-05', 9));
        Observer.Observe('iso text', ED('abc', 9));
        Observer.Observe('iso month 13', ED('2024-13-01', 9));
        Observer.Observe('iso day 32', ED('2024-01-32', 9));
        Observer.Observe('iso month 0', ED('2024-00-01', 9));
        Observer.Observe('iso day 0', ED('2024-01-00', 9));
        Observer.Observe('iso year 0', ED('0000-01-01', 9));
        Observer.Observe('iso datetime', ED('2024-03-05T10:00:00', 9));
        Observer.Observe('iso datetime Z', ED('2024-03-05T10:00:00Z', 9));
        Observer.Observe('iso trailing', ED('2024-03-05x', 9));
        Observer.Observe('iso leading space', ED(' 2024-03-05', 9));
        Observer.Observe('iso trailing space', ED('2024-03-05 ', 9));
        Observer.Expect('iso', 'Yes|2024-03-05');
        Observer.Expect('iso min', 'Yes|');
        Observer.Expect('iso max', 'Yes|9999-12-31');
        Observer.Expect('iso leap', 'Yes|2024-02-29');
        Observer.Expect('iso nonleap', 'No|');
        Observer.Expect('iso closing', 'No|');
        Observer.Expect('iso empty', 'Yes|');
        Observer.Expect('iso blank', 'Yes|');
        Observer.Expect('iso 0D', 'Yes|');
        Observer.Expect('iso no leading zero', 'No|');
        Observer.Expect('iso slash', 'No|');
        Observer.Expect('iso dmy', 'No|');
        Observer.Expect('iso two digit year', 'No|');
        Observer.Expect('iso text', 'No|');
        Observer.Expect('iso month 13', 'No|');
        Observer.Expect('iso day 32', 'No|');
        Observer.Expect('iso month 0', 'No|');
        Observer.Expect('iso day 0', 'No|');
        Observer.Expect('iso year 0', 'Yes|0001-01-02');
        Observer.Expect('iso datetime', 'No|');
        Observer.Expect('iso datetime Z', 'No|');
        Observer.Expect('iso trailing', 'No|');
        Observer.Expect('iso leading space', 'Yes|2024-03-05');
        Observer.Expect('iso trailing space', 'Yes|2024-03-05');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Other_Formats()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 8 do
            Observer.Observe('2024-03-05 fmt ' + Format(I), ED('2024-03-05', I));
        for I := 0 to 8 do
            Observer.Observe('050324 fmt ' + Format(I), ED('050324', I));
        Observer.Observe('fmt 10', ED('2024-03-05', 10));
        Observer.Observe('fmt -1', ED('2024-03-05', -1));
        Observer.Observe('default 5.3.24', ED('5.3.24', 0));
        Observer.Observe('default 050324', ED('050324', 0));
        Observer.Observe('default 05032024', ED('05032024', 0));
        Observer.Expect('2024-03-05 fmt 0', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 1', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 2', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 3', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 4', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 5', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 6', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 7', 'Yes|2024-03-05');
        Observer.Expect('2024-03-05 fmt 8', 'Yes|2024-03-05');
        Observer.Expect('050324 fmt 0', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 1', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 2', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 3', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 4', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 5', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 6', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 7', 'Yes|2024-05-03');
        Observer.Expect('050324 fmt 8', 'Yes|2024-05-03');
        Observer.Expect('fmt 10', 'Yes|2024-03-05');
        Observer.Expect('fmt -1', 'Yes|2024-03-05');
        Observer.Expect('default 5.3.24', 'Yes|2024-05-03');
        Observer.Expect('default 050324', 'Yes|2024-05-03');
        Observer.Expect('default 05032024', 'Yes|2024-05-03');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Default_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        Observer.Observe('empty', Format(Evaluate(D, '')));
        Observer.Observe('empty value', Format(D, 0, 9));
        Observer.Observe('iso', Format(Evaluate(D, '2024-03-05')));
        Observer.Observe('iso value', Format(D, 0, 9));
        Observer.Observe('text', Format(Evaluate(D, 'abc')));
        Observer.Observe('text value', Format(D, 0, 9));
        Observer.Observe('closing', Format(Evaluate(D, 'C2024-03-05')));
        Observer.Observe('closing value', Format(D, 0, 9));
        Observer.Observe('formatted', Format(Evaluate(D, Format(20240305D))));
        Observer.Observe('formatted value', Format(D, 0, 9));
        Observer.Observe('formatted 0', Format(Evaluate(D, Format(20240305D, 0, 0))));
        Observer.Observe('formatted 0 value', Format(D, 0, 9));
        Observer.Observe('formatted 1', Format(Evaluate(D, Format(20240305D, 0, 1))));
        Observer.Observe('formatted 1 value', Format(D, 0, 9));
        Observer.Observe('formatted 4', Format(Evaluate(D, Format(20240305D, 0, 4))));
        Observer.Observe('formatted 4 value', Format(D, 0, 9));
        Observer.Expect('empty', 'Yes');
        Observer.Expect('empty value', '');
        Observer.Expect('iso', 'Yes');
        Observer.Expect('iso value', '2024-03-05');
        Observer.Expect('text', 'No');
        Observer.Expect('text value', '2024-03-05');
        Observer.Expect('closing', 'No');
        Observer.Expect('closing value', '2024-03-05');
        Observer.Expect('formatted', 'Yes');
        Observer.Expect('formatted value', '2024-03-05');
        Observer.Expect('formatted 0', 'Yes');
        Observer.Expect('formatted 0 value', '2024-03-05');
        Observer.Expect('formatted 1', 'Yes');
        Observer.Expect('formatted 1 value', '2024-03-05');
        Observer.Expect('formatted 4', 'No');
        Observer.Expect('formatted 4 value', '2024-03-05');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Evaluate_Raises()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        asserterror Evaluate(D, 'abc');
        Observer.ObserveError('abc');
        Observer.Expect('abc|text', 'The format of the Date ''abc'' does not match your device''s date settings.\\Make sure that the day, month, and year are in the correct order and use the correct separator (such as - or /). Alternatively, you can always use the format ''yyyy-mm-dd''.');
        Observer.Expect('abc|code', 'Evaluate');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('hms', ET('13:45:06', 9));
        Observer.Observe('hms ms', ET('13:45:06.078', 9));
        Observer.Observe('hms ms 1 digit', ET('13:45:06.1', 9));
        Observer.Observe('hms ms 2 digits', ET('13:45:06.12', 9));
        Observer.Observe('hms ms 4 digits', ET('13:45:06.1234', 9));
        Observer.Observe('hm', ET('13:45', 9));
        Observer.Observe('h', ET('13', 9));
        Observer.Observe('midnight', ET('00:00:00', 9));
        Observer.Observe('max', ET('23:59:59.999', 9));
        Observer.Observe('24:00:00', ET('24:00:00', 9));
        Observer.Observe('25:00:00', ET('25:00:00', 9));
        Observer.Observe('minute 60', ET('12:60:00', 9));
        Observer.Observe('second 60', ET('12:00:60', 9));
        Observer.Observe('empty', ET('', 9));
        Observer.Observe('text', ET('abc', 9));
        Observer.Observe('am pm', ET('01:45:06 PM', 9));
        Observer.Observe('am', ET('01:45:06 AM', 9));
        Observer.Observe('12 am', ET('12:00:00 AM', 9));
        Observer.Observe('12 pm', ET('12:00:00 PM', 9));
        Observer.Observe('negative', ET('-1:00:00', 9));
        Observer.Observe('comma ms', ET('13:45:06,078', 9));
        Observer.Observe('T prefix', ET('T13:45:06', 9));
        Observer.Observe('Z suffix', ET('13:45:06Z', 9));
        Observer.Observe('single digits', ET('1:2:3', 9));
        Observer.Expect('hms', 'Yes|13:45:06');
        Observer.Expect('hms ms', 'Yes|13:45:06.078');
        Observer.Expect('hms ms 1 digit', 'Yes|13:45:06.1');
        Observer.Expect('hms ms 2 digits', 'Yes|13:45:06.12');
        Observer.Expect('hms ms 4 digits', 'Yes|13:45:06.123');
        Observer.Expect('hm', 'No|');
        Observer.Expect('h', 'No|');
        Observer.Expect('midnight', 'Yes|00:00:00');
        Observer.Expect('max', 'Yes|23:59:59.999');
        Observer.Expect('24:00:00', 'No|');
        Observer.Expect('25:00:00', 'No|');
        Observer.Expect('minute 60', 'No|');
        Observer.Expect('second 60', 'No|');
        Observer.Expect('empty', 'Yes|');
        Observer.Expect('text', 'No|');
        Observer.Expect('am pm', 'No|');
        Observer.Expect('am', 'No|');
        Observer.Expect('12 am', 'No|');
        Observer.Expect('12 pm', 'No|');
        Observer.Expect('negative', 'No|');
        Observer.Expect('comma ms', 'No|');
        Observer.Expect('T prefix', 'No|');
        Observer.Expect('Z suffix', 'Yes|13:45:06');
        Observer.Expect('single digits', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Other_Formats()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 8 do
            Observer.Observe('13:45:06 fmt ' + Format(I), ET('13:45:06', I));
        for I := 0 to 2 do
            Observer.Observe('1:45:06 PM fmt ' + Format(I), ET('1:45:06 PM', I));
        Observer.Observe('formatted default', ET(Format(134506T), 0));
        Observer.Observe('formatted 0', ET(Format(134506T, 0, 0), 0));
        Observer.Observe('formatted 1', ET(Format(134506T, 0, 1), 0));
        Observer.Observe('formatted 2', ET(Format(134506T, 0, 2), 0));
        Observer.Observe('formatted 9', ET(Format(134506.078T, 0, 9), 9));
        Observer.Expect('13:45:06 fmt 0', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 1', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 2', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 3', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 4', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 5', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 6', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 7', 'Yes|13:45:06');
        Observer.Expect('13:45:06 fmt 8', 'Yes|13:45:06');
        Observer.Expect('1:45:06 PM fmt 0', 'Yes|13:45:06');
        Observer.Expect('1:45:06 PM fmt 1', 'Yes|13:45:06');
        Observer.Expect('1:45:06 PM fmt 2', 'Yes|13:45:06');
        Observer.Expect('formatted default', 'Yes|13:45:06');
        Observer.Expect('formatted 0', 'Yes|13:45:06');
        Observer.Expect('formatted 1', 'Yes|13:45:06');
        Observer.Expect('formatted 2', 'No|');
        Observer.Expect('formatted 9', 'Yes|13:45:06.078');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format9()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('Z', EDT('2024-03-05T13:45:06Z', 9));
        Observer.Observe('Z ms', EDT('2024-03-05T13:45:06.078Z', 9));
        Observer.Observe('no Z', EDT('2024-03-05T13:45:06', 9));
        Observer.Observe('offset +01', EDT('2024-03-05T13:45:06+01:00', 9));
        Observer.Observe('offset -05', EDT('2024-03-05T13:45:06-05:00', 9));
        Observer.Observe('date only', EDT('2024-03-05', 9));
        Observer.Observe('date only Z', EDT('2024-03-05Z', 9));
        Observer.Observe('time only', EDT('13:45:06', 9));
        Observer.Observe('space separator', EDT('2024-03-05 13:45:06', 9));
        Observer.Observe('min', EDT('0001-01-01T00:00:00Z', 9));
        Observer.Observe('max', EDT('9999-12-31T23:59:59.999Z', 9));
        Observer.Observe('max no ms', EDT('9999-12-31T23:59:59Z', 9));
        Observer.Observe('midnight', EDT('2024-03-05T00:00:00Z', 9));
        Observer.Observe('empty', EDT('', 9));
        Observer.Observe('text', EDT('abc', 9));
        Observer.Observe('month 13', EDT('2024-13-05T00:00:00Z', 9));
        Observer.Observe('hour 25', EDT('2024-03-05T25:00:00Z', 9));
        Observer.Observe('hm', EDT('2024-03-05T13:45Z', 9));
        Observer.Observe('ms 1 digit', EDT('2024-03-05T13:45:06.1Z', 9));
        Observer.Observe('ms 6 digits', EDT('2024-03-05T13:45:06.123456Z', 9));
        Observer.Observe('lowercase tz', EDT('2024-03-05t13:45:06z', 9));
        Observer.Observe('offset past max', EDT('9999-12-31T23:59:59-01:00', 9));
        Observer.Observe('offset before min', EDT('0001-01-01T00:00:00+01:00', 9));
        Observer.Expect('Z', 'Yes|2024-03-05T13:45:06Z');
        Observer.Expect('Z ms', 'Yes|2024-03-05T13:45:06.078Z');
        Observer.Expect('no Z', 'Yes|2024-03-05T13:45:06Z');
        Observer.Expect('offset +01', 'Yes|2024-03-05T12:45:06Z');
        Observer.Expect('offset -05', 'Yes|2024-03-05T18:45:06Z');
        Observer.Expect('date only', 'Yes|2024-03-05T00:00:00Z');
        Observer.Expect('date only Z', 'Yes|2024-03-05T00:00:00Z');
        Observer.Expect('time only', 'Yes|' + Format(Today(), 0, 9) + 'T13:45:06Z');
        Observer.Expect('space separator', 'No|');
        Observer.Expect('min', 'Yes|');
        Observer.Expect('max', 'Yes|9999-12-31T23:59:59.999Z');
        Observer.Expect('max no ms', 'Yes|9999-12-31T23:59:59Z');
        Observer.Expect('midnight', 'Yes|2024-03-05T00:00:00Z');
        Observer.Expect('empty', 'Yes|');
        Observer.Expect('text', 'No|');
        Observer.Expect('month 13', 'No|');
        Observer.Expect('hour 25', 'No|');
        Observer.Expect('hm', 'No|');
        Observer.Expect('ms 1 digit', 'Yes|2024-03-05T13:45:06.1Z');
        Observer.Expect('ms 6 digits', 'Yes|2024-03-05T13:45:06.123Z');
        Observer.Expect('lowercase tz', 'No|');
        Observer.Expect('offset past max', 'Yes|9999-12-31T23:59:59.999Z');
        Observer.Expect('offset before min', 'Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Other_Formats()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 8 do
            Observer.Observe('05.03.24 13:45:06 fmt ' + Format(I), EDT('05.03.24 13:45:06', I));
        Observer.Observe('formatted default', EDT(Format(CreateDateTime(20240305D, 134506T)), 0));
        Observer.Observe('formatted 0', EDT(Format(CreateDateTime(20240305D, 134506T), 0, 0), 0));
        Observer.Observe('formatted 1', EDT(Format(CreateDateTime(20240305D, 134506T), 0, 1), 0));
        Observer.Observe('formatted 2', EDT(Format(CreateDateTime(20240305D, 134506T), 0, 2), 0));
        Observer.Observe('formatted 9', EDT(Format(CreateDateTime(20240305D, 134506.078T), 0, 9), 9));
        Observer.Observe('formatted 9 0DT', EDT(Format(0DT, 0, 9), 9));
        Observer.Observe('formatted default 0DT', EDT(Format(0DT), 0));
        Observer.Expect('05.03.24 13:45:06 fmt 0', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 1', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 2', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 3', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 4', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 5', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 6', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 7', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('05.03.24 13:45:06 fmt 8', 'Yes|2024-05-03T13:45:06Z');
        Observer.Expect('formatted default', 'Yes|2024-03-05T13:45:00Z');
        Observer.Expect('formatted 0', 'Yes|2024-03-05T13:45:00Z');
        Observer.Expect('formatted 1', 'Yes|2024-03-05T13:45:06Z');
        Observer.Expect('formatted 2', 'Yes|2024-03-05T13:45:00Z');
        Observer.Expect('formatted 9', 'Yes|2024-03-05T13:45:06.078Z');
        Observer.Expect('formatted 9 0DT', 'Yes|');
        Observer.Expect('formatted default 0DT', 'Yes|');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        Observer.Observe('ms number 9', EDU('1500', 9));
        Observer.Observe('ms number 0', EDU('1500', 0));
        Observer.Observe('ms zero', EDU('0', 9));
        Observer.Observe('negative', EDU('-1500', 9));
        Observer.Observe('big', EDU('31536000000', 9));
        Observer.Observe('1 hour', EDU('1 hour', 0));
        Observer.Observe('1 hours', EDU('1 hours', 0));
        Observer.Observe('2 hours 30 minutes', EDU('2 hours 30 minutes', 0));
        Observer.Observe('1 day', EDU('1 day', 0));
        Observer.Observe('1 days 2 hours', EDU('1 days 2 hours', 0));
        Observer.Observe('1 minute', EDU('1 minute', 0));
        Observer.Observe('1 second', EDU('1 second', 0));
        Observer.Observe('1 seconds 5 milliseconds', EDU('1 seconds 5 milliseconds', 0));
        Observer.Observe('5 milliseconds', EDU('5 milliseconds', 0));
        Observer.Observe('1 h', EDU('1 h', 0));
        Observer.Observe('1h', EDU('1h', 0));
        Observer.Observe('1 hour 1 hour', EDU('1 hour 1 hour', 0));
        Observer.Observe('1 minute 1 hour', EDU('1 minute 1 hour', 0));
        Observer.Observe('1.5 hours', EDU('1.5 hours', 0));
        Observer.Observe('-1 hour', EDU('-1 hour', 0));
        Observer.Observe('empty', EDU('', 0));
        Observer.Observe('empty 9', EDU('', 9));
        Observer.Observe('text', EDU('abc', 0));
        Observer.Observe('text 9', EDU('abc', 9));
        Observer.Observe('1.5 in 9', EDU('1.5', 9));
        Observer.Observe('1 hour in 9', EDU('1 hour', 9));
        Observer.Observe('formatted', EDU(Format(Duration_From(5400000)), 0));
        Observer.Observe('formatted 9', EDU(Format(Duration_From(5400000), 0, 9), 9));
        for I := 0 to 3 do
            Observer.Observe('1500 fmt ' + Format(I), EDU('1500', I));
        Observer.Expect('ms number 9', 'No|P0DT0H0M0.0S');
        Observer.Expect('ms number 0', 'Yes|P62DT12H0M0.0S');
        Observer.Expect('ms zero', 'No|P0DT0H0M0.0S');
        Observer.Expect('negative', 'No|P0DT0H0M0.0S');
        Observer.Expect('big', 'No|P0DT0H0M0.0S');
        Observer.Expect('1 hour', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('1 hours', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('2 hours 30 minutes', 'Yes|P0DT2H30M0.0S');
        Observer.Expect('1 day', 'Yes|P1DT0H0M0.0S');
        Observer.Expect('1 days 2 hours', 'Yes|P1DT2H0M0.0S');
        Observer.Expect('1 minute', 'Yes|P0DT0H1M0.0S');
        Observer.Expect('1 second', 'Yes|P0DT0H0M1.0S');
        Observer.Expect('1 seconds 5 milliseconds', 'Yes|P0DT0H0M1.005S');
        Observer.Expect('5 milliseconds', 'Yes|P0DT0H0M0.005S');
        Observer.Expect('1 h', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('1h', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('1 hour 1 hour', 'No|P0DT0H0M0.0S');
        Observer.Expect('1 minute 1 hour', 'Yes|P0DT1H1M0.0S');
        Observer.Expect('1.5 hours', 'Yes|P0DT1H30M0.0S');
        Observer.Expect('-1 hour', 'Yes|-P0DT1H0M0.0S');
        Observer.Expect('empty', 'Yes|P0DT0H0M0.0S');
        Observer.Expect('empty 9', 'No|P0DT0H0M0.0S');
        Observer.Expect('text', 'No|P0DT0H0M0.0S');
        Observer.Expect('text 9', 'No|P0DT0H0M0.0S');
        Observer.Expect('1.5 in 9', 'No|P0DT0H0M0.0S');
        Observer.Expect('1 hour in 9', 'No|P0DT0H0M0.0S');
        Observer.Expect('formatted', 'Yes|P0DT1H30M0.0S');
        Observer.Expect('formatted 9', 'Yes|P0DT1H30M0.0S');
        Observer.Expect('1500 fmt 0', 'Yes|P62DT12H0M0.0S');
        Observer.Expect('1500 fmt 1', 'Yes|P62DT12H0M0.0S');
        Observer.Expect('1500 fmt 2', 'Yes|P62DT12H0M0.0S');
        Observer.Expect('1500 fmt 3', 'Yes|P62DT12H0M0.0S');
        Observer.Verify();
    end;

    local procedure Duration_From(Ms: BigInteger): Duration
    begin
        exit(Ms);
    end;

    [Test]
    procedure DateFormula_Evaluate()
    var
        Observer: Codeunit "Probe Observer";
        DF: DateFormula;
    begin
        Observer.Observe('1D', Format(Evaluate(DF, '<1D>')) + '|' + Format(DF));
        Observer.Observe('1D 9', Format(Evaluate(DF, '<1D>', 9)) + '|' + Format(DF, 0, 9));
        Observer.Observe('-1M+CM', Format(Evaluate(DF, '<-1M+CM>')) + '|' + Format(DF));
        Observer.Observe('1Y+1Q+1M+1W+1D', Format(Evaluate(DF, '<1Y+1Q+1M+1W+1D>')) + '|' + Format(DF));
        Observer.Observe('lower', Format(Evaluate(DF, '<1d>')) + '|' + Format(DF));
        Observer.Observe('no brackets', Format(Evaluate(DF, '1D')) + '|' + Format(DF));
        Observer.Observe('CM', Format(Evaluate(DF, 'CM')) + '|' + Format(DF));
        Observer.Observe('empty', Format(Evaluate(DF, '')) + '|' + Format(DF));
        Observer.Observe('after empty clear', Format(Evaluate(DF, '<1D>')) + '|' + Format(DF));
        Observer.Observe('MON', Format(Evaluate(DF, '<MON>')) + '|' + Format(DF));
        Observer.Observe('WD3', Format(Evaluate(DF, '<WD3>')) + '|' + Format(DF));
        Observer.Observe('-WD3', Format(Evaluate(DF, '<-WD3>')) + '|' + Format(DF));
        Observer.Observe('0D', Format(Evaluate(DF, '<0D>')) + '|' + Format(DF));
        Observer.Observe('+1D', Format(Evaluate(DF, '<+1D>')) + '|' + Format(DF));
        Observer.Observe('1D+1D', Format(Evaluate(DF, '<1D+1D>')) + '|' + Format(DF));
        Observer.Observe('bad', Format(Evaluate(DF, '<foo>')) + '|' + Format(DF));
        Observer.Observe('length', Format(StrLen(Format(DF))));
        Observer.Observe('spaces', Format(Evaluate(DF, '< 1D >')) + '|' + Format(DF));
        Observer.Observe('1D 9 empty', Format(Evaluate(DF, '', 9)) + '|' + Format(DF));
        Observer.Observe('1D 9 bad', Format(Evaluate(DF, 'x', 9)) + '|' + Format(DF));
        Observer.Expect('1D', 'Yes|1D');
        Observer.Expect('1D 9', 'Yes|1D');
        Observer.Expect('-1M+CM', 'Yes|-1M+CM');
        Observer.Expect('1Y+1Q+1M+1W+1D', 'Yes|1Y+1Q+1M+1W+1D');
        Observer.Expect('lower', 'Yes|1D');
        Observer.Expect('no brackets', 'Yes|1D');
        Observer.Expect('CM', 'Yes|CM');
        Observer.Expect('empty', 'Yes|');
        Observer.Expect('after empty clear', 'Yes|1D');
        Observer.Expect('MON', 'No|1D');
        Observer.Expect('WD3', 'Yes|WD3');
        Observer.Expect('-WD3', 'Yes|-WD3');
        Observer.Expect('0D', 'Yes|0D');
        Observer.Expect('+1D', 'Yes|+1D');
        Observer.Expect('1D+1D', 'Yes|1D+1D');
        Observer.Expect('bad', 'No|1D+1D');
        Observer.Expect('length', '5');
        Observer.Expect('spaces', 'Yes|1D');
        Observer.Expect('1D 9 empty', 'Yes|');
        Observer.Expect('1D 9 bad', 'No|');
        Observer.Verify();
    end;

    [Test]
    procedure DateFormula_Assign_Compare()
    var
        Observer: Codeunit "Probe Observer";
        A: DateFormula;
        B: DateFormula;
        C: DateFormula;
    begin
        Evaluate(A, '<1D>');
        Evaluate(B, '<1D>');
        Evaluate(C, '<2D>');
        Observer.Observe('A = B', Format(A = B));
        Observer.Observe('A = C', Format(A = C));
        Observer.Observe('A <> C', Format(A <> C));
        Observer.Observe('format A', Format(A));
        C := A;
        Observer.Observe('assigned', Format(C));
        Observer.Observe('assigned equal', Format(C = A));
        Clear(C);
        Observer.Observe('cleared', Format(C));
        Observer.Observe('cleared length', Format(StrLen(Format(C))));
        Observer.Observe('cleared = empty', Format(C = B));
        Observer.Observe('calcdate on cleared', Format(CalcDate(C, 20240115D), 0, 9));
        Evaluate(A, '<CM>');
        Observer.Observe('CM format', Format(A));
        Observer.Observe('CM calcdate', Format(CalcDate(A, 20240115D), 0, 9));
        Observer.Expect('A = B', 'Yes');
        Observer.Expect('A = C', 'No');
        Observer.Expect('A <> C', 'Yes');
        Observer.Expect('format A', '1D');
        Observer.Expect('assigned', '1D');
        Observer.Expect('assigned equal', 'Yes');
        Observer.Expect('cleared', '');
        Observer.Expect('cleared length', '0');
        Observer.Expect('cleared = empty', 'No');
        Observer.Expect('calcdate on cleared', '2024-01-15');
        Observer.Expect('CM format', 'CM');
        Observer.Expect('CM calcdate', '2024-01-31');
        Observer.Verify();
    end;

    // Corpus issue 672 item 13 (AL issue 8256): the date text that Format(20260101D) gives in a dd.mm.yy region, read as a Time and
    // as a Date in this session (en-US).
    [Test]
    procedure BT_DottedShortDate_AsTimeAndDate()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('time 01.01.26', ET('01.01.26', 0));
        Observer.Observe('time 01.01.26 fmt 9', ET('01.01.26', 9));
        Observer.Observe('date 01.01.26', ED('01.01.26', 0));
        Observer.Observe('time 01.01.2026', ET('01.01.2026', 0));
        Observer.Observe('date 01.01.2026', ED('01.01.2026', 0));
        Observer.Expect('time 01.01.26', 'Yes|01:01:26');
        Observer.Expect('time 01.01.26 fmt 9', 'No|');
        Observer.Expect('date 01.01.26', 'Yes|2026-01-01');
        Observer.Expect('time 01.01.2026', 'Yes|01:01:20.26');
        Observer.Expect('date 01.01.2026', 'Yes|2026-01-01');
        Observer.Verify();
    end;

    // Corpus issue 672 item 20: Evaluate of Duration texts with short unit names (d, m, min, sec, s, ms, milli, millis), a fraction
    // of milliseconds, and a fractional second followed by milliseconds (the Microsoft Learn example).
    [Test]
    procedure BT_Duration_UnitAbbreviations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('learn example', EDU('2days 4hours 3.7 seconds 17 milliseconds', 0));
        Observer.Observe('3.7 seconds 17 milliseconds', EDU('3.7 seconds 17 milliseconds', 0));
        Observer.Observe('1 d', EDU('1 d', 0));
        Observer.Observe('1 m', EDU('1 m', 0));
        Observer.Observe('1 min', EDU('1 min', 0));
        Observer.Observe('1 mins', EDU('1 mins', 0));
        Observer.Observe('1 sec', EDU('1 sec', 0));
        Observer.Observe('1 s', EDU('1 s', 0));
        Observer.Observe('5 ms', EDU('5 ms', 0));
        Observer.Observe('5 milli', EDU('5 milli', 0));
        Observer.Observe('5 millis', EDU('5 millis', 0));
        Observer.Observe('1.5 milliseconds', EDU('1.5 milliseconds', 0));
        Observer.Observe('1.5 seconds', EDU('1.5 seconds', 0));
        Observer.Observe('2 days 3 h 4 min 5 sec 6 ms', EDU('2 days 3 h 4 min 5 sec 6 ms', 0));
        Observer.Observe('1 D', EDU('1 D', 0));
        Observer.Observe('1 HOUR', EDU('1 HOUR', 0));
        Observer.Observe('1 week', EDU('1 week', 0));
        Observer.Expect('learn example', 'Yes|P2DT4H0M3.717S');
        Observer.Expect('3.7 seconds 17 milliseconds', 'Yes|P0DT0H0M3.717S');
        Observer.Expect('1 d', 'Yes|P1DT0H0M0.0S');
        Observer.Expect('1 m', 'Yes|P0DT0H1M0.0S');
        Observer.Expect('1 min', 'Yes|P0DT0H1M0.0S');
        Observer.Expect('1 mins', 'No|P0DT0H0M0.0S');
        Observer.Expect('1 sec', 'Yes|P0DT0H0M1.0S');
        Observer.Expect('1 s', 'Yes|P0DT0H0M1.0S');
        Observer.Expect('5 ms', 'No|P0DT0H0M0.0S');
        Observer.Expect('5 milli', 'Yes|P0DT0H0M0.005S');
        Observer.Expect('5 millis', 'Yes|P0DT0H0M0.005S');
        Observer.Expect('1.5 milliseconds', 'No|P0DT0H0M0.0S');
        Observer.Expect('1.5 seconds', 'Yes|P0DT0H0M1.5S');
        Observer.Expect('2 days 3 h 4 min 5 sec 6 ms', 'No|P0DT0H0M0.0S');
        Observer.Expect('1 D', 'Yes|P1DT0H0M0.0S');
        Observer.Expect('1 HOUR', 'Yes|P0DT1H0M0.0S');
        Observer.Expect('1 week', 'No|P0DT0H0M0.0S');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryEvalDuration(Txt: Text; Fmt: Integer; var Du: Duration)
    begin
        Evaluate(Du, Txt, Fmt);
    end;

    local procedure EvalDurationErr(Txt: Text; Fmt: Integer): Text
    var
        Du: Duration;
    begin
        ClearLastError();
        if TryEvalDuration(Txt, Fmt, Du) then
            exit('ok|' + Format(Du, 0, 9));
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryFormatDuration(Du: Duration; Fmt: Integer; var Result: Text)
    begin
        Result := Format(Du, 0, Fmt);
    end;

    local procedure FormatDurationErr(Ms: BigInteger; Fmt: Integer): Text
    var
        Du: Duration;
        Result: Text;
    begin
        Du := Ms;
        ClearLastError();
        if TryFormatDuration(Du, Fmt, Result) then
            exit('ok|' + Result);
        exit('err|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // Corpus issue 672 item 25 (AL issue 6707): Evaluate of a number text above the Integer maximum into a Duration (a plain number is
    // read in hours unless format 9 is given), and Format of a Duration at and above the largest .NET TimeSpan (922337203685477 ms).
    [Test]
    procedure BT_Duration_BeyondTimeSpan()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('eval 3000000000 fmt 0', EvalDurationErr('3000000000', 0));
        Observer.Observe('eval 3000000000 fmt 9', EvalDurationErr('3000000000', 9));
        Observer.Observe('eval 2147483647 fmt 0', EvalDurationErr('2147483647', 0));
        Observer.Observe('eval 256204778 fmt 0', EvalDurationErr('256204778', 0));
        Observer.Observe('eval 256204779 fmt 0', EvalDurationErr('256204779', 0));
        Observer.Observe('format max timespan 0', FormatDurationErr(922337203685477L, 0));
        Observer.Observe('format max timespan 9', FormatDurationErr(922337203685477L, 9));
        Observer.Observe('format above timespan 0', FormatDurationErr(922337203685478L, 0));
        Observer.Observe('format above timespan 9', FormatDurationErr(922337203685478L, 9));
        Observer.Observe('format 3e15 ms 0', FormatDurationErr(3000000000000000L, 0));
        Observer.Expect('eval 3000000000 fmt 0', 'ok|P125000000DT0H0M0.0S');
        Observer.Expect('eval 3000000000 fmt 9', 'err|The value "3000000000" can''t be evaluated into type Duration.|Evaluate');
        Observer.Expect('eval 2147483647 fmt 0', 'ok|P89478485DT7H0M0.0S');
        Observer.Expect('eval 256204778 fmt 0', 'ok|P10675199DT2H0M0.0S');
        Observer.Expect('eval 256204779 fmt 0', 'ok|P10675199DT3H0M0.0S');
        Observer.Expect('format max timespan 0', 'ok|10675199 days 2 hours 48 minutes 5 seconds 477 milliseconds');
        Observer.Expect('format max timespan 9', 'ok|P10675199DT2H48M5.477S');
        Observer.Expect('format above timespan 0', 'ok|10675199 days 2 hours 48 minutes 5 seconds 478 milliseconds');
        Observer.Expect('format above timespan 9', 'ok|P10675199DT2H48M5.478S');
        Observer.Expect('format 3e15 ms 0', 'ok|34722222 days 5 hours 20 minutes');
        Observer.Verify();
    end;
}
