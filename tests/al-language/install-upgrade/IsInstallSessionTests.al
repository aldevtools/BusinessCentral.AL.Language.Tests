// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT IS9 Log, LT IS9 State, LT IS9 Subs (IsInstallSession.al); XApp A LT IS9 XA Login Seen
//   (tests/al-language-xapp-a/IsXaLoginSeen.al).
// Probe: al-runner issue 9046 step 2. What runs inside the install session of this app: the company-open and login events, their order
//   against the install code, the "User Login" side effect of the System Application's login subscriber, the session facts the
//   install code sees, and whether a login subscriber of XApp A (installed earlier) runs in this app's install session. The test
//   session is the control. Also TaskScheduler.CanCreateTask() inside the install code (al-runner issue 9082). Sessions are numbered S1, S2, ... and companies C1, C2, ... in the order their first log row was written (no ids or
//   names: the company order differs between hosts). "User Login" is recorded only as created-or-changed, so a fresh database and
//   a reused one give the same text.
// Measured on BC 27.5 (Windows sandbox, local observe), 2026-11-25: the install session is one session. Per company it raises
//   OnAfterInitialization, OnCompanyOpen, OnAfterLogin, OnCompanyOpenCompleted in that order before the install code; the
//   per-database install code runs last, with a blank company, and no event before it. A subscriber of XApp A (installed
//   earlier) runs there too. The "User Login" row is not created or changed in the install session (it is in the test session);
//   with a blank company the table cannot be read. TaskScheduler.CanCreateTask() is true in install code, false in the test.
// BC versions: 27 - 29
codeunit 75433 "LT IS9 Install Session Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Tag(Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if Company = CompanyName() then
            exit('session company');
        exit('other company');
    end;

    local procedure SessionNo(var Sessions: List of [Integer]; Id: Integer): Text
    begin
        if not Sessions.Contains(Id) then
            Sessions.Add(Id);
        exit('S' + Format(Sessions.IndexOf(Id)));
    end;

    local procedure CompanyNo(var Companies: List of [Text]; Company: Text): Text
    begin
        if Company = '' then
            exit('blank');
        if not Companies.Contains(Company) then
            Companies.Add(Company);
        exit('C' + Format(Companies.IndexOf(Company)));
    end;

    [Test]
    procedure InstallSession_LogSequence_EventsAndInstallCode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IS9 Log";
        Sessions: List of [Integer];
        Companies: List of [Text];
        Sequence: Text;
    begin
        Log.SetCurrentKey(Id);
        if Log.FindSet() then
            repeat
                Sequence += Log.Kind + '|' + CompanyNo(Companies, Log.Company) + '|' + Log.Context + '|' + SessionNo(Sessions, Log."Session Id") + ';';
            until Log.Next() = 0;
        Observer.Observe('sequence', Sequence);
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Observe('test session among them', Format(Sessions.Contains(SessionId())));
        Observer.Expect('sequence', 'OnAfterInitialization|C1|Install|S1;OnCompanyOpen|C1|Install|S1;OnAfterLogin|C1|Install|S1;OnCompanyOpenCompleted|C1|Install|S1;install per company|C1|Install|S1;OnAfterInitialization|C2|Install|S1;OnCompanyOpen|C2|Install|S1;OnAfterLogin|C2|Install|S1;OnCompanyOpenCompleted|C2|Install|S1;install per company|C2|Install|S1;install per database|blank|Install|S1;');
        Observer.Expect('sessions', '1');
        Observer.Expect('test session among them', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure InstallPerCompany_WhatTheInstallCodeSaw()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IS9 Log";
    begin
        Log.SetCurrentKey(Id);
        Log.SetRange(Kind, 'install per company');
        Observer.Observe('rows', Format(Log.Count()));
        Log.SetRange(Company, CompanyName());
        ObserveCompanyRows(Observer, Log);
        Log.SetFilter(Company, '<>%1', CompanyName());
        ObserveCompanyRows(Observer, Log);
        Observer.Expect('rows', '2');
        Observer.Expect('session company: context', 'Install');
        Observer.Expect('session company: facts', 'gui=No|client=SOAP|mode=Standard|company blank=No|can create task=Yes');
        Observer.Expect('session company: calls noted before', 'OnAfterInitialization;OnCompanyOpen;OnAfterLogin;OnCompanyOpenCompleted;');
        Observer.Expect('session company: user login', 'created or changed since company open=No');
        Observer.Expect('session company: xapp a subscriber', 'OnAfterLogin|Install;OnCompanyOpenCompleted|Install;');
        Observer.Expect('other company: context', 'Install');
        Observer.Expect('other company: facts', 'gui=No|client=SOAP|mode=Standard|company blank=No|can create task=Yes');
        Observer.Expect('other company: calls noted before', 'OnAfterInitialization;OnCompanyOpen;OnAfterLogin;OnCompanyOpenCompleted;');
        Observer.Expect('other company: user login', 'created or changed since company open=No');
        Observer.Expect('other company: xapp a subscriber', 'OnAfterLogin|Install;OnCompanyOpenCompleted|Install;');
        Observer.Verify();
    end;

    local procedure ObserveCompanyRows(var Observer: Codeunit "Probe Observer"; var Log: Record "LT IS9 Log")
    begin
        if Log.FindSet() then
            repeat
                Observer.Observe(Tag(Log.Company) + ': context', Log.Context);
                Observer.Observe(Tag(Log.Company) + ': facts', Log.Facts);
                Observer.Observe(Tag(Log.Company) + ': calls noted before', Log.Seen);
                Observer.Observe(Tag(Log.Company) + ': user login', Log."Login Facts");
                Observer.Observe(Tag(Log.Company) + ': xapp a subscriber', Log."XA Seen");
            until Log.Next() = 0;
    end;

    [Test]
    procedure InstallPerDatabase_WhatTheInstallCodeSaw()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IS9 Log";
        FirstCompanyRow: Record "LT IS9 Log";
    begin
        Log.SetRange(Kind, 'install per database');
        Observer.Observe('rows', Format(Log.Count()));
        if Log.FindFirst() then begin
            Observer.Observe('company', Tag(Log.Company));
            Observer.Observe('context', Log.Context);
            Observer.Observe('facts', Log.Facts);
            Observer.Observe('calls noted before', Log.Seen);
            Observer.Observe('user login', Log."Login Facts");
            Observer.Observe('xapp a subscriber', Log."XA Seen");
            FirstCompanyRow.SetRange(Kind, 'install per company');
            if FirstCompanyRow.FindFirst() then begin
                Observer.Observe('same session as per company', Format(FirstCompanyRow."Session Id" = Log."Session Id"));
                Observer.Observe('after per company', Format(FirstCompanyRow.Id < Log.Id));
            end;
        end;
        Observer.Expect('rows', '1');
        Observer.Expect('company', 'blank');
        Observer.Expect('context', 'Install');
        Observer.Expect('facts', 'gui=No|client=SOAP|mode=Standard|company blank=Yes|can create task=Yes');
        Observer.Expect('calls noted before', '');
        Observer.Expect('user login', 'at company open: no snapshot|at install start: error: You must choose a company before you can access the "User Login" table.');
        Observer.Expect('xapp a subscriber', '');
        Observer.Expect('same session as per company', 'Yes');
        Observer.Expect('after per company', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure TestSession_Control_CallsAndUserLogin()
    var
        Observer: Codeunit "Probe Observer";
        State: Codeunit "LT IS9 State";
        XaSeen: Codeunit "LT IS9 XA Login Seen";
        Subs: Codeunit "LT IS9 Subs";
        SnapLast: DateTime;
        NowLast: DateTime;
        Snap: Text;
        NowFound: Text;
    begin
        Snap := State.Snapshot(SnapLast);
        NowFound := Subs.ReadUserLogin(NowLast);
        Observer.Observe('calls noted in the test session', State.AsText());
        Observer.Observe('user login created or changed since company open', Format((Snap <> NowFound) or (NowLast <> SnapLast)));
        Observer.Observe('xapp a subscriber', XaSeen.AsText());
        Observer.Observe('context', Format(Session.GetExecutionContext()));
        Observer.Observe('mode', Format(Session.CurrentExecutionMode()));
        Observer.Observe('can create task', Format(TaskScheduler.CanCreateTask()));
        Observer.Expect('calls noted in the test session', 'OnAfterInitialization;OnCompanyOpen;OnAfterLogin;OnCompanyOpenCompleted;');
        Observer.Expect('user login created or changed since company open', 'Yes');
        Observer.Expect('xapp a subscriber', 'OnAfterLogin|Normal;OnCompanyOpenCompleted|Normal;');
        Observer.Expect('context', 'Normal');
        Observer.Expect('mode', 'Standard');
        Observer.Expect('can create task', 'No');
        Observer.Verify();
    end;
}
