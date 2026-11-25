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
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Finish();
    end;
}
