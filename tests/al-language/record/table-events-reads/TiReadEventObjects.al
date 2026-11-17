// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none (objects of this folder only)
// Probe (al-runner issue 8238): objects for tests/al-language/record/table-events-reads/TiReadEventTests.al and TiCompanyReadEventTests.al.
//   A table with subscribers to all ten table events (Before and After of Insert, Modify, Delete, Rename and Validate of field Description),
//   and subscribers to the same ten events of the platform table Company (Validate of field "Display Name"). Every subscriber adds one row
//   to the log table "LT TI Event Log". No subscriber fails.
// BC versions: 27 - 29

// local object: the row table whose reads the tests run; its ten table events log to "LT TI Event Log"
table 73600 "LT TI Read Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
        key(ByDescription; Description) { }
    }
}

// local object: the log the subscribers write
table 73601 "LT TI Event Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { AutoIncrement = true; }
        field(2; "Event Name"; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

// local object: subscribers to all ten table events of "LT TI Read Row"
codeunit 73602 "LT TI Row Event Subs"
{
    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert()
    begin
        Add('Row.OnBeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert()
    begin
        Add('Row.OnAfterInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify()
    begin
        Add('Row.OnBeforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModify()
    begin
        Add('Row.OnAfterModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete()
    begin
        Add('Row.OnBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDelete()
    begin
        Add('Row.OnAfterDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnBeforeRenameEvent', '', false, false)]
    local procedure OnBeforeRename()
    begin
        Add('Row.OnBeforeRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRename()
    begin
        Add('Row.OnAfterRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnBeforeValidateEvent', 'Description', false, false)]
    local procedure OnBeforeValidate()
    begin
        Add('Row.OnBeforeValidate');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT TI Read Row", 'OnAfterValidateEvent', 'Description', false, false)]
    local procedure OnAfterValidate()
    begin
        Add('Row.OnAfterValidate');
    end;

    local procedure Add(EventName: Text)
    var
        Log: Record "LT TI Event Log";
    begin
        Log.Init();
        Log."Event Name" := CopyStr(EventName, 1, MaxStrLen(Log."Event Name"));
        Log.Insert();
    end;
}

// local object: subscribers to all ten table events of the platform table Company; no corpus test writes Company, so they run only in the probe
codeunit 73603 "LT TI Company Event Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeInsertEvent', '', false, false)]
    local procedure OnBeforeInsert()
    begin
        Add('Company.OnBeforeInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterInsertEvent', '', false, false)]
    local procedure OnAfterInsert()
    begin
        Add('Company.OnAfterInsert');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify()
    begin
        Add('Company.OnBeforeModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModify()
    begin
        Add('Company.OnAfterModify');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeDeleteEvent', '', false, false)]
    local procedure OnBeforeDelete()
    begin
        Add('Company.OnBeforeDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterDeleteEvent', '', false, false)]
    local procedure OnAfterDelete()
    begin
        Add('Company.OnAfterDelete');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeRenameEvent', '', false, false)]
    local procedure OnBeforeRename()
    begin
        Add('Company.OnBeforeRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterRenameEvent', '', false, false)]
    local procedure OnAfterRename()
    begin
        Add('Company.OnAfterRename');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeValidateEvent', 'Display Name', false, false)]
    local procedure OnBeforeValidate()
    begin
        Add('Company.OnBeforeValidate');
    end;

    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterValidateEvent', 'Display Name', false, false)]
    local procedure OnAfterValidate()
    begin
        Add('Company.OnAfterValidate');
    end;

    local procedure Add(EventName: Text)
    var
        Log: Record "LT TI Event Log";
    begin
        Log.Init();
        Log."Event Name" := CopyStr(EventName, 1, MaxStrLen(Log."Event Name"));
        Log.Insert();
    end;
}
