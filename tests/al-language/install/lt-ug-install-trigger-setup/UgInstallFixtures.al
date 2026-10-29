// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: none (own tables 90360 - 90363, codeunits 90364 - 90366)
// Probe: outside issue 6148 (a 45-app AppSource suite whose OnInstallAppPerDatabase reaches a GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup
//   subscriber that reads a per-company setup table with IsEmpty and has no CompanyName() guard). Question: does the platform ask for the database trigger
//   setup while the per-database part of an install runs, with which company, and does the IsEmpty of a per-company table in that subscriber work?
// Install code must never fail (check-install-triggers.py): no Subtype = Install codeunit here, only subscribers of Codeunit "Extension Triggers" (as
//   install/lt-bf-install-probes/BfInstallFixtures.al). Every write goes into a DataPerCompany = false table or the per-company table of the per-company part;
//   the reads that can fail run in a TryFunction.
// The writes of the install subscribers use Insert(true) because the platform asks for the table trigger setup only for a write with RunTrigger true
//   (events/lt-table-trigger-setup-calls/TableTriggerSetupCalls.al). The log writes use Insert(false).
// BC versions: 27 - 29

// Written by the per-database part only (Insert(true)).
table 90360 "LT UG Database Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// Written by the per-company part only (Insert(true)), once per company.
table 90361 "LT UG Company Part Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// A per-company table (DataPerCompany is true by default): the table the trigger setup subscriber reads, as the setup table of the issue.
table 90362 "LT UG Per Company Setup"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

table 90363 "LT UG Setup Log"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; Id; Integer) { AutoIncrement = true; }
        field(2; "Table Id"; Integer) { }
        field(3; "Company"; Text[60]) { }
        field(4; "Context"; Text[30]) { }
        field(5; "Install Part"; Text[30]) { }
        field(6; Info; Text[2048]) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

// Which install routine is running: set by the install subscribers, read by the trigger setup subscriber.
codeunit 90364 "LT UG Install State"
{
    SingleInstance = true;

    var
        Part: Text;

    procedure SetPart(NewPart: Text)
    begin
        Part := NewPart;
    end;

    procedure GetPart(): Text
    begin
        exit(Part);
    end;

    [TryFunction]
    procedure TryIsEmpty()
    var
        Setup: Record "LT UG Per Company Setup";
    begin
        if Setup.IsEmpty() then;
    end;

    procedure Reads(): Text
    var
        Result: Text;
    begin
        if TryIsEmpty() then
            Result := 'isempty=ok'
        else
            Result := 'isempty=error|' + GetLastErrorText() + '|' + GetLastErrorCode();
        ClearLastError();
        exit(Result);
    end;
}

codeunit 90365 "LT UG Install Subs"
{
    var
        State: Codeunit "LT UG Install State";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerCompany', '', false, false)]
    local procedure InstallPerCompany()
    var
        CompanyRow: Record "LT UG Company Part Row";
        Setup: Record "LT UG Per Company Setup";
    begin
        State.SetPart('per company');
        // The trigger setup is asked for a table when the first write with RunTrigger true reaches it in the install session.
        if CompanyRow.Insert(true) then;
        CompanyRow.Id := 1;
        if CompanyRow.Insert(true) then;
        if Setup.Insert(true) then;
        State.SetPart('');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Extension Triggers", 'OnInstallAppPerDatabase', '', false, false)]
    local procedure InstallPerDatabase()
    var
        DatabaseRow: Record "LT UG Database Row";
        Log: Record "LT UG Setup Log";
    begin
        State.SetPart('per database');
        Log.Init();
        Log."Table Id" := 0;
        Log."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Log."Company"));
        Log."Context" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log."Context"));
        Log."Install Part" := 'per database';
        Log.Info := 'install subscriber: ' + State.Reads();
        if Log.Insert(false) then;
        DatabaseRow.Id := 1;
        if DatabaseRow.Insert(true) then;
        State.SetPart('');
    end;
}

// The subscriber of the issue: GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup, reading a per-company table. It answers for the tables of this
// probe only, never sets a flag, and logs what it saw (company, execution context, the install routine running, the read of the per-company table).
codeunit 90366 "LT UG Trigger Setup Subs"
{
    var
        State: Codeunit "LT UG Install State";

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, OnAfterGetDatabaseTableTriggerSetup, '', false, false)]
    local procedure SetTableTriggerSetup(TableID: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Record "LT UG Setup Log";
    begin
        if not (TableID in [Database::"LT UG Database Row", Database::"LT UG Company Part Row", Database::"LT UG Per Company Setup"]) then
            exit;
        Log.Init();
        Log."Table Id" := TableID;
        Log."Company" := CopyStr(CompanyName(), 1, MaxStrLen(Log."Company"));
        Log."Context" := CopyStr(Format(Session.GetExecutionContext()), 1, MaxStrLen(Log."Context"));
        Log."Install Part" := CopyStr(State.GetPart(), 1, MaxStrLen(Log."Install Part"));
        Log.Info := State.Reads();
        if Log.Insert(false) then;
    end;
}
