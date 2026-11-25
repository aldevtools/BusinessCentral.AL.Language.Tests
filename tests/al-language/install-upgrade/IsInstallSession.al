// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures for IsInstallSessionTests.al (al-runner issue 9046): what runs inside the install session of this app.
// No Subtype = Install codeunit (check-install-triggers.py): the install code is two "Extension Triggers" subscribers.
// Login and company-open subscribers ("Company Triggers" OnCompanyOpen / OnCompanyOpenCompleted, "System Initialization"
//   OnAfterInitialization / OnAfterLogin) note every call in the SingleInstance "LT IS9 State" (every session, no write) and write a
//   log row only when the execution context is Install or Upgrade. The install subscribers write one row at their start with what
//   they see: the calls noted so far in this session, the session facts, the "User Login" row of the current user (read through a
//   RecordRef, the table is Access = Internal) and the calls a login subscriber of XApp A noted (IsXaLoginSeen.al).
// Every write is `if Insert() then;` into a DataPerCompany = false table; reads that can fail run in TryFunctions.
// BC versions: 27 - 29

table 75430 "LT IS9 Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[40]) { }
        field(3; Company; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; Context; Text[30]) { }
        field(6; Facts; Text[250]) { }
        field(7; Seen; Text[250]) { }
        field(8; "Login Facts"; Text[250]) { }
        field(9; "XA Seen"; Text[250]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 75431 "LT IS9 State"
{
    SingleInstance = true;

    var
        Calls: Text;
        SnapTaken: Boolean;
        SnapText: Text;
        SnapLast: DateTime;

    procedure Add(Name: Text)
    begin
        Calls += Name + ';';
    end;

    procedure AsText(): Text
    begin
        exit(Calls);
    end;

    procedure TakeSnapshot(Found: Text; Last: DateTime)
    begin
        if SnapTaken then
            exit;
        SnapTaken := true;
        SnapText := Found;
        SnapLast := Last;
    end;

    procedure Snapshot(var Last: DateTime): Text
    begin
        Last := SnapLast;
        if not SnapTaken then
            exit('no snapshot');
        exit(SnapText);
    end;
}

codeunit 75432 "LT IS9 Subs"
{
    var
        State: Codeunit "LT IS9 State";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    var
        Found: Text;
        Last: DateTime;
    begin
        Found := ReadUserLogin(Last);
        State.TakeSnapshot(Found, Last);
        Note('OnCompanyOpen');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    begin
        Note('OnCompanyOpenCompleted');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure AfterInitialization()
    begin
        Note('OnAfterInitialization');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('OnAfterLogin');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    begin
        InstallStart('install per company');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    begin
        InstallStart('install per database');
    end;

    local procedure Note(Name: Text)
    begin
        State.Add(Name);
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            Write(Name, '', '', '', '');
    end;

    local procedure InstallStart(Kind: Text)
    var
        XaSeen: Codeunit "LT IS9 XA Login Seen";
        SnapLast: DateTime;
        NowFound: Text;
        NowLast: DateTime;
        LoginFacts: Text;
        Facts: Text;
    begin
        Facts := 'gui=' + Format(GuiAllowed()) + '|client=' + Format(CurrentClientType()) +
            '|mode=' + Format(Session.CurrentExecutionMode()) + '|company blank=' + Format(CompanyName() = '');
        LoginFacts := 'at company open: ' + State.Snapshot(SnapLast);
        NowFound := ReadUserLogin(NowLast);
        LoginFacts += '|at install start: ' + NowFound;
        if (NowLast <> 0DT) or (SnapLast <> 0DT) then
            LoginFacts += '|last login changed=' + Format(NowLast <> SnapLast);
        Write(Kind, Facts, State.AsText(), LoginFacts, XaSeen.AsText());
    end;

    local procedure Write(Kind: Text; Facts: Text; Seen: Text; LoginFacts: Text; XaSeen: Text)
    var
        Log: Record "LT IS9 Log";
    begin
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log."Session Id" := SessionId();
        Log.Context := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log.Context));
        Log.Facts := CopyStr(Facts, 1, MaxStrLen(Log.Facts));
        Log.Seen := CopyStr(Seen, 1, MaxStrLen(Log.Seen));
        Log."Login Facts" := CopyStr(LoginFacts, 1, MaxStrLen(Log."Login Facts"));
        Log."XA Seen" := CopyStr(XaSeen, 1, MaxStrLen(Log."XA Seen"));
        if Log.Insert() then;
    end;

    // 'row' / 'no row' for the current user's "User Login" row, or the error text when the read fails.
    procedure ReadUserLogin(var Last: DateTime): Text
    var
        Found: Boolean;
    begin
        Last := 0DT;
        ClearLastError();
        if not TryReadUserLogin(Found, Last) then
            exit('error: ' + CopyStr(GetLastErrorText(), 1, 120));
        if Found then
            exit('row');
        exit('no row');
    end;

    [TryFunction]
    local procedure TryReadUserLogin(var Found: Boolean; var Last: DateTime)
    var
        RecRef: RecordRef;
        SidRef: FieldRef;
    begin
        RecRef.Open(9008);
        SidRef := RecRef.Field(1);
        SidRef.SetRange(UserSecurityId());
        Found := RecRef.FindFirst();
        if Found then
            Last := RecRef.Field(4).Value();
        RecRef.Close();
    end;
}
