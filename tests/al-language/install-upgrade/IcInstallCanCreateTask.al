// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/taskscheduler/taskscheduler-cancreatetask-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/codeunit/codeunit-company-triggers
// Scope: in-scope
// Fixtures for IcInstallCanCreateTaskTests.al (al-runner issue 9123): what TaskScheduler.CanCreateTask() answers in the company-open and login
//   subscribers that run inside the install session of this app.
// No Subtype = Install codeunit (check-install-triggers.py): the install code is two "Extension Triggers" subscribers.
// The "Company Triggers" OnCompanyOpen / OnCompanyOpenCompleted and "System Initialization" OnAfterInitialization / OnAfterLogin subscribers
//   read CanCreateTask(), GetExecutionContext(), GetCurrentModuleExecutionContext() and CurrentExecutionMode(). They note the reads in the
//   SingleInstance "LT IC State" in every session (no write) and write a log row only when the execution context is Install or Upgrade.
//   The install subscribers write a row with the same reads and the session id, so the test can tell the install session's rows from
//   rows of other sessions, plus what the XApp A subscriber noted (tests/al-language-xapp-a/IcXaCanCreateTask.al).
// Every write is `if Insert() then;` into a DataPerCompany = false table.
// BC versions: 27 - 29

table 75990 "LT IC Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; Kind; Text[40]) { }
        field(3; Company; Text[60]) { }
        field(4; "Session Id"; Integer) { }
        field(5; Facts; Text[250]) { }
        field(6; "XA Seen"; Text[1000]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 75991 "LT IC State"
{
    SingleInstance = true;

    var
        Calls: Text;

    procedure Add(Entry: Text)
    begin
        Calls += Entry + ';';
    end;

    procedure AsText(): Text
    begin
        exit(Calls);
    end;
}

codeunit 75992 "LT IC Subs"
{
    var
        State: Codeunit "LT IC State";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterInitialization', '', false, false)]
    local procedure AfterInitialization()
    begin
        Note('OnAfterInitialization');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpen', '', false, false)]
    local procedure CompanyOpen()
    begin
        Note('OnCompanyOpen');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"System Initialization", 'OnAfterLogin', '', false, false)]
    local procedure AfterLogin()
    begin
        Note('OnAfterLogin');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Company Triggers", 'OnCompanyOpenCompleted', '', false, false)]
    local procedure CompanyOpenCompleted()
    begin
        Note('OnCompanyOpenCompleted');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        XaSeen: Codeunit "LT IC XA Seen";
    begin
        Write('install per company', Facts(), XaSeen.AsText());
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        XaSeen: Codeunit "LT IC XA Seen";
    begin
        Write('install per database', Facts(), XaSeen.AsText());
    end;

    procedure Facts(): Text
    begin
        exit('ctx=' + Format(Session.GetExecutionContext()) + ',mod=' + Format(Session.GetCurrentModuleExecutionContext()) +
            ',mode=' + Format(Session.CurrentExecutionMode()) + ',cct=' + Format(TaskScheduler.CanCreateTask()));
    end;

    local procedure Note(Name: Text)
    var
        Read: Text;
    begin
        Read := Facts();
        State.Add(Name + '|' + Read);
        if Session.GetExecutionContext() in [ExecutionContext::Install, ExecutionContext::Upgrade] then
            Write(Name, Read, '');
    end;

    local procedure Write(Kind: Text; Read: Text; XaSeen: Text)
    var
        Log: Record "LT IC Log";
    begin
        Log.Init();
        Log.Kind := CopyStr(Kind, 1, MaxStrLen(Log.Kind));
        Log.Company := CopyStr(CompanyName(), 1, MaxStrLen(Log.Company));
        Log."Session Id" := SessionId();
        Log.Facts := CopyStr(Read, 1, MaxStrLen(Log.Facts));
        Log."XA Seen" := CopyStr(XaSeen, 1, MaxStrLen(Log."XA Seen"));
        if Log.Insert() then;
    end;
}
