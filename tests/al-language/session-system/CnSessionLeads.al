// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-createtask-integer-integer-boolean-string-datetime-recordid-duration-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); codeunit 84889 (CnIsolatedStorageLeads.al); "LT P Upgrade Empty" (67282, PUpgradeTriggers.al); codeunit 10 "Type Helper" (Base Application)
// Probe: corpus issue #669 (writer CN).
//   58: the user a TaskScheduler task is created for: the "Scheduled Task" row's User ID and User Name next to UserSecurityId() and UserId().
//       The task itself does not run while the test runs (W6TaskScheduler.al), so what UserId() returns inside it is not observable here.
//   59 (microsoft/AL#4625): Type Helper GetCurrUTCDateTime, GetCurrUTCDateTimeAsText and GetCurrUTCDateTimeISO8601 next to CurrentDateTime(),
//       as relations only (no test may depend on the run date).
//   48 (microsoft/AL#5120): Insert, Modify and Delete on the application-database table "OData Edm Type" (2000000179) from a test.
//   54: SessionSettings.TimeZone and CreateDateTime, DT2Date, DT2Time, Format(DateTime, 0, 9) in the test session (install code is not probed: check-install-triggers.py).
//   49 (microsoft/AL#6857): Run of an Upgrade codeunit through a codeunit variable (Codeunit.Run by id is pinned in PUpgradeTriggers.al).
// Measured (local BC 29, checked by the CI matrix): the Scheduled Task row carries the creating session's UserSecurityId and UserId; Type Helper's
//   UTC value equals CurrentDateTime; the test session's time zone is UTC; OData Edm Type accepts Insert, Modify and Delete from a test (this is not SaaS);
//   a Run through an Upgrade codeunit variable fails like Codeunit.Run by id (UpgradeCodeunitOnRunCall).
// BC versions: 27, 28, 29

codeunit 84894 "LT CN Task User"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure CreateTask_ScheduledTaskUser()
    var
        Observer: Codeunit "Probe Observer";
        Task: Record "Scheduled Task";
        TaskId: Guid;
    begin
        TaskId := TaskScheduler.CreateTask(Codeunit::"LT CN Noop", 0, false);
        Observer.Observe('row', Format(Task.Get(TaskId)));
        Observer.Observe('user id is session user', Format(Task."User ID" = UserSecurityId()));
        Observer.Observe('user name is UserId', Format(Task."User Name" = UserId()));
        Observer.Observe('user name empty', Format(Task."User Name" = ''));
        Observer.Observe('company is current', Format(Task.Company = CompanyName()));
        Observer.Observe('run codeunit', Format(Task."Run Codeunit" = Codeunit::"LT CN Noop"));
        Observer.Observe('is ready', Format(Task."Is Ready"));
        TaskScheduler.CancelTask(TaskId);
        Observer.Expect('row', 'Yes');
        Observer.Expect('user id is session user', 'Yes');
        Observer.Expect('user name is UserId', 'Yes');
        Observer.Expect('user name empty', 'No');
        Observer.Expect('company is current', 'Yes');
        Observer.Expect('run codeunit', 'Yes');
        Observer.Expect('is ready', 'No');
        Observer.Verify();
    end;
}

codeunit 84895 "LT CN TypeHelper UTC"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure GetCurrUTCDateTime_IsCurrentDateTime()
    var
        Observer: Codeunit "Probe Observer";
        TypeHelper: Codeunit "Type Helper";
        Before: DateTime;
        Utc: DateTime;
        After: DateTime;
    begin
        Before := CurrentDateTime();
        Utc := TypeHelper.GetCurrUTCDateTime();
        After := CurrentDateTime();
        Observer.Observe('not before', Format(Utc - Before > -1000));
        Observer.Observe('not after', Format(After - Utc > -1000));
        Observer.Expect('not before', 'Yes');
        Observer.Expect('not after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure GetCurrUTCDateTime_TextForms()
    var
        Observer: Codeunit "Probe Observer";
        TypeHelper: Codeunit "Type Helper";
        AsText: Text;
        Iso: Text;
        IsoDt: DateTime;
    begin
        AsText := TypeHelper.GetCurrUTCDateTimeAsText();
        Iso := TypeHelper.GetCurrUTCDateTimeISO8601();
        Observer.Observe('as text len', Format(StrLen(AsText)));
        Observer.Observe('as text ends GMT', Format(AsText.EndsWith(' GMT')));
        Observer.Observe('as text comma', CopyStr(AsText, 4, 2));
        Observer.Observe('iso len', Format(StrLen(Iso)));
        Observer.Observe('iso T', CopyStr(Iso, 11, 1));
        Observer.Observe('iso Z', CopyStr(Iso, 20, 1));
        Observer.Observe('iso evaluates', Format(Evaluate(IsoDt, Iso, 9)));
        Observer.Observe('iso near now', Format(Abs(CurrentDateTime() - IsoDt) < 5000));
        Observer.Expect('as text len', '29');
        Observer.Expect('as text ends GMT', 'Yes');
        Observer.Expect('as text comma', ', ');
        Observer.Expect('iso len', '20');
        Observer.Expect('iso T', 'T');
        Observer.Expect('iso Z', 'Z');
        Observer.Expect('iso evaluates', 'Yes');
        Observer.Expect('iso near now', 'Yes');
        Observer.Verify();
    end;

    // Item 54, the test-session half: the session time zone and the DateTime conversions in it.
    [Test]
    procedure TestSession_TimeZoneAndConversions()
    var
        Observer: Codeunit "Probe Observer";
        S: SessionSettings;
        DT: DateTime;
    begin
        S.Init();
        DT := CreateDateTime(20240601D, 120000T);
        Observer.Observe('time zone', S.TimeZone());
        Observer.Observe('format 9', Format(DT, 0, 9));
        Observer.Observe('dt2date', Format(DT2Date(DT), 0, 9));
        Observer.Observe('dt2time', Format(DT2Time(DT), 0, 9));
        Observer.Expect('time zone', 'UTC');
        Observer.Expect('format 9', '2024-06-01T12:00:00Z');
        Observer.Expect('dt2date', '2024-06-01');
        Observer.Expect('dt2time', '12:00:00');
        Observer.Verify();
    end;
}

codeunit 84896 "LT CN OData Edm"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ODataEdmType_InsertModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
        E: Record "OData Edm Type";
    begin
        if E.Get('LTCN-PROBE') then
            E.Delete();
        E.Init();
        E."Key" := 'LTCN-PROBE';
        E.Description := 'x';
        Observer.Observe('insert', Format(E.Insert()));
        E.Description := 'y';
        Observer.Observe('modify', Format(E.Modify()));
        Observer.Observe('delete', Format(E.Delete()));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('delete', 'Yes');
        Observer.Verify();
    end;
}

codeunit 84897 "LT CN Upgrade Run Var"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure UpgradeCodeunit_RunThroughVariable()
    var
        Observer: Codeunit "Probe Observer";
        U: Codeunit "LT P Upgrade Empty";
    begin
        asserterror U.Run();
        Observer.ObserveError('run');
        Observer.Expect('run|text', 'Upgrade codeunit ''67282'' cannot be invoked outside the schema synchronization process.');
        Observer.Expect('run|code', 'UpgradeCodeunitOnRunCall');
        Observer.Verify();
    end;
}
