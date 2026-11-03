// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (P93); the lead measures the facts on a local BC 29 and turns them into assertions.
// Facts: DateTime.Date, Time, ToText for 0DT and a value with milliseconds, Time.ToText and Duration.ToText
// BC versions: 29 (27 and 28 by CI)

codeunit 70321 "LT P93 DateTime"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryDT(Dt: DateTime; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := Format(Dt.Date());
            1:
                R := Format(Dt.Time());
            2:
                R := Dt.ToText();
            3:
                R := Dt.ToText(true);
            4:
                R := Dt.ToText(false);
            5:
                R := Format(Dt.Date(), 0, 9);
            6:
                R := Format(Dt.Time(), 0, 9);
        end;
    end;

    [TryFunction]
    local procedure TryTime(T: Time; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := T.ToText();
            1:
                R := T.ToText(true);
            2:
                R := T.ToText(false);
        end;
    end;

    [TryFunction]
    local procedure TryDur(D: Duration; Mode: Integer; var R: Text)
    begin
        case Mode of
            0:
                R := D.ToText();
            1:
                R := D.ToText(true);
            2:
                R := D.ToText(false);
        end;
    end;

    local procedure DT(V: DateTime; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryDT(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure TM(V: Time; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryTime(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure DU(V: Duration; Mode: Integer): Text
    var
        R: Text;
    begin
        if TryDur(V, Mode, R) then
            exit(R);
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure DateTime_Zero()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        Observer.Observe('date', DT(V, 0));
        Observer.Observe('time', DT(V, 1));
        Observer.Observe('tt', DT(V, 2));
        Observer.Observe('tt-true', DT(V, 3));
        Observer.Observe('tt-false', DT(V, 4));
        Observer.Observe('date-9', DT(V, 5));
        Observer.Observe('time-9', DT(V, 6));
        Observer.Observe('format', Format(V));
        Observer.Observe('format-9', Format(V, 0, 9));
        Observer.Observe('lit-date', DT(0DT, 0));
        Observer.Observe('lit-time', DT(0DT, 1));
        Observer.Observe('lit-tt', DT(0DT, 2));
        Observer.Expect('date', '');
        Observer.Expect('time', '');
        Observer.Expect('tt', '');
        Observer.Expect('tt-true', '');
        Observer.Expect('tt-false', '');
        Observer.Expect('date-9', '');
        Observer.Expect('time-9', '');
        Observer.Expect('format', '');
        Observer.Expect('format-9', '');
        Observer.Expect('lit-date', '');
        Observer.Expect('lit-time', '');
        Observer.Expect('lit-tt', '');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_Millis()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
    begin
        V := CreateDateTime(20240315D, 123456T) + 789;
        Observer.Observe('date', DT(V, 0));
        Observer.Observe('time', DT(V, 1));
        Observer.Observe('tt', DT(V, 2));
        Observer.Observe('tt-true', DT(V, 3));
        Observer.Observe('tt-false', DT(V, 4));
        Observer.Observe('date-9', DT(V, 5));
        Observer.Observe('time-9', DT(V, 6));
        Observer.Observe('format', Format(V));
        Observer.Observe('format-9', Format(V, 0, 9));
        Observer.Observe('format-0', Format(V, 0, 0));
        Observer.Observe('format-1', Format(V, 0, 1));
        Observer.Observe('format-custom', Format(V, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>.<Thousands,3>'));
        Observer.Expect('date', '03/15/24');
        Observer.Expect('time', '12:34:56 PM');
        Observer.Expect('tt', '03/15/24 12:34 PM');
        Observer.Expect('tt-true', '2024-03-15T12:34:56.789Z');
        Observer.Expect('tt-false', '03/15/24 12:34 PM');
        Observer.Expect('date-9', '2024-03-15');
        Observer.Expect('time-9', '12:34:56.789');
        Observer.Expect('format', '03/15/24 12:34 PM');
        Observer.Expect('format-9', '2024-03-15T12:34:56.789Z');
        Observer.Expect('format-0', '03/15/24 12:34 PM');
        Observer.Expect('format-1', '03/15/24 12:34:56.789 PM');
        Observer.Expect('format-custom', '2024-03-15 12:34:56.789');
        Observer.Verify();
    end;

    [Test]
    procedure DateTime_NoMillis_AndClosing()
    var
        Observer: Codeunit "Probe Observer";
        V: DateTime;
        W: DateTime;
    begin
        V := CreateDateTime(20240229D, 120000T);
        W := CreateDateTime(20231231D, 120000T);
        Observer.Observe('feb29-date', DT(V, 0));
        Observer.Observe('feb29-time', DT(V, 1));
        Observer.Observe('feb29-tt', DT(V, 2));
        Observer.Observe('feb29-tt-true', DT(V, 3));
        Observer.Observe('feb29-format-9', Format(V, 0, 9));
        Observer.Observe('dec31-date', DT(W, 0));
        Observer.Observe('dec31-time', DT(W, 1));
        Observer.Observe('dec31-tt', DT(W, 2));
        Observer.Observe('dec31-tt-true', DT(W, 3));
        Observer.Observe('dec31-format-9', Format(W, 0, 9));
        Observer.Observe('closing-date', DT(CreateDateTime(ClosingDate(20231231D), 120000T), 0));
        Observer.Observe('dateonly', DT(CreateDateTime(20240315D, 0T), 1));
        asserterror Observer.Observe('timeonly', DT(CreateDateTime(0D, 123456T), 0));
        Observer.ObserveError('af151');
        Observer.Expect('feb29-date', '02/29/24');
        Observer.Expect('feb29-time', '12:00:00 PM');
        Observer.Expect('feb29-tt', '02/29/24 12:00 PM');
        Observer.Expect('feb29-tt-true', '2024-02-29T12:00:00Z');
        Observer.Expect('feb29-format-9', '2024-02-29T12:00:00Z');
        Observer.Expect('dec31-date', '12/31/23');
        Observer.Expect('dec31-time', '12:00:00 PM');
        Observer.Expect('dec31-tt', '12/31/23 12:00 PM');
        Observer.Expect('dec31-tt-true', '2023-12-31T12:00:00Z');
        Observer.Expect('dec31-format-9', '2023-12-31T12:00:00Z');
        Observer.Expect('closing-date', '01/01/24');
        Observer.Expect('dateonly', '12:00:00 AM');
        Observer.Expect('af151|text', 'The date is not valid.');
        Observer.Expect('af151|code', 'DateInvalid');
        Observer.Verify();
    end;

    [Test]
    procedure Time_ToText()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        Observer.Observe('zero', TM(T, 0));
        Observer.Observe('zero-true', TM(T, 1));
        Observer.Observe('zero-false', TM(T, 2));
        Observer.Observe('zero-format', Format(T));
        Observer.Observe('zero-format-9', Format(T, 0, 9));
        T := 123456T;
        Observer.Observe('t', TM(T, 0));
        Observer.Observe('t-true', TM(T, 1));
        Observer.Observe('t-false', TM(T, 2));
        Observer.Observe('t-format', Format(T));
        Observer.Observe('t-format-9', Format(T, 0, 9));
        T := 235959T;
        Observer.Observe('late', TM(T, 0));
        Observer.Observe('late-true', TM(T, 1));
        T := 000000T + 123;
        Observer.Observe('ms', TM(T, 0));
        Observer.Observe('ms-true', TM(T, 1));
        Observer.Observe('ms-format', Format(T));
        Observer.Observe('ms-format-9', Format(T, 0, 9));
        T := 120000T;
        Observer.Observe('noon', TM(T, 0));
        Observer.Observe('noon-true', TM(T, 1));
        Observer.Expect('zero', '');
        Observer.Expect('zero-true', '');
        Observer.Expect('zero-false', '');
        Observer.Expect('zero-format', '');
        Observer.Expect('zero-format-9', '');
        Observer.Expect('t', '12:34:56 PM');
        Observer.Expect('t-true', '12:34:56');
        Observer.Expect('t-false', '12:34:56 PM');
        Observer.Expect('t-format', '12:34:56 PM');
        Observer.Expect('t-format-9', '12:34:56');
        Observer.Expect('late', '11:59:59 PM');
        Observer.Expect('late-true', '23:59:59');
        Observer.Expect('ms', '12:00:00 AM');
        Observer.Expect('ms-true', '00:00:00.123');
        Observer.Expect('ms-format', '12:00:00 AM');
        Observer.Expect('ms-format-9', '00:00:00.123');
        Observer.Expect('noon', '12:00:00 PM');
        Observer.Expect('noon-true', '12:00:00');
        Observer.Verify();
    end;

    [Test]
    procedure Duration_ToText()
    var
        Observer: Codeunit "Probe Observer";
        D: Duration;
    begin
        Observer.Observe('zero', DU(D, 0));
        Observer.Observe('zero-true', DU(D, 1));
        Observer.Observe('zero-false', DU(D, 2));
        Observer.Observe('zero-format', Format(D));
        D := 1000;
        Observer.Observe('1s', DU(D, 0));
        Observer.Observe('1s-true', DU(D, 1));
        Observer.Observe('1s-format', Format(D));
        Observer.Observe('1s-format-9', Format(D, 0, 9));
        D := 3661000;
        Observer.Observe('1h1m1s', DU(D, 0));
        Observer.Observe('1h1m1s-true', DU(D, 1));
        Observer.Observe('1h1m1s-format-9', Format(D, 0, 9));
        D := 172800000;
        Observer.Observe('2d', DU(D, 0));
        Observer.Observe('2d-true', DU(D, 1));
        Observer.Observe('2d-format-9', Format(D, 0, 9));
        D := -5000;
        Observer.Observe('neg', DU(D, 0));
        Observer.Observe('neg-true', DU(D, 1));
        Observer.Observe('neg-format-9', Format(D, 0, 9));
        D := 1;
        Observer.Observe('1ms', DU(D, 0));
        Observer.Observe('1ms-true', DU(D, 1));
        Observer.Expect('zero', '');
        Observer.Expect('zero-true', 'P0DT0H0M0.0S');
        Observer.Expect('zero-false', '');
        Observer.Expect('zero-format', '');
        Observer.Expect('1s', '1 second');
        Observer.Expect('1s-true', 'P0DT0H0M1.0S');
        Observer.Expect('1s-format', '1 second');
        Observer.Expect('1s-format-9', 'P0DT0H0M1.0S');
        Observer.Expect('1h1m1s', '1 hour 1 minute 1 second');
        Observer.Expect('1h1m1s-true', 'P0DT1H1M1.0S');
        Observer.Expect('1h1m1s-format-9', 'P0DT1H1M1.0S');
        Observer.Expect('2d', '2 days');
        Observer.Expect('2d-true', 'P2DT0H0M0.0S');
        Observer.Expect('2d-format-9', 'P2DT0H0M0.0S');
        Observer.Expect('neg', '-5 seconds');
        Observer.Expect('neg-true', '-P0DT0H0M5.0S');
        Observer.Expect('neg-format-9', '-P0DT0H0M5.0S');
        Observer.Expect('1ms', '1 millisecond');
        Observer.Expect('1ms-true', 'P0DT0H0M0.001S');
        Observer.Verify();
    end;
}
