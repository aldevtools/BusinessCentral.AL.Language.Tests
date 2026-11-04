// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/time/time-hour-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Time.Hour, Time.Minute, Time.Second, Time.Millisecond and Time.ToText([Boolean]) on fixed times (no clock reads). Settles #626 items 1 to 5.
// BC versions: 27, 28, 29

codeunit 77500 "LT AC Time Parts"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_TimeHour()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456.789T;
        Observer.Observe('fixed', Format(T.Hour()));
        T := 000000T;
        Observer.Observe('midnight', Format(T.Hour()));
        T := 235959.999T;
        Observer.Observe('last_ms', Format(T.Hour()));
        T := 010000T;
        Observer.Observe('one_am', Format(T.Hour()));
        T := 120000T;
        Observer.Observe('noon', Format(T.Hour()));
        T := 235959T;
        Observer.Observe('max_second', Format(T.Hour()));
        Observer.Expect('fixed', '12');
        Observer.Expect('midnight', '0');
        Observer.Expect('last_ms', '23');
        Observer.Expect('one_am', '1');
        Observer.Expect('noon', '12');
        Observer.Expect('max_second', '23');
        Observer.Verify();
    end;

    [Test]
    procedure AC_TimeMinute()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456.789T;
        Observer.Observe('fixed', Format(T.Minute()));
        T := 000000T;
        Observer.Observe('midnight', Format(T.Minute()));
        T := 235959.999T;
        Observer.Observe('last_ms', Format(T.Minute()));
        T := 120100T;
        Observer.Observe('one', Format(T.Minute()));
        T := 125900T;
        Observer.Observe('fifty_nine', Format(T.Minute()));
        Observer.Expect('fixed', '34');
        Observer.Expect('midnight', '0');
        Observer.Expect('last_ms', '59');
        Observer.Expect('one', '1');
        Observer.Expect('fifty_nine', '59');
        Observer.Verify();
    end;

    [Test]
    procedure AC_TimeSecond()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456.789T;
        Observer.Observe('fixed', Format(T.Second()));
        T := 000000T;
        Observer.Observe('midnight', Format(T.Second()));
        T := 235959.999T;
        Observer.Observe('last_ms', Format(T.Second()));
        T := 120001T;
        Observer.Observe('one', Format(T.Second()));
        T := 120059.500T;
        Observer.Observe('half_ms', Format(T.Second()));
        Observer.Expect('fixed', '56');
        Observer.Expect('midnight', '0');
        Observer.Expect('last_ms', '59');
        Observer.Expect('one', '1');
        Observer.Expect('half_ms', '59');
        Observer.Verify();
    end;

    [Test]
    procedure AC_TimeMillisecond()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456.789T;
        Observer.Observe('fixed', Format(T.Millisecond()));
        T := 000000T;
        Observer.Observe('midnight', Format(T.Millisecond()));
        T := 235959.999T;
        Observer.Observe('last_ms', Format(T.Millisecond()));
        T := 120000.001T;
        Observer.Observe('one', Format(T.Millisecond()));
        T := 120000.010T;
        Observer.Observe('ten', Format(T.Millisecond()));
        T := 120000.100T;
        Observer.Observe('hundred', Format(T.Millisecond()));
        T := 235959T;
        Observer.Observe('no_ms', Format(T.Millisecond()));
        Observer.Expect('fixed', '789');
        Observer.Expect('midnight', '0');
        Observer.Expect('last_ms', '999');
        Observer.Expect('one', '1');
        Observer.Expect('ten', '10');
        Observer.Expect('hundred', '100');
        Observer.Expect('no_ms', '0');
        Observer.Verify();
    end;

    [Test]
    procedure AC_TimeToText()
    var
        Observer: Codeunit "Probe Observer";
        T: Time;
    begin
        T := 123456.789T;
        Observer.Observe('ms_default', T.ToText());
        Observer.Observe('ms_false', T.ToText(false));
        Observer.Observe('ms_true', T.ToText(true));
        Observer.Observe('ms_format_0_0', Format(T, 0, 0));
        Observer.Observe('ms_format_0_9', Format(T, 0, 9));
        T := 000000T;
        Observer.Observe('midnight_default', T.ToText());
        Observer.Observe('midnight_true', T.ToText(true));
        T := 235959.999T;
        Observer.Observe('last_default', T.ToText());
        Observer.Observe('last_true', T.ToText(true));
        T := 090500T;
        Observer.Observe('morning_default', T.ToText());
        Observer.Observe('morning_true', T.ToText(true));
        T := 150000T;
        Observer.Observe('afternoon_default', T.ToText());
        Observer.Observe('afternoon_true', T.ToText(true));
        Observer.Expect('ms_default', '12:34:56 PM');
        Observer.Expect('ms_false', '12:34:56 PM');
        Observer.Expect('ms_true', '12:34:56.789');
        Observer.Expect('ms_format_0_0', '12:34:56 PM');
        Observer.Expect('ms_format_0_9', '12:34:56.789');
        Observer.Expect('midnight_default', '12:00:00 AM');
        Observer.Expect('midnight_true', '00:00:00');
        Observer.Expect('last_default', '11:59:59 PM');
        Observer.Expect('last_true', '23:59:59.999');
        Observer.Expect('morning_default', ' 9:05:00 AM');
        Observer.Expect('morning_true', '09:05:00');
        Observer.Expect('afternoon_default', ' 3:00:00 PM');
        Observer.Expect('afternoon_true', '15:00:00');
        Observer.Verify();
    end;
}
