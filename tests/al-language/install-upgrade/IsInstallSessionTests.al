// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT IS9 Log, LT IS9 State, LT IS9 Subs (IsInstallSession.al); XApp A LT IS9 XA Login Seen
//   (tests/al-language-xapp-a/IsXaLoginSeen.al).
// Probe: al-runner issue 9046 step 2. What runs inside the install session of this app: the company-open and login events, their order
//   against the install code, the "User Login" side effect of the System Application's login subscriber, the session facts the
//   install code sees, and whether a login subscriber of XApp A (installed earlier) runs in this app's install session. The test
//   session is the control. Sessions are numbered S1, S2, ... in the order their first log row was written (no session ids).
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

    [Test]
    procedure InstallSession_LogSequence_EventsAndInstallCode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT IS9 Log";
        Sessions: List of [Integer];
        Sequence: Text;
    begin
        Log.SetCurrentKey(Id);
        if Log.FindSet() then
            repeat
                Sequence += Log.Kind + '|' + Tag(Log.Company) + '|' + Log.Context + '|' + SessionNo(Sessions, Log."Session Id") + ';';
            until Log.Next() = 0;
        Observer.Observe('sequence', Sequence);
        Observer.Observe('sessions', Format(Sessions.Count()));
        Observer.Observe('test session among them', Format(Sessions.Contains(SessionId())));
        Observer.Finish();
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
        if Log.FindSet() then
            repeat
                Observer.Observe(Tag(Log.Company) + ': context', Log.Context);
                Observer.Observe(Tag(Log.Company) + ': facts', Log.Facts);
                Observer.Observe(Tag(Log.Company) + ': calls noted before', Log.Seen);
                Observer.Observe(Tag(Log.Company) + ': user login', Log."Login Facts");
                Observer.Observe(Tag(Log.Company) + ': xapp a subscriber', Log."XA Seen");
            until Log.Next() = 0;
        Observer.Finish();
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
        Observer.Finish();
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
        Observer.Observe('user login at company open', Snap);
        Observer.Observe('user login in the test', NowFound);
        Observer.Observe('last login changed since company open', Format(NowLast <> SnapLast));
        Observer.Observe('xapp a subscriber', XaSeen.AsText());
        Observer.Observe('context', Format(Session.GetExecutionContext()));
        Observer.Observe('mode', Format(Session.CurrentExecutionMode()));
        Observer.Finish();
    end;
}
