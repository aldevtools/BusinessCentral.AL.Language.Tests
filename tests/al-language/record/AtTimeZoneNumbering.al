// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own codeunit 80007
// Probe: the "Time Zone" virtual table (2000000164) lists the time zones of the HOST operating system, so "No." and ID depend on the machine.
// The shape (1..N, no gaps, non-blank IDs) is pinned host-independently in record/TestTimeZoneVirtualTable.al.
// Facts asked: the No. of the row with ID 'W. Europe Standard Time', the row count, the first and last ID.
// Asserted with the Windows values (corpus #683): BC 27.5 and 28.5 (Windows check 2026-10-20) and 27.5 and 29.0 (Windows check 3) all give
// 144 rows, 'W. Europe Standard Time' = No. 55, no 'Europe/Berlin', 1=Dateline Standard Time, 2=UTC-11, 3=Aleutian Standard Time,
// 144=Line Islands Standard Time. Before the bc-linux #132 fix the Linux image listed the IANA ids (BC 29.0,
// 2026-10-19: count 419; no 'W. Europe Standard Time'; 'Europe/Berlin' is No. 195; 1=Pacific/Niue, 2=Pacific/Midway, 3=Pacific/Pago_Pago;
// 419=Pacific/Kiritimati). The ci.yml pin includes that fix, so the values are asserted on Linux too.
// BC versions: 27, 28, 29

codeunit 80007 "LT AT Time Zone Numbering"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AT_TimeZone_Numbering_Probe()
    var
        Observer: Codeunit "Probe Observer";
        TimeZone: Record "Time Zone";
    begin
        Observer.Observe('count', Format(TimeZone.Count()));
        TimeZone.SetRange(ID, 'W. Europe Standard Time');
        if TimeZone.FindFirst() then
            Observer.Observe('W. Europe No.', Format(TimeZone."No."))
        else
            Observer.Observe('W. Europe No.', 'absent');
        TimeZone.SetRange(ID, 'Europe/Berlin');
        if TimeZone.FindFirst() then
            Observer.Observe('Europe/Berlin No.', Format(TimeZone."No."))
        else
            Observer.Observe('Europe/Berlin No.', 'absent');
        TimeZone.SetRange(ID);
        TimeZone.FindFirst();
        Observer.Observe('first', Format(TimeZone."No.") + '=' + TimeZone.ID);
        TimeZone.FindLast();
        Observer.Observe('last', Format(TimeZone."No.") + '=' + TimeZone.ID);
        TimeZone.Get(2);
        Observer.Observe('2', TimeZone.ID);
        TimeZone.Get(3);
        Observer.Observe('3', TimeZone.ID);
        Observer.Expect('count', '144');
        Observer.Expect('W. Europe No.', '55');
        Observer.Expect('Europe/Berlin No.', 'absent');
        Observer.Expect('first', '1=Dateline Standard Time');
        Observer.Expect('last', '144=Line Islands Standard Time');
        Observer.Expect('2', 'UTC-11');
        Observer.Expect('3', 'Aleutian Standard Time');
        Observer.Verify();
    end;

    // UQ (al-runner 6218): lookups by ID of several Windows zones, an unknown id, and the row count under an ID filter.
    [Test]
    procedure UQ_TimeZone_LookupById()
    var
        Observer: Codeunit "Probe Observer";
        TimeZone: Record "Time Zone";
    begin
        Observer.Observe('Pacific', ById('Pacific Standard Time'));
        Observer.Observe('UTC', ById('UTC'));
        Observer.Observe('Arabian', ById('Arabian Standard Time'));
        Observer.Observe('GMT', ById('GMT Standard Time'));
        Observer.Observe('Eastern', ById('Eastern Standard Time'));
        Observer.Observe('Tokyo', ById('Tokyo Standard Time'));
        Observer.Observe('Unknown', ById('No Such Standard Time'));
        TimeZone.SetRange(ID, 'Arabian Standard Time');
        Observer.Observe('Arabian IsEmpty', Format(TimeZone.IsEmpty()));
        TimeZone.SetRange(ID, 'No Such Standard Time');
        Observer.Observe('Unknown IsEmpty', Format(TimeZone.IsEmpty()));
        Observer.Expect('Pacific', 'present, ID Pacific Standard Time, count 1');
        Observer.Expect('UTC', 'present, ID UTC, count 1');
        Observer.Expect('Arabian', 'present, ID Arabian Standard Time, count 1');
        Observer.Expect('GMT', 'present, ID GMT Standard Time, count 1');
        Observer.Expect('Eastern', 'present, ID Eastern Standard Time, count 1');
        Observer.Expect('Tokyo', 'present, ID Tokyo Standard Time, count 1');
        Observer.Expect('Unknown', 'absent');
        Observer.Expect('Arabian IsEmpty', 'No');
        Observer.Expect('Unknown IsEmpty', 'Yes');
        Observer.Verify();
    end;

    local procedure ById(ZoneId: Text): Text
    var
        TimeZone: Record "Time Zone";
    begin
        TimeZone.SetRange(ID, ZoneId);
        if TimeZone.FindFirst() then
            exit('present, ID ' + TimeZone.ID + ', count ' + Format(TimeZone.Count()));
        exit('absent');
    end;
}
