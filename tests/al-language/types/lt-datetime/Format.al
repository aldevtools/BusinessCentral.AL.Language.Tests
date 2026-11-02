// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/date/date-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Topic: Format of Date, Time, DateTime, Duration with standard format numbers and custom strings
// Writer QR (2026-10-21), QR_* tests: custom strings of ISO-like time stamps (<Filler Character,0> mid-string after <Hours24,2>, 'T' and ';'
//   literals, <Hours24> without width, <Thousands>, <Second dec>) on a DateTime, a Time and a Date, and on 0DT, 0T and 0D.
//   BC: on a DateTime <Hours24,2> pads with 0 (09), on a Time with a space ( 9) unless <Filler Character,0> is in the string; 0DT and 0D give ''
//   for every string, 0T formats as 00:00:00 (12:00 AM).
// Writer Y64 (2026-11-01, Y64_* tests, al-runner issue 6650): <Second dec.> (with the period, as in the test libraries' unique-code builders) and its
//   neighbours (<Second dec.,N>, case, <Second dec,N> widths) on a Time and a DateTime with 0, 1, 2 and 3 digits of milliseconds, 0T and 0DT, with and without
//   <Filler Character,0>, and the reporter's whole string followed by DelChr.
// Writer TU (2026-10-29), TU_Time_Format_CodeNames (BC 29.0 SaaS sandbox, two runs, same values): code names on a Time.
//   BC: <Hours> and <Hour> give the 24-hour value (13 at 13:45); <Ho>, <H>, <Min>, <Sec>, <Thou>, <hours,2> and <HOURS,2> are accepted;
//   <Hourz>, <Hours24x,2> and <Hours 24> fail with InvalidFormatString. <Hours,2> pads with a space on a Time ( 9) and with 0 on a DateTime
//   (09); <Hours,1> of 13 gives *. The Length argument right-aligns a shorter result with spaces and cuts a longer one (no error).
// BC versions: 29 (27 and 28 by CI)

codeunit 73804 "LT DtT Format"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryFmt(V: Variant; Number: Integer; var Result: Text)
    var
        D: Date;
        T: Time;
        DT: DateTime;
        Du: Duration;
    begin
        if V.IsDate() then begin
            D := V;
            Result := Format(D, 0, Number);
        end else if V.IsTime() then begin
            T := V;
            Result := Format(T, 0, Number);
        end else if V.IsDateTime() then begin
            DT := V;
            Result := Format(DT, 0, Number);
        end else begin
            Du := V;
            Result := Format(Du, 0, Number);
        end;
    end;

    local procedure Fmt(V: Variant; Number: Integer): Text
    var
        Result: Text;
    begin
        if TryFmt(V, Number, Result) then
            exit(Result);
        exit('ERR:' + GetLastErrorText());
    end;

    [Test]
    procedure Date_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
        I: Integer;
    begin
        D := 20240305D;
        for I := 0 to 9 do
            Observer.Observe('date fmt ' + Format(I), Fmt(D, I));
        Observer.Observe('date fmt 10', Fmt(D, 10));
        Observer.Observe('date fmt 99', Fmt(D, 99));
        Observer.Observe('date fmt -1', Fmt(D, -1));
        Observer.Observe('date len 5', Format(D, 5, 9));
        Observer.Observe('date len 5 default', Format(D, 5));
        Observer.Observe('date len 20', Format(D, 20, 9));
        Observer.Observe('date default', Format(D));
        Observer.Expect('date fmt 0', '03/05/24');
        Observer.Expect('date fmt 1', '03/05/24');
        Observer.Expect('date fmt 2', '030524D');
        Observer.Expect('date fmt 3', '24/03/05');
        Observer.Expect('date fmt 4', 'March 5, 2024');
        Observer.Expect('date fmt 5', '030524');
        Observer.Expect('date fmt 6', '240305');
        Observer.Expect('date fmt 7', 'Mar 5, 2024');
        Observer.Expect('date fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Date''.');
        Observer.Expect('date fmt 9', '2024-03-05');
        Observer.Expect('date fmt 10', 'ERR:Standard format number 10 does not exist for the type ''Date''.');
        Observer.Expect('date fmt 99', 'ERR:Standard format number 99 does not exist for the type ''Date''.');
        Observer.Expect('date fmt -1', 'ERR:Standard format number -1 does not exist for the type ''Date''.');
        Observer.Expect('date len 5', '2024-');
        Observer.Expect('date len 5 default', '03/05');
        Observer.Expect('date len 20', '          2024-03-05');
        Observer.Expect('date default', '03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_0D_And_Bounds()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0D fmt ' + Format(I), Format(0D, 0, I));
        Observer.Observe('0D default', Format(0D));
        asserterror Observer.Observe('min 9', Format(00010101D, 0, 9));
        Observer.ObserveError('af74');
        asserterror Observer.Observe('min 0', Format(00010101D, 0, 0));
        Observer.ObserveError('af76');
        asserterror Observer.Observe('min 1', Format(00010101D, 0, 1));
        Observer.ObserveError('af78');
        asserterror Observer.Observe('min 4', Format(00010101D, 0, 4));
        Observer.ObserveError('af80');
        Observer.Observe('max 9', Format(99991231D, 0, 9));
        Observer.Observe('max 0', Format(99991231D, 0, 0));
        Observer.Observe('max 1', Format(99991231D, 0, 1));
        Observer.Observe('max 4', Format(99991231D, 0, 4));
        Observer.Expect('0D fmt 0', '');
        Observer.Expect('0D fmt 1', '');
        Observer.Expect('0D fmt 2', '');
        Observer.Expect('0D fmt 3', '');
        Observer.Expect('0D fmt 4', '');
        Observer.Expect('0D fmt 5', '');
        Observer.Expect('0D fmt 6', '');
        Observer.Expect('0D fmt 7', '');
        Observer.Expect('0D fmt 8', '');
        Observer.Expect('0D fmt 9', '');
        Observer.Expect('0D default', '');
        Observer.Expect('af74|text', 'The date is not valid.');
        Observer.Expect('af74|code', 'DateInvalid');
        Observer.Expect('af76|text', 'The date is not valid.');
        Observer.Expect('af76|code', 'DateInvalid');
        Observer.Expect('af78|text', 'The date is not valid.');
        Observer.Expect('af78|code', 'DateInvalid');
        Observer.Expect('af80|text', 'The date is not valid.');
        Observer.Expect('af80|code', 'DateInvalid');
        Observer.Expect('max 9', '9999-12-31');
        Observer.Expect('max 0', '12/31/9999');
        Observer.Expect('max 1', '12/31/9999');
        Observer.Expect('max 4', 'December 31, 9999');
        Observer.Verify();
    end;

    [Test]
    procedure Date_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240305D;
        Observer.Observe('Day', Format(D, 0, '<Day>'));
        Observer.Observe('Day,2', Format(D, 0, '<Day,2>'));
        Observer.Observe('Day,3', Format(D, 0, '<Day,3>'));
        Observer.Observe('Month', Format(D, 0, '<Month>'));
        Observer.Observe('Month,2', Format(D, 0, '<Month,2>'));
        Observer.Observe('Month Text', Format(D, 0, '<Month Text>'));
        Observer.Observe('Month Text,3', Format(D, 0, '<Month Text,3>'));
        Observer.Observe('Year', Format(D, 0, '<Year>'));
        Observer.Observe('Year4', Format(D, 0, '<Year4>'));
        Observer.Observe('Closing', Format(D, 0, '<Closing>'));
        Observer.Observe('Standard Format 9', Format(D, 0, '<Standard Format,9>'));
        Observer.Observe('Standard Format 0', Format(D, 0, '<Standard Format,0>'));
        Observer.Observe('Standard Format 1', Format(D, 0, '<Standard Format,1>'));
        Observer.Observe('Standard Format 4', Format(D, 0, '<Standard Format,4>'));
        Observer.Observe('Day+Month', Format(D, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('dash', Format(D, 0, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('literal', Format(D, 0, 'Date: <Day>/<Month>'));
        asserterror Observer.Observe('Day Text', Format(D, 0, '<Day Text>'));
        Observer.ObserveError('af110');
        Observer.Observe('Weekday Text', Format(D, 0, '<Weekday Text>'));
        Observer.Observe('Week', Format(D, 0, '<Week>'));
        Observer.Observe('Week,2', Format(D, 0, '<Week,2>'));
        asserterror Observer.Observe('bad tag', Format(D, 0, '<Foo>'));
        Observer.ObserveError('af116');
        Observer.Observe('empty custom', Format(D, 0, ''));
        Observer.Observe('Closing on closing', Format(ClosingDate(D), 0, '<Closing><Day>'));
        Observer.Observe('Closing format 9', Format(ClosingDate(D), 0, 9));
        Observer.Observe('Closing format 0', Format(ClosingDate(D), 0, 0));
        Observer.Observe('Closing format 1', Format(ClosingDate(D), 0, 1));
        Observer.Expect('Day', '5');
        Observer.Expect('Day,2', '05');
        Observer.Expect('Day,3', '005');
        Observer.Expect('Month', '3');
        Observer.Expect('Month,2', '03');
        Observer.Expect('Month Text', 'March');
        Observer.Expect('Month Text,3', 'Mar');
        Observer.Expect('Year', '24');
        Observer.Expect('Year4', '2024');
        Observer.Expect('Closing', '');
        Observer.Expect('Standard Format 9', '2024-03-05');
        Observer.Expect('Standard Format 0', '03/05/24');
        Observer.Expect('Standard Format 1', '03/05/24');
        Observer.Expect('Standard Format 4', 'March 5, 2024');
        Observer.Expect('Day+Month', '05.03.2024');
        Observer.Expect('dash', '2024-03-05');
        Observer.Expect('literal', 'Date: 5/3');
        Observer.Expect('af110|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Day Text>');
        Observer.Expect('af110|code', 'InvalidFormatString');
        Observer.Expect('Weekday Text', 'Tuesday');
        Observer.Expect('Week', '10');
        Observer.Expect('Week,2', '10');
        Observer.Expect('af116|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af116|code', 'InvalidFormatString');
        Observer.Expect('empty custom', '');
        Observer.Expect('Closing on closing', 'C5');
        Observer.Expect('Closing format 9', '2024-03-05');
        Observer.Expect('Closing format 0', 'C03/05/24');
        Observer.Expect('Closing format 1', 'C03/05/24');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
        I: Integer;
    begin
        T := 134506.078T;
        for I := 0 to 9 do
            Observer.Observe('time fmt ' + Format(I), Fmt(T, I));
        Observer.Observe('time fmt 10', Fmt(T, 10));
        Observer.Observe('time fmt -1', Fmt(T, -1));
        Observer.Observe('time default', Format(T));
        Observer.Observe('time len 4', Format(T, 4, 9));
        Observer.Expect('time fmt 0', ' 1:45:06 PM');
        Observer.Expect('time fmt 1', ' 1:45:06.078 PM');
        Observer.Expect('time fmt 2', '134506.078T');
        Observer.Expect('time fmt 3', 'ERR:Standard format number 3 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 4', 'ERR:Standard format number 4 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 5', 'ERR:Standard format number 5 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 6', 'ERR:Standard format number 6 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 7', 'ERR:Standard format number 7 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Time''.');
        Observer.Expect('time fmt 9', '13:45:06.078');
        Observer.Expect('time fmt 10', 'ERR:Standard format number 10 does not exist for the type ''Time''.');
        Observer.Expect('time fmt -1', 'ERR:Standard format number -1 does not exist for the type ''Time''.');
        Observer.Expect('time default', ' 1:45:06 PM');
        Observer.Expect('time len 4', '13:4');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0T fmt ' + Format(I), Format(0T, 0, I));
        for I := 0 to 2 do begin
            Observer.Observe('midnight fmt ' + Format(I), Format(000000T, 0, I));
            Observer.Observe('noon fmt ' + Format(I), Format(120000T, 0, I));
            Observer.Observe('1am fmt ' + Format(I), Format(010000T, 0, I));
            Observer.Observe('1pm fmt ' + Format(I), Format(130000T, 0, I));
            Observer.Observe('max fmt ' + Format(I), Format(235959.999T, 0, I));
        end;
        Observer.Expect('0T fmt 0', '');
        Observer.Expect('0T fmt 1', '');
        Observer.Expect('0T fmt 2', '');
        Observer.Expect('0T fmt 3', '');
        Observer.Expect('0T fmt 4', '');
        Observer.Expect('0T fmt 5', '');
        Observer.Expect('0T fmt 6', '');
        Observer.Expect('0T fmt 7', '');
        Observer.Expect('0T fmt 8', '');
        Observer.Expect('0T fmt 9', '');
        Observer.Expect('midnight fmt 0', '12:00:00 AM');
        Observer.Expect('noon fmt 0', '12:00:00 PM');
        Observer.Expect('1am fmt 0', ' 1:00:00 AM');
        Observer.Expect('1pm fmt 0', ' 1:00:00 PM');
        Observer.Expect('max fmt 0', '11:59:59 PM');
        Observer.Expect('midnight fmt 1', '12:00:00 AM');
        Observer.Expect('noon fmt 1', '12:00:00 PM');
        Observer.Expect('1am fmt 1', ' 1:00:00 AM');
        Observer.Expect('1pm fmt 1', ' 1:00:00 PM');
        Observer.Expect('max fmt 1', '11:59:59.999 PM');
        Observer.Expect('midnight fmt 2', '000000T');
        Observer.Expect('noon fmt 2', '120000T');
        Observer.Expect('1am fmt 2', '010000T');
        Observer.Expect('1pm fmt 2', '130000T');
        Observer.Expect('max fmt 2', '235959.999T');
        Observer.Verify();
    end;

    [Test]
    procedure Time_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 134506.078T;
        Observer.Observe('Hours24', Format(T, 0, '<Hours24>'));
        Observer.Observe('Hours24,2', Format(T, 0, '<Hours24,2>'));
        Observer.Observe('Hours12', Format(T, 0, '<Hours12>'));
        Observer.Observe('Hours12,2', Format(T, 0, '<Hours12,2>'));
        Observer.Observe('Minutes', Format(T, 0, '<Minutes>'));
        Observer.Observe('Minutes,2', Format(T, 0, '<Minutes,2>'));
        Observer.Observe('Seconds', Format(T, 0, '<Seconds>'));
        Observer.Observe('Seconds,2', Format(T, 0, '<Seconds,2>'));
        Observer.Observe('Thousands', Format(T, 0, '<Thousands>'));
        Observer.Observe('Thousands,3', Format(T, 0, '<Thousands,3>'));
        Observer.Observe('Second dec', Format(T, 0, '<Second dec>'));
        Observer.Observe('Second dec,3', Format(T, 0, '<Second dec,3>'));
        Observer.Observe('AM/PM', Format(T, 0, '<AM/PM>'));
        Observer.Observe('AM/PM morning', Format(090000T, 0, '<AM/PM>'));
        Observer.Observe('Hours12 midnight', Format(000000T, 0, '<Hours12>'));
        Observer.Observe('Hours12 noon', Format(120000T, 0, '<Hours12>'));
        Observer.Observe('hms', Format(T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('hms ms', Format(T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('Standard Format 9', Format(T, 0, '<Standard Format,9>'));
        Observer.Observe('Standard Format 0', Format(T, 0, '<Standard Format,0>'));
        Observer.Observe('Standard Format 2', Format(T, 0, '<Standard Format,2>'));
        asserterror Observer.Observe('bad tag', Format(T, 0, '<Foo>'));
        Observer.ObserveError('af187');
        Observer.Observe('literal', Format(T, 0, 'At <Hours24>h'));
        Observer.Expect('Hours24', '13');
        Observer.Expect('Hours24,2', '13');
        Observer.Expect('Hours12', '1');
        Observer.Expect('Hours12,2', ' 1');
        Observer.Expect('Minutes', '45');
        Observer.Expect('Minutes,2', '45');
        Observer.Expect('Seconds', '6');
        Observer.Expect('Seconds,2', '06');
        Observer.Expect('Thousands', '78');
        Observer.Expect('Thousands,3', ' 78');
        Observer.Expect('Second dec', '.078');
        Observer.Expect('Second dec,3', '***');
        Observer.Expect('AM/PM', 'PM');
        Observer.Expect('AM/PM morning', 'AM');
        Observer.Expect('Hours12 midnight', '12');
        Observer.Expect('Hours12 noon', '12');
        Observer.Expect('hms', '13:45:06');
        Observer.Expect('hms ms', '13:45:06. 78');
        Observer.Expect('Standard Format 9', '13:45:06.078');
        Observer.Expect('Standard Format 0', ' 1:45:06 PM');
        Observer.Expect('Standard Format 2', '134506.078T');
        Observer.Expect('af187|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af187|code', 'InvalidFormatString');
        Observer.Expect('literal', 'At 13h');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Numbers()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
        I: Integer;
    begin
        DT := CreateDateTime(20240305D, 134506.078T);
        for I := 0 to 9 do
            Observer.Observe('dt fmt ' + Format(I), Fmt(DT, I));
        Observer.Observe('dt fmt 10', Fmt(DT, 10));
        Observer.Observe('dt fmt -1', Fmt(DT, -1));
        Observer.Observe('dt default', Format(DT));
        Observer.Observe('dt len 8', Format(DT, 8, 9));
        Observer.Expect('dt fmt 0', '03/05/24 01:45 PM');
        Observer.Expect('dt fmt 1', '03/05/24 01:45:06.078 PM');
        Observer.Expect('dt fmt 2', '03/05/24 01:45 PM');
        Observer.Expect('dt fmt 3', '03/05/24 01:45:06 PM');
        Observer.Expect('dt fmt 4', 'ERR:Standard format number 4 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 5', 'ERR:Standard format number 5 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 6', 'ERR:Standard format number 6 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 7', 'ERR:Standard format number 7 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 8', 'ERR:Standard format number 8 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt 9', '2024-03-05T13:45:06.078Z');
        Observer.Expect('dt fmt 10', 'ERR:Standard format number 10 does not exist for the type ''DateTime''.');
        Observer.Expect('dt fmt -1', 'ERR:Standard format number -1 does not exist for the type ''DateTime''.');
        Observer.Expect('dt default', '03/05/24 01:45 PM');
        Observer.Expect('dt len 8', '2024-03-');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Values()
    var
        Observer: Codeunit "Probe Observer";
        I: Integer;
    begin
        for I := 0 to 9 do
            Observer.Observe('0DT fmt ' + Format(I), Format(0DT, 0, I));
        asserterror Observer.Observe('min 9', Format(CreateDateTime(00010101D, 000000T), 0, 9));
        Observer.ObserveError('af218');
        asserterror Observer.Observe('min 0', Format(CreateDateTime(00010101D, 000000T), 0, 0));
        Observer.ObserveError('af222');
        Observer.Observe('max 9', Format(CreateDateTime(99991231D, 235959.999T), 0, 9));
        Observer.Observe('max 0', Format(CreateDateTime(99991231D, 235959.999T), 0, 0));
        Observer.Observe('date only 9', Format(CreateDateTime(20240305D, 0T), 0, 9));
        Observer.Observe('date only 0', Format(CreateDateTime(20240305D, 0T), 0, 0));
        Observer.Observe('midnight 9', Format(CreateDateTime(20240305D, 000000T), 0, 9));
        asserterror Observer.Observe('time only 9', Format(CreateDateTime(0D, 123456T), 0, 9));
        Observer.ObserveError('af230');
        asserterror Observer.Observe('time only 0', Format(CreateDateTime(0D, 123456T), 0, 0));
        Observer.ObserveError('af233');
        Observer.Expect('0DT fmt 0', '');
        Observer.Expect('0DT fmt 1', '');
        Observer.Expect('0DT fmt 2', '');
        Observer.Expect('0DT fmt 3', '');
        Observer.Expect('0DT fmt 4', '');
        Observer.Expect('0DT fmt 5', '');
        Observer.Expect('0DT fmt 6', '');
        Observer.Expect('0DT fmt 7', '');
        Observer.Expect('0DT fmt 8', '');
        Observer.Expect('0DT fmt 9', '');
        Observer.Expect('af218|text', 'The date is not valid.');
        Observer.Expect('af218|code', 'DateInvalid');
        Observer.Expect('af222|text', 'The date is not valid.');
        Observer.Expect('af222|code', 'DateInvalid');
        Observer.Expect('max 9', '9999-12-31T23:59:59.999Z');
        Observer.Expect('max 0', '12/31/9999 11:59 PM');
        Observer.Expect('date only 9', '2024-03-05T00:00:00Z');
        Observer.Expect('date only 0', '03/05/24 12:00 AM');
        Observer.Expect('midnight 9', '2024-03-05T00:00:00Z');
        Observer.Expect('af230|text', 'The date is not valid.');
        Observer.Expect('af230|code', 'DateInvalid');
        Observer.Expect('af233|text', 'The date is not valid.');
        Observer.Expect('af233|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Format_Custom()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240305D, 134506.078T);
        Observer.Observe('year4', Format(DT, 0, '<Year4>'));
        Observer.Observe('day month', Format(DT, 0, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('date time', Format(DT, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('ms', Format(DT, 0, '<Thousands,3>'));
        Observer.Observe('AM/PM', Format(DT, 0, '<AM/PM>'));
        Observer.Observe('Hours12', Format(DT, 0, '<Hours12,2>'));
        Observer.Observe('Standard 9', Format(DT, 0, '<Standard Format,9>'));
        Observer.Observe('Standard 0', Format(DT, 0, '<Standard Format,0>'));
        Observer.Observe('Standard 1', Format(DT, 0, '<Standard Format,1>'));
        Observer.Observe('Standard 2', Format(DT, 0, '<Standard Format,2>'));
        Observer.Observe('Standard 3', Format(DT, 0, '<Standard Format,3>'));
        asserterror Observer.Observe('bad tag', Format(DT, 0, '<Foo>'));
        Observer.ObserveError('af249');
        Observer.Observe('0DT custom', Format(0DT, 0, '<Year4>'));
        Observer.Expect('year4', '2024');
        Observer.Expect('day month', '05.03.2024');
        Observer.Expect('date time', '2024-03-05 13:45:06');
        Observer.Expect('ms', '078');
        Observer.Expect('AM/PM', 'PM');
        Observer.Expect('Hours12', '01');
        Observer.Expect('Standard 9', '2024-03-05T13:45:06.078Z');
        Observer.Expect('Standard 0', '03/05/24 01:45 PM');
        Observer.Expect('Standard 1', '03/05/24 01:45:06.078 PM');
        Observer.Expect('Standard 2', '03/05/24 01:45 PM');
        Observer.Expect('Standard 3', '03/05/24 01:45:06 PM');
        Observer.Expect('af249|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Foo>');
        Observer.Expect('af249|code', 'InvalidFormatString');
        Observer.Expect('0DT custom', '');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_Format()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
        I: Integer;
    begin
        D := 90061001;
        for I := 0 to 9 do
            Observer.Observe('dur fmt ' + Format(I), Fmt(D, I));
        Observer.Observe('dur default', Format(D));
        Observer.Observe('dur 0', Format(Duration_Zero()));
        Observer.Observe('dur 1 ms', Format(Duration_From(1)));
        Observer.Observe('dur 999 ms', Format(Duration_From(999)));
        Observer.Observe('dur 1 s', Format(Duration_From(1000)));
        Observer.Observe('dur 1 min', Format(Duration_From(60000)));
        Observer.Observe('dur 1 h', Format(Duration_From(3600000)));
        Observer.Observe('dur 1 d', Format(Duration_From(86400000)));
        Observer.Observe('dur 2 d', Format(Duration_From(172800000)));
        Observer.Observe('dur 1h30m', Format(Duration_From(5400000)));
        Observer.Observe('dur neg', Format(Duration_From(-5400000)));
        Observer.Observe('dur neg 9', Format(Duration_From(-5400000), 0, 9));
        Observer.Observe('dur 1 s 9', Format(Duration_From(1000), 0, 9));
        Observer.Observe('dur 1 d 9', Format(Duration_From(86400000), 0, 9));
        asserterror Observer.Observe('dur custom', Format(Duration_From(5400000), 0, '<Hours24,2>:<Minutes,2>'));
        Observer.ObserveError('af279');
        Observer.Expect('dur fmt 0', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur fmt 1', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur fmt 2', '1 0 1 2 1 4 1 6 1 8');
        Observer.Expect('dur fmt 3', 'ERR:Standard format number 3 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 4', 'ERR:Standard format number 4 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 5', 'ERR:Standard format number 5 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 6', 'ERR:Standard format number 6 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 7', 'ERR:Standard format number 7 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 8', 'ERR:Standard format number 8 does not exist for the type ''Duration''.');
        Observer.Expect('dur fmt 9', 'P1DT1H1M1.001S');
        Observer.Expect('dur default', '1 day 1 hour 1 minute 1 second 1 millisecond');
        Observer.Expect('dur 0', '');
        Observer.Expect('dur 1 ms', '1 millisecond');
        Observer.Expect('dur 999 ms', '999 milliseconds');
        Observer.Expect('dur 1 s', '1 second');
        Observer.Expect('dur 1 min', '1 minute');
        Observer.Expect('dur 1 h', '1 hour');
        Observer.Expect('dur 1 d', '1 day');
        Observer.Expect('dur 2 d', '2 days');
        Observer.Expect('dur 1h30m', '1 hour 30 minutes');
        Observer.Expect('dur neg', '-1 hour 30 minutes');
        Observer.Expect('dur neg 9', '-P0DT1H30M0.0S');
        Observer.Expect('dur 1 s 9', 'P0DT0H0M1.0S');
        Observer.Expect('dur 1 d 9', 'P1DT0H0M0.0S');
        Observer.Expect('af279|text', 'An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24,2>:<Minutes,2>');
        Observer.Expect('af279|code', 'InvalidFormatString');
        Observer.Verify();
    end;

    local procedure Duration_Zero(): Duration
    var
        D: Duration;
    begin
        exit(D);
    end;

    local procedure Duration_From(Ms: BigInteger): Duration
    begin
        exit(Ms);
    end;

    [Test]
    procedure Format_Length_Truncation()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('date len 1', Format(20240305D, 1, 9));
        Observer.Observe('date len 4', Format(20240305D, 4, 9));
        Observer.Observe('date len 10', Format(20240305D, 10, 9));
        Observer.Observe('date len 11', Format(20240305D, 11, 9));
        Observer.Observe('date len -1', Format(20240305D, -1, 9));
        Observer.Observe('time len 3', Format(134506T, 3, 9));
        Observer.Observe('dt len 10', Format(CreateDateTime(20240305D, 134506T), 10, 9));
        Observer.Observe('dt len 30', Format(CreateDateTime(20240305D, 134506T), 30, 9));
        Observer.Observe('date len 5 fmt 0', Format(20240305D, 5, 0));
        Observer.Observe('date len 5 custom', Format(20240305D, 5, '<Year4>-<Month,2>'));
        Observer.Expect('date len 1', '2');
        Observer.Expect('date len 4', '2024');
        Observer.Expect('date len 10', '2024-03-05');
        Observer.Expect('date len 11', ' 2024-03-05');
        Observer.Expect('date len -1', '2');
        Observer.Expect('time len 3', '13:');
        Observer.Expect('dt len 10', '2024-03-05');
        Observer.Expect('dt len 30', '          2024-03-05T13:45:06Z');
        Observer.Expect('date len 5 fmt 0', '03/05');
        Observer.Expect('date len 5 custom', '2024-');
        Observer.Verify();
    end;

    // Writer QR (2026-10-21): Format with a custom string of the forms an ISO-like time stamp is built from: <Filler Character,0> in the
    // middle of the string after <Hours24,2>, ';' and 'T' as literals, <Hours24> without a width, the time codes on a DateTime, and the
    // same strings on 0D, 0T and 0DT. Observation names are the index of the string in the procedure (the strings are in the code).
    [TryFunction]
    local procedure TryFmtStr(V: Variant; FormatString: Text; var Result: Text)
    var
        D: Date;
        T: Time;
        DT: DateTime;
    begin
        if V.IsDate() then begin
            D := V;
            Result := Format(D, 0, FormatString);
        end else if V.IsTime() then begin
            T := V;
            Result := Format(T, 0, FormatString);
        end else begin
            DT := V;
            Result := Format(DT, 0, FormatString);
        end;
    end;

    local procedure FmtStr(V: Variant; FormatString: Text): Text
    var
        Result: Text;
    begin
        if TryFmtStr(V, FormatString, Result) then
            exit('[' + Result + ']');
        exit('ERR:' + GetLastErrorText());
    end;

    [Test]
    procedure QR_DateTime_Format_StampStrings_Morning()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20240305D, 090702.123T);
        Observer.Observe('m1', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m2', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Filler Character,0><Minutes,2><Seconds,2>'));
        Observer.Observe('m3', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>;<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m4', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m5', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('m6', FmtStr(DT, '<Year,2><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('m7', FmtStr(DT, '<Day,2>/<Month,2>/<Year,2>;<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m8', FmtStr(DT, '<Hours24>'));
        Observer.Observe('m9', FmtStr(DT, '<Hours24>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m10', FmtStr(DT, '<Hours24,2>-<Minutes,2>-<Seconds,2>'));
        Observer.Observe('m11', FmtStr(DT, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('m12', FmtStr(DT, '<Hours24><Minutes,2>'));
        Observer.Observe('m13', FmtStr(DT, '<Minutes,2>'));
        Observer.Observe('m14', FmtStr(DT, '<Thousands>'));
        Observer.Observe('m15', FmtStr(DT, '<Second dec>'));
        Observer.Observe('m16', FmtStr(DT, '<Seconds,2><Second dec>'));
        Observer.Expect('m1', '[2024-03-05T09:07:02]');
        Observer.Expect('m2', '[20240305090702]');
        Observer.Expect('m3', '[2024-03-05;09:07:02]');
        Observer.Expect('m4', '[2024-03-05T09:07:02]');
        Observer.Expect('m5', '[20240305090702]');
        Observer.Expect('m6', '[240305090702]');
        Observer.Expect('m7', '[05/03/24;09:07:02]');
        Observer.Expect('m8', '[9]');
        Observer.Expect('m9', '[9:07:02]');
        Observer.Expect('m10', '[09-07-02]');
        Observer.Expect('m11', '[09:07:02]');
        Observer.Expect('m12', '[907]');
        Observer.Expect('m13', '[07]');
        Observer.Expect('m14', '[123]');
        Observer.Expect('m15', '[.123]');
        Observer.Expect('m16', '[02.123]');
        Observer.Verify();
    end;

    [Test]
    procedure QR_DateTime_Format_StampStrings_Afternoon()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := CreateDateTime(20241231D, 134506T);
        Observer.Observe('a1', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a2', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Filler Character,0><Minutes,2><Seconds,2>'));
        Observer.Observe('a3', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>;<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a4', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a5', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('a6', FmtStr(DT, '<Year,2><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('a7', FmtStr(DT, '<Day,2>/<Month,2>/<Year,2>;<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a8', FmtStr(DT, '<Hours24>'));
        Observer.Observe('a9', FmtStr(DT, '<Hours24>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a10', FmtStr(DT, '<Hours24,2>-<Minutes,2>-<Seconds,2>'));
        Observer.Observe('a11', FmtStr(DT, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('a12', FmtStr(DT, '<Hours24><Minutes,2>'));
        Observer.Observe('a13', FmtStr(DT, '<Minutes,2>'));
        Observer.Observe('a14', FmtStr(DT, '<Thousands>'));
        Observer.Observe('a15', FmtStr(DT, '<Second dec>'));
        Observer.Observe('a16', FmtStr(DT, '<Seconds,2><Second dec>'));
        Observer.Expect('a1', '[2024-12-31T13:45:06]');
        Observer.Expect('a2', '[20241231134506]');
        Observer.Expect('a3', '[2024-12-31;13:45:06]');
        Observer.Expect('a4', '[2024-12-31T13:45:06]');
        Observer.Expect('a5', '[20241231134506]');
        Observer.Expect('a6', '[241231134506]');
        Observer.Expect('a7', '[31/12/24;13:45:06]');
        Observer.Expect('a8', '[13]');
        Observer.Expect('a9', '[13:45:06]');
        Observer.Expect('a10', '[13-45-06]');
        Observer.Expect('a11', '[13:45:06]');
        Observer.Expect('a12', '[1345]');
        Observer.Expect('a13', '[45]');
        Observer.Expect('a14', '[0]');
        Observer.Expect('a15', '[]');
        Observer.Expect('a16', '[06]');
        Observer.Verify();
    end;

    [Test]
    procedure QR_DateTime_Format_StampStrings_Undefined()
    var
        Observer: Codeunit "Probe Observer";
        DT: DateTime;
    begin
        DT := 0DT;
        Observer.Observe('u1', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('u2', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Filler Character,0><Minutes,2><Seconds,2>'));
        Observer.Observe('u3', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>;<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('u4', FmtStr(DT, '<Year4>-<Month,2>-<Day,2>T<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('u5', FmtStr(DT, '<Year4><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('u6', FmtStr(DT, '<Year,2><Month,2><Day,2><Hours24,2><Minutes,2><Seconds,2>'));
        Observer.Observe('u7', FmtStr(DT, '<Day,2>/<Month,2>/<Year,2>;<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('u8', FmtStr(DT, '<Hours24>'));
        Observer.Expect('u1', '[]');
        Observer.Expect('u2', '[]');
        Observer.Expect('u3', '[]');
        Observer.Expect('u4', '[]');
        Observer.Expect('u5', '[]');
        Observer.Expect('u6', '[]');
        Observer.Expect('u7', '[]');
        Observer.Expect('u8', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Time_Format_StampStrings()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 090702.123T;
        Observer.Observe('t1', FmtStr(T, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('t2', FmtStr(T, '<Hours24,2>-<Minutes,2>-<Seconds,2>'));
        Observer.Observe('t3', FmtStr(T, '<Hours24>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('t4', FmtStr(T, '<Hours24,2><Filler Character,0><Minutes,2>'));
        Observer.Observe('t5', FmtStr(T, '<Hours12,2><Filler Character,0>:<Minutes,2> <AM/PM>'));
        T := 0T;
        Observer.Observe('z1', FmtStr(T, '<Hours24,2><Filler Character,0>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('z2', FmtStr(T, '<Hours24,2>-<Minutes,2>-<Seconds,2>'));
        Observer.Observe('z3', FmtStr(T, '<Hours24>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('z4', FmtStr(T, '<Hours24,2><Filler Character,0><Minutes,2>'));
        Observer.Observe('z5', FmtStr(T, '<Hours12,2><Filler Character,0>:<Minutes,2> <AM/PM>'));
        Observer.Expect('t1', '[09:07:02]');
        Observer.Expect('t2', '[ 9-07-02]');
        Observer.Expect('t3', '[9:07:02]');
        Observer.Expect('t4', '[0907]');
        Observer.Expect('t5', '[09:07 AM]');
        Observer.Expect('z1', '[00:00:00]');
        Observer.Expect('z2', '[ 0-00-00]');
        Observer.Expect('z3', '[0:00:00]');
        Observer.Expect('z4', '[0000]');
        Observer.Expect('z5', '[12:00 AM]');
        Observer.Verify();
    end;

    [Test]
    procedure QR_Date_Format_StampStrings()
    var
        Observer: Codeunit "Probe Observer";
        D: Date;
    begin
        D := 20240305D;
        Observer.Observe('d1', FmtStr(D, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('d2', FmtStr(D, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('d3', FmtStr(D, '<Day,2>/<Month,2>/<Year4>'));
        Observer.Observe('d4', FmtStr(D, '<Year4>.<Month,2>.<Day,2>'));
        Observer.Observe('d5', FmtStr(D, '<Day,2><Month,2><Year4>'));
        Observer.Observe('d6', FmtStr(D, '<Day,2><Month,2><Year,2>'));
        Observer.Observe('d7', FmtStr(D, '<DAY>. <MONTH text> <YEAR4>'));
        Observer.Observe('d8', FmtStr(D, '<Weekday Text>'));
        Observer.Observe('d9', FmtStr(D, '<Week>'));
        D := 0D;
        Observer.Observe('z1', FmtStr(D, '<Year4>-<Month,2>-<Day,2>'));
        Observer.Observe('z2', FmtStr(D, '<Day,2>.<Month,2>.<Year4>'));
        Observer.Observe('z3', FmtStr(D, '<Day,2>/<Month,2>/<Year4>'));
        Observer.Observe('z4', FmtStr(D, '<Year4>.<Month,2>.<Day,2>'));
        Observer.Observe('z5', FmtStr(D, '<Day,2><Month,2><Year4>'));
        Observer.Observe('z6', FmtStr(D, '<Day,2><Month,2><Year,2>'));
        Observer.Observe('z7', FmtStr(D, '<DAY>. <MONTH text> <YEAR4>'));
        Observer.Observe('z8', FmtStr(D, '<Weekday Text>'));
        Observer.Observe('z9', FmtStr(D, '<Week>'));
        Observer.Expect('d1', '[2024-03-05]');
        Observer.Expect('d2', '[05.03.2024]');
        Observer.Expect('d3', '[05/03/2024]');
        Observer.Expect('d4', '[2024.03.05]');
        Observer.Expect('d5', '[05032024]');
        Observer.Expect('d6', '[050324]');
        Observer.Expect('d7', '[5. March 2024]');
        Observer.Expect('d8', '[Tuesday]');
        Observer.Expect('d9', '[10]');
        Observer.Expect('z1', '[]');
        Observer.Expect('z2', '[]');
        Observer.Expect('z3', '[]');
        Observer.Expect('z4', '[]');
        Observer.Expect('z5', '[]');
        Observer.Expect('z6', '[]');
        Observer.Expect('z7', '[]');
        Observer.Expect('z8', '[]');
        Observer.Expect('z9', '[]');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TuTryFormatTime(Value: Time; Length: Integer; FormatString: Text; var Result: Text)
    begin
        Result := Format(Value, Length, FormatString);
    end;

    [TryFunction]
    local procedure TuTryFormatDateTime(Value: DateTime; Length: Integer; FormatString: Text; var Result: Text)
    begin
        Result := Format(Value, Length, FormatString);
    end;

    local procedure TuFormatTime(Value: Time; Length: Integer; FormatString: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TuTryFormatTime(Value, Length, FormatString, Result) then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    local procedure TuFormatDateTime(Value: DateTime; Length: Integer; FormatString: Text): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TuTryFormatDateTime(Value, Length, FormatString, Result) then
            exit('[' + Result + ']');
        exit('error: ' + GetLastErrorText() + ' | ' + GetLastErrorCode());
    end;

    [Test]
    procedure TU_Time_Format_CodeNames()
    var
        Observer: Codeunit "Probe Observer";
    begin
        // Format of a Time with code names with a length: <Hours,2> (not Hours24/Hours12), unknown names, and the Length argument 8.
        // Each value is [text] or 'error: <text> | <code>'.
        Observer.Observe('0905 <Hours>', TuFormatTime(090503.007T, 0, '<Hours>'));
        Observer.Observe('1345 <Hours>', TuFormatTime(134506.078T, 0, '<Hours>'));
        Observer.Observe('0905 len8 <Hours>', TuFormatTime(090503.007T, 8, '<Hours>'));
        Observer.Observe('0905 <Hours,2>', TuFormatTime(090503.007T, 0, '<Hours,2>'));
        Observer.Observe('1345 <Hours,2>', TuFormatTime(134506.078T, 0, '<Hours,2>'));
        Observer.Observe('0905 len8 <Hours,2>', TuFormatTime(090503.007T, 8, '<Hours,2>'));
        Observer.Observe('0905 <Hours,1>', TuFormatTime(090503.007T, 0, '<Hours,1>'));
        Observer.Observe('1345 <Hours,1>', TuFormatTime(134506.078T, 0, '<Hours,1>'));
        Observer.Observe('0905 len8 <Hours,1>', TuFormatTime(090503.007T, 8, '<Hours,1>'));
        Observer.Observe('0905 <Hours,3>', TuFormatTime(090503.007T, 0, '<Hours,3>'));
        Observer.Observe('1345 <Hours,3>', TuFormatTime(134506.078T, 0, '<Hours,3>'));
        Observer.Observe('0905 len8 <Hours,3>', TuFormatTime(090503.007T, 8, '<Hours,3>'));
        Observer.Observe('0905 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('1345 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(134506.078T, 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 len8 <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Hour>', TuFormatTime(090503.007T, 0, '<Hour>'));
        Observer.Observe('1345 <Hour>', TuFormatTime(134506.078T, 0, '<Hour>'));
        Observer.Observe('0905 len8 <Hour>', TuFormatTime(090503.007T, 8, '<Hour>'));
        Observer.Observe('0905 <Minute>', TuFormatTime(090503.007T, 0, '<Minute>'));
        Observer.Observe('1345 <Minute>', TuFormatTime(134506.078T, 0, '<Minute>'));
        Observer.Observe('0905 len8 <Minute>', TuFormatTime(090503.007T, 8, '<Minute>'));
        Observer.Observe('0905 <Second>', TuFormatTime(090503.007T, 0, '<Second>'));
        Observer.Observe('1345 <Second>', TuFormatTime(134506.078T, 0, '<Second>'));
        Observer.Observe('0905 len8 <Second>', TuFormatTime(090503.007T, 8, '<Second>'));
        Observer.Observe('0905 <Hours24,2>', TuFormatTime(090503.007T, 0, '<Hours24,2>'));
        Observer.Observe('1345 <Hours24,2>', TuFormatTime(134506.078T, 0, '<Hours24,2>'));
        Observer.Observe('0905 len8 <Hours24,2>', TuFormatTime(090503.007T, 8, '<Hours24,2>'));
        Observer.Observe('0905 <Hours12>', TuFormatTime(090503.007T, 0, '<Hours12>'));
        Observer.Observe('1345 <Hours12>', TuFormatTime(134506.078T, 0, '<Hours12>'));
        Observer.Observe('0905 len8 <Hours12>', TuFormatTime(090503.007T, 8, '<Hours12>'));
        Observer.Observe('0905 <Thousands>', TuFormatTime(090503.007T, 0, '<Thousands>'));
        Observer.Observe('1345 <Thousands>', TuFormatTime(134506.078T, 0, '<Thousands>'));
        Observer.Observe('0905 len8 <Thousands>', TuFormatTime(090503.007T, 8, '<Thousands>'));
        Observer.Observe('0905 <AM/PM>', TuFormatTime(090503.007T, 0, '<AM/PM>'));
        Observer.Observe('1345 <AM/PM>', TuFormatTime(134506.078T, 0, '<AM/PM>'));
        Observer.Observe('0905 len8 <AM/PM>', TuFormatTime(090503.007T, 8, '<AM/PM>'));
        Observer.Observe('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(134506.078T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503.007T, 8, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(090503.007T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(134506.078T, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', TuFormatTime(090503.007T, 8, '<Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Observe('0905 <HOURS,2>', TuFormatTime(090503.007T, 0, '<HOURS,2>'));
        Observer.Observe('1345 <HOURS,2>', TuFormatTime(134506.078T, 0, '<HOURS,2>'));
        Observer.Observe('0905 len8 <HOURS,2>', TuFormatTime(090503.007T, 8, '<HOURS,2>'));
        Observer.Observe('midnight <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(000000T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0T <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(0T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('len5 <Hours24,2>:<Minutes,2>:<Seconds,2>', TuFormatTime(090503T, 5, '<Hours24,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('dt <Hours,2>', TuFormatDateTime(CreateDateTime(DMY2Date(5, 3, 2024), 090503T), 0, '<Hours,2>'));
        Observer.Observe('dt <Hours,2>:<Minutes,2>:<Seconds,2>', TuFormatDateTime(CreateDateTime(DMY2Date(5, 3, 2024), 090503T), 0, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('0905 <Ho>', TuFormatTime(090503.007T, 0, '<Ho>'));
        Observer.Observe('0905 <H>', TuFormatTime(090503.007T, 0, '<H>'));
        Observer.Observe('0905 <Min>', TuFormatTime(090503.007T, 0, '<Min>'));
        Observer.Observe('0905 <Sec>', TuFormatTime(090503.007T, 0, '<Sec>'));
        Observer.Observe('0905 <Thou>', TuFormatTime(090503.007T, 0, '<Thou>'));
        Observer.Observe('0905 <Hourz>', TuFormatTime(090503.007T, 0, '<Hourz>'));
        Observer.Observe('0905 <Hours24x,2>', TuFormatTime(090503.007T, 0, '<Hours24x,2>'));
        Observer.Observe('0905 <Hours 24>', TuFormatTime(090503.007T, 0, '<Hours 24>'));
        Observer.Observe('0905 <Hours,0>', TuFormatTime(090503.007T, 0, '<Hours,0>'));
        Observer.Observe('0905 <hours,2>', TuFormatTime(090503.007T, 0, '<hours,2>'));
        Observer.Observe('0905 len8 time()-like ms', TuFormatTime(090503.457T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Observe('2359 len8', TuFormatTime(235959.999T, 8, '<Hours,2>:<Minutes,2>:<Seconds,2>'));
        Observer.Expect('0905 <Hours>', '[9]');
        Observer.Expect('1345 <Hours>', '[13]');
        Observer.Expect('0905 len8 <Hours>', '[       9]');
        Observer.Expect('0905 <Hours,2>', '[ 9]');
        Observer.Expect('1345 <Hours,2>', '[13]');
        Observer.Expect('0905 len8 <Hours,2>', '[       9]');
        Observer.Expect('0905 <Hours,1>', '[9]');
        Observer.Expect('1345 <Hours,1>', '[*]');
        Observer.Expect('0905 len8 <Hours,1>', '[       9]');
        Observer.Expect('0905 <Hours,3>', '[  9]');
        Observer.Expect('1345 <Hours,3>', '[ 13]');
        Observer.Expect('0905 len8 <Hours,3>', '[       9]');
        Observer.Expect('0905 <Hours,2>:<Minutes,2>:<Seconds,2>', '[ 9:05:03]');
        Observer.Expect('1345 <Hours,2>:<Minutes,2>:<Seconds,2>', '[13:45:06]');
        Observer.Expect('0905 len8 <Hours,2>:<Minutes,2>:<Seconds,2>', '[ 9:05:03]');
        Observer.Expect('0905 <Hour>', '[9]');
        Observer.Expect('1345 <Hour>', '[13]');
        Observer.Expect('0905 len8 <Hour>', '[       9]');
        Observer.Expect('0905 <Minute>', '[5]');
        Observer.Expect('1345 <Minute>', '[45]');
        Observer.Expect('0905 len8 <Minute>', '[       5]');
        Observer.Expect('0905 <Second>', '[3]');
        Observer.Expect('1345 <Second>', '[6]');
        Observer.Expect('0905 len8 <Second>', '[       3]');
        Observer.Expect('0905 <Hours24,2>', '[ 9]');
        Observer.Expect('1345 <Hours24,2>', '[13]');
        Observer.Expect('0905 len8 <Hours24,2>', '[       9]');
        Observer.Expect('0905 <Hours12>', '[9]');
        Observer.Expect('1345 <Hours12>', '[1]');
        Observer.Expect('0905 len8 <Hours12>', '[       9]');
        Observer.Expect('0905 <Thousands>', '[7]');
        Observer.Expect('1345 <Thousands>', '[78]');
        Observer.Expect('0905 len8 <Thousands>', '[       7]');
        Observer.Expect('0905 <AM/PM>', '[AM]');
        Observer.Expect('1345 <AM/PM>', '[PM]');
        Observer.Expect('0905 len8 <AM/PM>', '[      AM]');
        Observer.Expect('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>', '[ 9:05:03]');
        Observer.Expect('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>', '[13:45:06]');
        Observer.Expect('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>', '[ 9:05:03]');
        Observer.Expect('0905 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', '[ 9:05:03.  7]');
        Observer.Expect('1345 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', '[13:45:06. 78]');
        Observer.Expect('0905 len8 <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>', '[ 9:05:03]');
        Observer.Expect('0905 <HOURS,2>', '[ 9]');
        Observer.Expect('1345 <HOURS,2>', '[13]');
        Observer.Expect('0905 len8 <HOURS,2>', '[       9]');
        Observer.Expect('midnight <Hours,2>:<Minutes,2>:<Seconds,2>', '[ 0:00:00]');
        Observer.Expect('0T <Hours,2>:<Minutes,2>:<Seconds,2>', '[ 0:00:00]');
        Observer.Expect('len5 <Hours24,2>:<Minutes,2>:<Seconds,2>', '[ 9:05]');
        Observer.Expect('dt <Hours,2>', '[09]');
        Observer.Expect('dt <Hours,2>:<Minutes,2>:<Seconds,2>', '[09:05:03]');
        Observer.Expect('0905 <Ho>', '[9]');
        Observer.Expect('0905 <H>', '[9]');
        Observer.Expect('0905 <Min>', '[5]');
        Observer.Expect('0905 <Sec>', '[3]');
        Observer.Expect('0905 <Thou>', '[7]');
        Observer.Expect('0905 <Hourz>', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Hourz> | InvalidFormatString');
        Observer.Expect('0905 <Hours24x,2>', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Hours24x,2> | InvalidFormatString');
        Observer.Expect('0905 <Hours 24>', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Hours 24> | InvalidFormatString');
        Observer.Expect('0905 <Hours,0>', '[9]');
        Observer.Expect('0905 <hours,2>', '[ 9]');
        Observer.Expect('0905 len8 time()-like ms', '[ 9:05:03]');
        Observer.Expect('2359 len8', '[23:59:59]');
        Observer.Verify();
    end;

    // Writer Y36 (gap cycle 3, C3-08): codes without a width on a DateTime (<Minutes>, <Seconds>, <Thousands>, <Hours24>, <Hours12>,
    // <Year>) and the time stamp string of Microsoft's Quality Management test library.    // BC (SaaS BC 29): no padding: <Minutes> 0, 5, 9, 10; <Seconds> 0, 5, 9; <Thousands> 0, 5, 78; <Hours24> 0 at 00:30; <Hours12> 12 at
    // 00:30; so the Quality Management stamp of 2026-03-05 09:07:02 is 260305972. <Year> gives two digits for 1998, 2005, 2031 and four
    // digits for 2099.
    [Test]
    procedure Y36_DateTime_Format_Minutes_NoWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('min_120000', FmtStr(CreateDateTime(20260305D, 120000T), '<Minutes>'));
        Observer.Observe('min_120500', FmtStr(CreateDateTime(20260305D, 120500T), '<Minutes>'));
        Observer.Observe('min_120900', FmtStr(CreateDateTime(20260305D, 120900T), '<Minutes>'));
        Observer.Observe('min_121000', FmtStr(CreateDateTime(20260305D, 121000T), '<Minutes>'));
        Observer.Observe('min_090702_123', FmtStr(CreateDateTime(20260305D, 090702.123T), '<Minutes>'));
        Observer.Observe('min_125900', FmtStr(CreateDateTime(20260305D, 125900T), '<Minutes>'));
        Observer.Expect('min_120000', '[0]');
        Observer.Expect('min_120500', '[5]');
        Observer.Expect('min_120900', '[9]');
        Observer.Expect('min_121000', '[10]');
        Observer.Expect('min_090702_123', '[7]');
        Observer.Expect('min_125900', '[59]');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_DateTime_Format_Seconds_NoWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('sec_120000', FmtStr(CreateDateTime(20260305D, 120000T), '<Seconds>'));
        Observer.Observe('sec_120005', FmtStr(CreateDateTime(20260305D, 120005T), '<Seconds>'));
        Observer.Observe('sec_120009', FmtStr(CreateDateTime(20260305D, 120009T), '<Seconds>'));
        Observer.Observe('sec_120010', FmtStr(CreateDateTime(20260305D, 120010T), '<Seconds>'));
        Observer.Observe('sec_120059', FmtStr(CreateDateTime(20260305D, 120059T), '<Seconds>'));
        Observer.Observe('sec_120005_5', FmtStr(CreateDateTime(20260305D, 120005.5T), '<Seconds>'));
        Observer.Expect('sec_120000', '[0]');
        Observer.Expect('sec_120005', '[5]');
        Observer.Expect('sec_120009', '[9]');
        Observer.Expect('sec_120010', '[10]');
        Observer.Expect('sec_120059', '[59]');
        Observer.Expect('sec_120005_5', '[5]');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_DateTime_Format_QltyStamp()
    var
        Observer: Codeunit "Probe Observer";
        Stamp: Text;
    begin
        Stamp := '<Year><Month,2><Day,2><Hours24><Minutes><Seconds>';
        Observer.Observe('q_20260305_090702', FmtStr(CreateDateTime(20260305D, 090702T), Stamp));
        Observer.Observe('q_20261231_235959', FmtStr(CreateDateTime(20261231D, 235959T), Stamp));
        Observer.Observe('q_20260101_000000', FmtStr(CreateDateTime(20260101D, 000000T), Stamp));
        Observer.Observe('q_20261031_140509', FmtStr(CreateDateTime(20261031D, 140509T), Stamp));
        Observer.Observe('q_20260305_100000', FmtStr(CreateDateTime(20260305D, 100000T), Stamp));
        Observer.Observe('q_prefix_A', FmtStr(CreateDateTime(20260305D, 090702T), 'A' + Stamp));
        Observer.Observe('q_prefix_A0SM', FmtStr(CreateDateTime(20260305D, 090702T), 'A0SM-A' + Stamp));
        Observer.Observe('q_padstr_A', PadStr(Format(CreateDateTime(20260305D, 090702T), 0, 'A' + Stamp), 19, '0'));
        Observer.Expect('q_20260305_090702', '[260305972]');
        Observer.Expect('q_20261231_235959', '[261231235959]');
        Observer.Expect('q_20260101_000000', '[260101000]');
        Observer.Expect('q_20261031_140509', '[2610311459]');
        Observer.Expect('q_20260305_100000', '[2603051000]');
        Observer.Expect('q_prefix_A', '[A260305972]');
        Observer.Expect('q_prefix_A0SM', '[A0SM-A260305972]');
        Observer.Expect('q_padstr_A', 'A260305972000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_DateTime_Format_Thousands_NoWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('ms_000', FmtStr(CreateDateTime(20260305D, 120000T), '<Thousands>'));
        Observer.Observe('ms_005', FmtStr(CreateDateTime(20260305D, 120000.005T), '<Thousands>'));
        Observer.Observe('ms_078', FmtStr(CreateDateTime(20260305D, 120000.078T), '<Thousands>'));
        Observer.Observe('ms_123', FmtStr(CreateDateTime(20260305D, 120000.123T), '<Thousands>'));
        Observer.Observe('ms_999', FmtStr(CreateDateTime(20260305D, 120000.999T), '<Thousands>'));
        Observer.Observe('z_stamp_078', FmtStr(CreateDateTime(20260305D, 090702.078T), 'Z<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'));
        Observer.Observe('z_stamp_000', FmtStr(CreateDateTime(20260305D, 090702T), 'Z<Year><Month,2><Day,2><Hours24><Minutes><Seconds><Thousands>'));
        Observer.Expect('ms_000', '[0]');
        Observer.Expect('ms_005', '[5]');
        Observer.Expect('ms_078', '[78]');
        Observer.Expect('ms_123', '[123]');
        Observer.Expect('ms_999', '[999]');
        Observer.Expect('z_stamp_078', '[Z26030597278]');
        Observer.Expect('z_stamp_000', '[Z2603059720]');
        Observer.Verify();
    end;

    [Test]
    procedure Y36_DateTime_Format_Hours_Year_NoWidth()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('h24_0030', FmtStr(CreateDateTime(20260305D, 003000T), '<Hours24>'));
        Observer.Observe('h24_0900', FmtStr(CreateDateTime(20260305D, 090000T), '<Hours24>'));
        Observer.Observe('h24_1200', FmtStr(CreateDateTime(20260305D, 120000T), '<Hours24>'));
        Observer.Observe('h24_2300', FmtStr(CreateDateTime(20260305D, 230000T), '<Hours24>'));
        Observer.Observe('h12_0030', FmtStr(CreateDateTime(20260305D, 003000T), '<Hours12>'));
        Observer.Observe('h12_0900', FmtStr(CreateDateTime(20260305D, 090000T), '<Hours12>'));
        Observer.Observe('h12_1200', FmtStr(CreateDateTime(20260305D, 120000T), '<Hours12>'));
        Observer.Observe('h12_2300', FmtStr(CreateDateTime(20260305D, 230000T), '<Hours12>'));
        Observer.Observe('ampm_0030', FmtStr(CreateDateTime(20260305D, 003000T), '<AM/PM>'));
        Observer.Observe('ampm_1200', FmtStr(CreateDateTime(20260305D, 120000T), '<AM/PM>'));
        Observer.Observe('ampm_2300', FmtStr(CreateDateTime(20260305D, 230000T), '<AM/PM>'));
        Observer.Observe('year_2031', FmtStr(CreateDateTime(20310305D, 120000T), '<Year>'));
        Observer.Observe('year_2099', FmtStr(CreateDateTime(20990305D, 120000T), '<Year>'));
        Observer.Observe('year_1998', FmtStr(CreateDateTime(19980305D, 120000T), '<Year>'));
        Observer.Observe('year_2005', FmtStr(CreateDateTime(20050305D, 120000T), '<Year>'));
        Observer.Expect('h24_0030', '[0]');
        Observer.Expect('h24_0900', '[9]');
        Observer.Expect('h24_1200', '[12]');
        Observer.Expect('h24_2300', '[23]');
        Observer.Expect('h12_0030', '[12]');
        Observer.Expect('h12_0900', '[9]');
        Observer.Expect('h12_1200', '[12]');
        Observer.Expect('h12_2300', '[11]');
        Observer.Expect('ampm_0030', '[AM]');
        Observer.Expect('ampm_1200', '[PM]');
        Observer.Expect('ampm_2300', '[PM]');
        Observer.Expect('year_2031', '[31]');
        Observer.Expect('year_2099', '[2099]');
        Observer.Expect('year_1998', '[98]');
        Observer.Expect('year_2005', '[05]');
        Observer.Verify();
    end;

    local procedure Y64Strings(): List of [Text]
    var
        L: List of [Text];
    begin
        L.Add('<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.>');
        L.Add('<Second dec.>');
        L.Add('<Second dec.,3>');
        L.Add('<Second dec.,4>');
        L.Add('<Second Dec.>');
        L.Add('<SECOND DEC.>');
        L.Add('<Second dec,1>');
        L.Add('<Second dec,2>');
        L.Add('<Second dec,4>');
        L.Add('<Second dec,5>');
        L.Add('<Seconds,2><Second dec.>');
        L.Add('<Second dec.><Filler Character,0>');
        L.Add('<Filler Character,0><Second dec,4>');
        L.Add('<Second dec..>');
        L.Add('<Second dec>.');
        exit(L);
    end;

    local procedure Y64ObserveTime(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: Time)
    var
        L: List of [Text];
        i: Integer;
    begin
        L := Y64Strings();
        for i := 1 to L.Count() do
            Observer.Observe(Prefix + Format(i), TuFormatTime(Value, 0, L.Get(i)));
    end;

    local procedure Y64ObserveDateTime(var Observer: Codeunit "Probe Observer"; Prefix: Text; Value: DateTime)
    var
        L: List of [Text];
        i: Integer;
    begin
        L := Y64Strings();
        for i := 1 to L.Count() do
            Observer.Observe(Prefix + Format(i), TuFormatDateTime(Value, 0, L.Get(i)));
    end;

    // Observation names: a prefix for the value and the index of the string in Y64Strings.
    [Test]
    procedure Y64_Time_Format_SecondDecPeriod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y64ObserveTime(Observer, 't078_', 134506.078T);
        Y64ObserveTime(Observer, 't5_', 090507.5T);
        Observer.Expect('t078_1', '[134506.078]');
        Observer.Expect('t078_2', '[.078]');
        Observer.Expect('t078_3', '[***]');
        Observer.Expect('t078_4', '[.078]');
        Observer.Expect('t078_5', '[.078]');
        Observer.Expect('t078_6', '[.078]');
        Observer.Expect('t078_7', '[*]');
        Observer.Expect('t078_8', '[**]');
        Observer.Expect('t078_9', '[.078]');
        Observer.Expect('t078_10', '[.0780]');
        Observer.Expect('t078_11', '[06.078]');
        Observer.Expect('t078_12', '[.078]');
        Observer.Expect('t078_13', '[.078]');
        Observer.Expect('t078_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('t078_15', '[.078.]');
        Observer.Expect('t5_1', '[090507.5]');
        Observer.Expect('t5_2', '[.5]');
        Observer.Expect('t5_3', '[.50]');
        Observer.Expect('t5_4', '[.500]');
        Observer.Expect('t5_5', '[.5]');
        Observer.Expect('t5_6', '[.5]');
        Observer.Expect('t5_7', '[*]');
        Observer.Expect('t5_8', '[.5]');
        Observer.Expect('t5_9', '[.500]');
        Observer.Expect('t5_10', '[.5000]');
        Observer.Expect('t5_11', '[07.5]');
        Observer.Expect('t5_12', '[.5]');
        Observer.Expect('t5_13', '[.500]');
        Observer.Expect('t5_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('t5_15', '[.5.]');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Time_Format_SecondDecPeriod_More()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y64ObserveTime(Observer, 't05_', 090507.05T);
        Y64ObserveTime(Observer, 't0_', 090507T);
        Observer.Expect('t05_1', '[090507.05]');
        Observer.Expect('t05_2', '[.05]');
        Observer.Expect('t05_3', '[.05]');
        Observer.Expect('t05_4', '[.050]');
        Observer.Expect('t05_5', '[.05]');
        Observer.Expect('t05_6', '[.05]');
        Observer.Expect('t05_7', '[*]');
        Observer.Expect('t05_8', '[**]');
        Observer.Expect('t05_9', '[.050]');
        Observer.Expect('t05_10', '[.0500]');
        Observer.Expect('t05_11', '[07.05]');
        Observer.Expect('t05_12', '[.05]');
        Observer.Expect('t05_13', '[.050]');
        Observer.Expect('t05_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('t05_15', '[.05.]');
        Observer.Expect('t0_1', '[090507]');
        Observer.Expect('t0_2', '[]');
        Observer.Expect('t0_3', '[000]');
        Observer.Expect('t0_4', '[0000]');
        Observer.Expect('t0_5', '[]');
        Observer.Expect('t0_6', '[]');
        Observer.Expect('t0_7', '[0]');
        Observer.Expect('t0_8', '[00]');
        Observer.Expect('t0_9', '[0000]');
        Observer.Expect('t0_10', '[00000]');
        Observer.Expect('t0_11', '[07]');
        Observer.Expect('t0_12', '[]');
        Observer.Expect('t0_13', '[0000]');
        Observer.Expect('t0_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('t0_15', '[.]');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Time_Format_SecondDecPeriod_Edges()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y64ObserveTime(Observer, 't999_', 235959.999T);
        Y64ObserveTime(Observer, '0T_', 0T);
        Observer.Expect('t999_1', '[235959.999]');
        Observer.Expect('t999_2', '[.999]');
        Observer.Expect('t999_3', '[***]');
        Observer.Expect('t999_4', '[.999]');
        Observer.Expect('t999_5', '[.999]');
        Observer.Expect('t999_6', '[.999]');
        Observer.Expect('t999_7', '[*]');
        Observer.Expect('t999_8', '[**]');
        Observer.Expect('t999_9', '[.999]');
        Observer.Expect('t999_10', '[.9990]');
        Observer.Expect('t999_11', '[59.999]');
        Observer.Expect('t999_12', '[.999]');
        Observer.Expect('t999_13', '[.999]');
        Observer.Expect('t999_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('t999_15', '[.999.]');
        Observer.Expect('0T_1', '[000000]');
        Observer.Expect('0T_2', '[]');
        Observer.Expect('0T_3', '[000]');
        Observer.Expect('0T_4', '[0000]');
        Observer.Expect('0T_5', '[]');
        Observer.Expect('0T_6', '[]');
        Observer.Expect('0T_7', '[0]');
        Observer.Expect('0T_8', '[00]');
        Observer.Expect('0T_9', '[0000]');
        Observer.Expect('0T_10', '[00000]');
        Observer.Expect('0T_11', '[00]');
        Observer.Expect('0T_12', '[]');
        Observer.Expect('0T_13', '[0000]');
        Observer.Expect('0T_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('0T_15', '[.]');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_DateTime_Format_SecondDecPeriod()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Y64ObserveDateTime(Observer, 'dt078_', CreateDateTime(20240305D, 134506.078T));
        Y64ObserveDateTime(Observer, 'dt0_', CreateDateTime(20240305D, 090507T));
        Observer.Expect('dt078_1', '[134506.078]');
        Observer.Expect('dt078_2', '[.078]');
        Observer.Expect('dt078_3', '[***]');
        Observer.Expect('dt078_4', '[.078]');
        Observer.Expect('dt078_5', '[.078]');
        Observer.Expect('dt078_6', '[.078]');
        Observer.Expect('dt078_7', '[*]');
        Observer.Expect('dt078_8', '[**]');
        Observer.Expect('dt078_9', '[.078]');
        Observer.Expect('dt078_10', '[.0780]');
        Observer.Expect('dt078_11', '[06.078]');
        Observer.Expect('dt078_12', '[.078]');
        Observer.Expect('dt078_13', '[.078]');
        Observer.Expect('dt078_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('dt078_15', '[.078.]');
        Observer.Expect('dt0_1', '[090507]');
        Observer.Expect('dt0_2', '[]');
        Observer.Expect('dt0_3', '[.00]');
        Observer.Expect('dt0_4', '[.000]');
        Observer.Expect('dt0_5', '[]');
        Observer.Expect('dt0_6', '[]');
        Observer.Expect('dt0_7', '[.]');
        Observer.Expect('dt0_8', '[.0]');
        Observer.Expect('dt0_9', '[.000]');
        Observer.Expect('dt0_10', '[.0000]');
        Observer.Expect('dt0_11', '[07]');
        Observer.Expect('dt0_12', '[]');
        Observer.Expect('dt0_13', '[.000]');
        Observer.Expect('dt0_14', 'error: An invalid field or attribute has been specified for the ''Format'' property.\\<Second dec..> | InvalidFormatString');
        Observer.Expect('dt0_15', '[.]');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_SecondDecPeriod_ReporterCode()
    var
        Observer: Codeunit "Probe Observer";
        CurrTime: Text;
    begin
        CurrTime := Format(134506.078T, 0, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.>');
        Observer.Observe('code', 'X-' + DelChr(CurrTime, '=', '.,:'));
        CurrTime := Format(090507T, 0, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.>');
        Observer.Observe('code no ms', 'X-' + DelChr(CurrTime, '=', '.,:'));
        Observer.Observe('length 10', TuFormatTime(134506.078T, 10, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.>'));
        Observer.Observe('length 4', TuFormatTime(134506.078T, 4, '<Hours24,2><Filler Character,0><Minutes,2><Seconds,2><Second dec.>'));
        Observer.Observe('length -12', TuFormatTime(134506.078T, -12, '<Second dec.>'));
        Observer.Expect('code', 'X-134506078');
        Observer.Expect('code no ms', 'X-090507');
        Observer.Expect('length 10', '[134506.078]');
        Observer.Expect('length 4', '[1345]');
        Observer.Expect('length -12', '[.078]');
        Observer.Verify();
    end;
}
