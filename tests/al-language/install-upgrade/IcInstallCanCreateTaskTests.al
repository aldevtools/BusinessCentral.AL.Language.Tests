// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-cancreatetask-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT IC Log, LT IC State, LT IC Subs (IcInstallCanCreateTask.al); XApp A LT IC XA Seen
//   (tests/al-language-xapp-a/IcXaCanCreateTask.al).
// Probe: al-runner issue 9123. TaskScheduler.CanCreateTask() read in "Company Triggers" OnCompanyOpen / OnCompanyOpenCompleted and
//   "System Initialization" OnAfterInitialization / OnAfterLogin subscribers while the install session of this app runs, per company and
//   before the per-database install code, in this app and in a subscriber of XApp A (installed earlier); beside each read
//   Session.GetExecutionContext() (ctx), Session.GetCurrentModuleExecutionContext() (mod) and Session.CurrentExecutionMode() (mode).
//   Install-session rows are the rows with the session id of the install code's rows. The test session is the control.
//   Companies are numbered C1, C2, ... in the order of their first row (no names: the company order differs between hosts).
//   XApp A cells: XApp A's Subtype = Install codeunit (tests/al-language-xapp-a/IcXaInstallCanCreateTask.al) reads the same facts in
//   OnInstallAppPerCompany (session company, other company) and OnInstallAppPerDatabase, then runs
//   `if CanCreateTask then CreateTask("LT IC XA Seen", 0) else Codeunit.Run("LT IC XA Seen")`. The test reads which branch ran, whether the task
//   still exists (TaskExists, Scheduled Task rows), and the rows the codeunit wrote (task session or install session), when the test starts.
//   A first run waited up to 60 seconds: the tasks still had not run, on all three versions. The final test does not wait (60 s per version).
// Measured on: BC 27.5, 28.5 and 29.0 in corpus CI (fresh install of every app). All tests gave the same values on all three.
//   In the install session CanCreateTask answers Yes in all four subscribers, in XApp A's subscribers, and in both install triggers, and CreateTask there
//   returns a non-blank task id (per database and per company, in both companies); all 3 tasks exist (TaskExists = Yes) and none has run when the test starts; in the
//   test session it answers Yes in the subscribers and No in the test procedure.
// Not measured: upgrade sessions (CI installs fresh; the fixtures write rows for Upgrade too).
// BC versions: 27 - 29
codeunit 75993 "LT IC Install CCT Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure CompanyNo(var Companies: List of [Text]; Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if not Companies.Contains(Company) then
            Companies.Add(Company);
        exit('C' + Format(Companies.IndexOf(Company)));
    end;

    local procedure InstallSessionId(): Integer
    var
        Log: Record "LT IC Log";
    begin
        Log.SetRange(Kind, 'install per database');
        if Log.FindFirst() then
            exit(Log."Session Id");
        exit(-1);
    end;

    local procedure CompanyLabel(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    local procedure XaInstallSessionId(): Integer
    var
        XaLog: Record "LT IC XA Log";
    begin
        XaLog.SetRange(Kind, 'install per database');
        if XaLog.FindFirst() then
            exit(XaLog."Session Id");
        exit(-1);
    end;

    local procedure TaskState(): Text
    var
        XaLog: Record "LT IC XA Log";
        Task: Record "Scheduled Task";
        Result: Text;
        InstallId: Integer;
    begin
        SelectLatestVersion();
        InstallId := XaInstallSessionId();
        XaLog.SetCurrentKey(Id);
        XaLog.SetFilter(Kind, 'install per company|install per database');
        if XaLog.FindSet() then
            repeat
                if not IsNullGuid(XaLog."Task Id") then
                    Result += XaLog.Kind + ' ' + CompanyLabel(XaLog.Company) + ': TaskExists=' + Format(TaskScheduler.TaskExists(XaLog."Task Id")) + ';';
            until XaLog.Next() = 0;
        Task.SetRange("Run Codeunit", Codeunit::"LT IC XA Seen");
        Result += 'Scheduled Task rows=' + Format(Task.Count()) + ';';
        XaLog.SetRange(Kind, 'codeunit ran');
        Result += 'codeunit ran rows=' + Format(XaLog.Count()) + ';';
        if XaLog.FindSet() then
            repeat
                Result += CompanyLabel(XaLog.Company) + '|install session=' + Format(XaLog."Session Id" = InstallId) + '|' + XaLog.Facts + ';';
            until XaLog.Next() = 0;
        exit(Result);
    end;

    [Test]
    procedure XAppAInstall_CreateTask_TasksExistAndHaveNotRun()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('when the test starts', TaskState());
        Observer.Expect('when the test starts', 'install per company session company: TaskExists=Yes;install per company other company: TaskExists=Yes;install per database blank: TaskExists=Yes;Scheduled Task rows=3;codeunit ran rows=0;');
        Observer.Verify();
    end;

    [Test]
    procedure XAppAInstall_CanCreateTask_InInstallTriggers()
    var
        Observer: Codeunit "Probe Observer";
        XaLog: Record "LT IC XA Log";
        InstallId: Integer;
        OneSession: Boolean;
    begin
        InstallId := XaInstallSessionId();
        Observer.Observe('install per database row', Format(InstallId <> -1));
        OneSession := true;
        XaLog.SetCurrentKey(Id);
        XaLog.SetFilter(Kind, 'install per company|install per database');
        if XaLog.FindSet() then
            repeat
                Observer.Observe(XaLog.Kind + ' ' + CompanyLabel(XaLog.Company), XaLog.Facts + '|' + XaLog.Branch + '|task id blank=' + Format(IsNullGuid(XaLog."Task Id")));
                OneSession := OneSession and (XaLog."Session Id" = InstallId);
            until XaLog.Next() = 0;
        Observer.Observe('all install rows in one session', Format(OneSession));
        Observer.Observe('test session is the install session', Format(SessionId() = InstallId));
        Observer.Expect('install per database row', 'Yes');
        Observer.Expect('install per company session company', 'ctx=Install,mod=Install,mode=Standard,cct=Yes|CreateTask|task id blank=No');
        Observer.Expect('install per company other company', 'ctx=Install,mod=Install,mode=Standard,cct=Yes|CreateTask|task id blank=No');
        Observer.Expect('install per database blank', 'ctx=Install,mod=Install,mode=Standard,cct=Yes|CreateTask|task id blank=No');
        Observer.Expect('all install rows in one session', 'Yes');
        Observer.Expect('test session is the install session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallSession_CanCreateTask_InSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IC Log";
        Companies: List of [Text];
        Sequence: Text;
        InstallId: Integer;
        PerCompanySessions: Integer;
    begin
        InstallId := InstallSessionId();
        Observer.Observe('install per database rows', Format(InstallId <> -1));
        Log.SetCurrentKey(Id);
        Log.SetRange("Session Id", InstallId);
        if Log.FindSet() then
            repeat
                Sequence += Log.Kind + '|' + CompanyNo(Companies, Log.Company) + '|' + Log.Facts + ';';
            until Log.Next() = 0;
        Observer.Observe('install session', Sequence);
        Log.SetFilter("Session Id", '<>%1', InstallId);
        Observer.Observe('rows of other sessions', Format(Log.Count()));
        Log.SetRange("Session Id");
        Log.SetRange(Kind, 'install per company');
        Log.SetFilter("Session Id", '<>%1', InstallId);
        PerCompanySessions := Log.Count();
        Observer.Observe('per company install rows in another session', Format(PerCompanySessions));
        Observer.Observe('test session is the install session', Format(SessionId() = InstallId));
        Observer.Expect('install per database rows', 'Yes');
        Observer.Expect('install session', 'OnAfterInitialization|C1|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnCompanyOpen|C1|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnAfterLogin|C1|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnCompanyOpenCompleted|C1|ctx=Install,mod=Install,mode=Standard,cct=Yes;install per company|C1|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnAfterInitialization|C2|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnCompanyOpen|C2|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnAfterLogin|C2|ctx=Install,mod=Install,mode=Standard,cct=Yes;OnCompanyOpenCompleted|C2|ctx=Install,mod=Install,mode=Standard,cct=Yes;install per company|C2|ctx=Install,mod=Install,mode=Standard,cct=Yes;install per database|blank|ctx=Install,mod=Install,mode=Standard,cct=Yes;');
        Observer.Expect('rows of other sessions', '0');
        Observer.Expect('per company install rows in another session', '0');
        Observer.Expect('test session is the install session', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallSession_CanCreateTask_XAppASubscriber()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IC Log";
        Companies: List of [Text];
    begin
        Log.SetCurrentKey(Id);
        Log.SetFilter(Kind, 'install per company|install per database');
        if Log.FindSet() then
            repeat
                Observer.Observe(Log.Kind + ' ' + CompanyNo(Companies, Log.Company) + ': xapp a subscriber', Log."XA Seen");
            until Log.Next() = 0;
        Observer.Expect('install per company C1: xapp a subscriber', 'OnCompanyOpen|ctx=Install,mod=Normal,mode=Standard,cct=Yes;OnAfterLogin|ctx=Install,mod=Normal,mode=Standard,cct=Yes;OnCompanyOpenCompleted|ctx=Install,mod=Normal,mode=Standard,cct=Yes;');
        Observer.Expect('install per company C2: xapp a subscriber', 'OnCompanyOpen|ctx=Install,mod=Normal,mode=Standard,cct=Yes;OnAfterLogin|ctx=Install,mod=Normal,mode=Standard,cct=Yes;OnCompanyOpenCompleted|ctx=Install,mod=Normal,mode=Standard,cct=Yes;');
        Observer.Expect('install per database blank: xapp a subscriber', '');
        Observer.Verify();
    end;

    [Test]
    procedure TestSession_Control_CanCreateTask_InSubscribers()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT IC State";
        XaSeen: Codeunit "LT IC XA Seen";
        Subs: Codeunit "LT IC Subs";
    begin
        Observer.Observe('subscribers in the test session', State.AsText());
        Observer.Observe('xapp a subscriber in the test session', XaSeen.AsText());
        Observer.Observe('test procedure', Subs.Facts());
        Observer.Expect('subscribers in the test session', 'OnAfterInitialization|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;OnCompanyOpen|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;OnAfterLogin|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;OnCompanyOpenCompleted|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;');
        Observer.Expect('xapp a subscriber in the test session', 'OnCompanyOpen|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;OnAfterLogin|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;OnCompanyOpenCompleted|ctx=Normal,mod=Normal,mode=Standard,cct=Yes;');
        Observer.Expect('test procedure', 'ctx=Normal,mod=Normal,mode=Standard,cct=No');
        Observer.Verify();
    end;
}
