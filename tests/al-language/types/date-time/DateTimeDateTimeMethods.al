// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datetime/datetime-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160); test codeunit 73578
// Probe: written against BC on CI (no local container); every literal asserted below is what the CI tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: the instance methods DateTime.Date() and DateTime.Time() next to the functions DT2Date(Dt) and DT2Time(Dt), for a DateTime with date and time,
//   a DateTime at midnight, the undefined DateTime (0DT), a DateTime made from 0D and a time, and one made from a date and 0T.
// BC versions: 27, 28, 29 by CI

codeunit 73578 "LT DateTime Date Time Methods"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Obs: Codeunit "Probe Observer";

    local procedure Show(Name: Text; Dt: DateTime)
    begin
        Obs.Observe(Name + '.dt', Format(Dt, 0, 9));
        Obs.Observe(Name + '.date_method', Format(Dt.Date(), 0, 9));
        Obs.Observe(Name + '.date_fn', Format(DT2Date(Dt), 0, 9));
        Obs.Observe(Name + '.time_method', Format(Dt.Time(), 0, 9));
        Obs.Observe(Name + '.time_fn', Format(DT2Time(Dt), 0, 9));
    end;

    [Test]
    procedure DateTime_DateAndTimeMethods_SetValue()
    begin
        Show('set', CreateDateTime(DMY2Date(15, 6, 2026), 143025.123T));
        Show('midnight', CreateDateTime(DMY2Date(15, 6, 2026), 0T));
        Show('endday', CreateDateTime(DMY2Date(31, 12, 2026), 235959.999T));
        Obs.Expect('set.dt', '2026-06-15T14:30:25.123Z');
        Obs.Expect('set.date_method', '2026-06-15');
        Obs.Expect('set.date_fn', '2026-06-15');
        Obs.Expect('set.time_method', '14:30:25.123');
        Obs.Expect('set.time_fn', '14:30:25.123');
        Obs.Expect('midnight.dt', '2026-06-15T00:00:00Z');
        Obs.Expect('midnight.date_method', '2026-06-15');
        Obs.Expect('midnight.date_fn', '2026-06-15');
        Obs.Expect('midnight.time_method', '00:00:00');
        Obs.Expect('midnight.time_fn', '00:00:00');
        Obs.Expect('endday.dt', '2026-12-31T23:59:59.999Z');
        Obs.Expect('endday.date_method', '2026-12-31');
        Obs.Expect('endday.date_fn', '2026-12-31');
        Obs.Expect('endday.time_method', '23:59:59.999');
        Obs.Expect('endday.time_fn', '23:59:59.999');
        Obs.Verify();
    end;

    [Test]
    procedure DateTime_DateAndTimeMethods_Undefined()
    var
        Dt: DateTime;
    begin
        Show('zero', 0DT);
        Show('var', Dt);
        Obs.Observe('date_is_zero', Format(Dt.Date() = 0D));
        Obs.Observe('time_is_zero', Format(Dt.Time() = 0T));
        Obs.Expect('zero.dt', '');
        Obs.Expect('zero.date_method', '');
        Obs.Expect('zero.date_fn', '');
        Obs.Expect('zero.time_method', '');
        Obs.Expect('zero.time_fn', '');
        Obs.Expect('var.dt', '');
        Obs.Expect('var.date_method', '');
        Obs.Expect('var.date_fn', '');
        Obs.Expect('var.time_method', '');
        Obs.Expect('var.time_fn', '');
        Obs.Expect('date_is_zero', 'Yes');
        Obs.Expect('time_is_zero', 'Yes');
        Obs.Verify();
    end;

    [TryFunction]
    local procedure TryDate0Time(var Dt: DateTime)
    begin
        Dt := CreateDateTime(0D, 120000T);
    end;

    [Test]
    procedure DateTime_DateAndTimeMethods_DateZeroWithTime()
    var
        Dt: DateTime;
    begin
        if TryDate0Time(Dt) then
            Show('date0', Dt)
        else begin
            Obs.Observe('date0', GetLastErrorText());
            ClearLastError();
        end;
        Obs.Expect('date0', 'The date is not valid.');
        Obs.Verify();
    end;
}
