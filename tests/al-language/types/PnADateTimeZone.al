// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-createdatetime-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md row: Dates: The session time zone is UTC for CreateDateTime, DT2Date, DT2Time and the date codes of Format(DateTime, 0, <...>)
// Facts: CreateDateTime, DT2Date, DT2Time and Format(DateTime, 0, custom codes) near midnight and at the extremes: whether any zone shift applies
// BC versions: 29 (27 and 28 by CI)

codeunit 70120 "LT PnA DateTime Zone"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Show(var Observer: Codeunit "Probe Observer"; Name: Text; D: Date; T: Time)
    var
        Dt: DateTime;
    begin
        Dt := CreateDateTime(D, T);
        Observer.Observe(Name,
          Format(DT2Date(Dt) = D) + '|' + Format(DT2Time(Dt) = T) + '|' +
          Format(Dt, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>') + '|' + Format(Dt, 0, 9));
    end;

    [Test]
    procedure RoundTrip_AndFormatCodes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Show(Observer, 'midnight', DMY2Date(1, 1, 2024), 000000T);
        Show(Observer, 'one-second-past-midnight', DMY2Date(1, 1, 2024), 000001T);
        Show(Observer, 'one-second-before-midnight', DMY2Date(31, 12, 2023), 235959T);
        Show(Observer, 'noon', DMY2Date(15, 6, 2024), 120000T);
        Show(Observer, 'summer-late', DMY2Date(30, 6, 2024), 233000T);
        Show(Observer, 'summer-early', DMY2Date(1, 7, 2024), 003000T);
        Show(Observer, 'winter-late', DMY2Date(31, 1, 2024), 233000T);
        Show(Observer, 'winter-early', DMY2Date(1, 2, 2024), 003000T);
        Show(Observer, 'leap-day', DMY2Date(29, 2, 2024), 235959T);
        Show(Observer, 'first-date', DMY2Date(1, 1, 1753), 000000T);
        Show(Observer, 'last-date', DMY2Date(31, 12, 9999), 235959T);
        Show(Observer, 'dst-spring-gap-us', DMY2Date(10, 3, 2024), 023000T);
        Show(Observer, 'dst-spring-gap-eu', DMY2Date(31, 3, 2024), 023000T);
        Show(Observer, 'dst-autumn-overlap-eu', DMY2Date(27, 10, 2024), 023000T);
        Observer.Expect('midnight', 'Yes|Yes|2024-01-01 00:00:00|2024-01-01T00:00:00Z');
        Observer.Expect('one-second-past-midnight', 'Yes|Yes|2024-01-01 00:00:01|2024-01-01T00:00:01Z');
        Observer.Expect('one-second-before-midnight', 'Yes|Yes|2023-12-31 23:59:59|2023-12-31T23:59:59Z');
        Observer.Expect('noon', 'Yes|Yes|2024-06-15 12:00:00|2024-06-15T12:00:00Z');
        Observer.Expect('summer-late', 'Yes|Yes|2024-06-30 23:30:00|2024-06-30T23:30:00Z');
        Observer.Expect('summer-early', 'Yes|Yes|2024-07-01 00:30:00|2024-07-01T00:30:00Z');
        Observer.Expect('winter-late', 'Yes|Yes|2024-01-31 23:30:00|2024-01-31T23:30:00Z');
        Observer.Expect('winter-early', 'Yes|Yes|2024-02-01 00:30:00|2024-02-01T00:30:00Z');
        Observer.Expect('leap-day', 'Yes|Yes|2024-02-29 23:59:59|2024-02-29T23:59:59Z');
        Observer.Expect('first-date', 'Yes|Yes|1753-01-01 00:00:00|1753-01-01T00:00:00Z');
        Observer.Expect('last-date', 'Yes|Yes|9999-12-31 23:59:59|9999-12-31T23:59:59Z');
        Observer.Expect('dst-spring-gap-us', 'Yes|Yes|2024-03-10 02:30:00|2024-03-10T02:30:00Z');
        Observer.Expect('dst-spring-gap-eu', 'Yes|Yes|2024-03-31 02:30:00|2024-03-31T02:30:00Z');
        Observer.Expect('dst-autumn-overlap-eu', 'Yes|Yes|2024-10-27 02:30:00|2024-10-27T02:30:00Z');
        Observer.Verify();
    end;

    [Test]
    procedure Undefined_AndDateOnly()
    var
        Observer: Codeunit "Probe Observer";
        Dt: DateTime;
    begin
        Dt := CreateDateTime(0D, 0T);
        Observer.Observe('undefined-date', Format(DT2Date(Dt)));
        Observer.Observe('undefined-time', Format(DT2Time(Dt)));
        Dt := CreateDateTime(DMY2Date(1, 1, 2024), 0T);
        Observer.Observe('date-only-date', Format(DT2Date(Dt) = DMY2Date(1, 1, 2024)));
        Observer.Observe('date-only-time', Format(DT2Time(Dt)));
        asserterror Dt := CreateDateTime(0D, 120000T);
        Observer.ObserveError('af58');
        Observer.Observe('time-only-date', Format(DT2Date(Dt)));
        Observer.Observe('time-only-time', Format(DT2Time(Dt)));
        Observer.Observe('time-only-format', Format(Dt, 0, 9));
        Dt := CreateDateTime(DMY2Date(1, 1, 2024), 000000T);
        Observer.Observe('add-one-day', Format(DT2Date(Dt + 86400000) = DMY2Date(2, 1, 2024)));
        Observer.Observe('subtract-one-ms', Format(DT2Date(Dt - 1) = DMY2Date(31, 12, 2023)));
        Observer.Observe('subtract-one-ms-time', Format(Format(DT2Time(Dt - 1), 0, 9)));
        Observer.Expect('undefined-date', '');
        Observer.Expect('undefined-time', '');
        Observer.Expect('date-only-date', 'Yes');
        Observer.Expect('date-only-time', '12:00:00 AM');
        Observer.Expect('af58|text', 'The date is not valid.');
        Observer.Expect('af58|code', 'DateInvalid');
        Observer.Expect('time-only-date', '01/01/24');
        Observer.Expect('time-only-time', '12:00:00 AM');
        Observer.Expect('time-only-format', '2024-01-01T00:00:00Z');
        Observer.Expect('add-one-day', 'Yes');
        Observer.Expect('subtract-one-ms', 'Yes');
        Observer.Expect('subtract-one-ms-time', '23:59:59.999');
        Observer.Verify();
    end;
}
