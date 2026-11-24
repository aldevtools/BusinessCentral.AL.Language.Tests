// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: none (objects of this folder only)
// Probe (al-runner issue 8238): objects for tests/al-language/record/table-events-reads/TiReadEventTests.al and TiCompanyReadEventTests.al.
//   A table with subscribers to all ten table events (Before and After of Insert, Modify, Delete, Rename and Validate of field Description),
//   and subscribers to the same ten events of the platform table Company (Validate of field "Display Name"). Every subscriber adds its event name
//   to an in-memory SingleInstance log (73601 for the row table, 73607 for Company) and never fails. A first version wrote a log table; its
//   Company subscriber broke the app install on BC 28.5: install code raises OnBeforeInsertEvent of Company (on a temporary record) inside
//   OnInstallAppPerCompany, where a database write is not allowed.
// BC versions: 27 - 29

// local object: the row table whose reads the tests run; its ten table events log to codeunit 73601
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

// local object: the in-memory log of the row subscribers (no database write: a subscriber that writes fails when the event is raised inside install code)
// singleinstance-shared-on-purpose: written by the subscribers of codeunit 73602, read by the one test codeunit 73604
codeunit 73601 "LT TI Row Event Log"
{
    SingleInstance = true;

    var
        Names: List of [Text];

    procedure Add(EventName: Text)
    begin
        Names.Add(EventName);
    end;

    // The names added since the last call, then empties the log.
    procedure Take(): Text
    var
        Name: Text;
        Result: Text;
    begin
        foreach Name in Names do begin
            if Result <> '' then
                Result += ',';
            Result += Name;
        end;
        Clear(Names);
        exit('[' + Result + ']');
    end;
}

// local object: the in-memory log of the Company subscribers (no database write: install code of other apps raises Company events on a temporary record)
// singleinstance-shared-on-purpose: written by the subscribers of codeunit 73603, read by the one test codeunit 73605
codeunit 73607 "LT TI Company Event Log"
{
    SingleInstance = true;

    var
        Names: List of [Text];

    procedure Add(EventName: Text)
    begin
        Names.Add(EventName);
    end;

    // The names added since the last call, then empties the log.
    procedure Take(): Text
    var
        Name: Text;
        Result: Text;
    begin
        foreach Name in Names do begin
            if Result <> '' then
                Result += ',';
            Result += Name;
        end;
        Clear(Names);
        exit('[' + Result + ']');
    end;
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
        Log: Codeunit "LT TI Row Event Log";
    begin
        Log.Add(EventName);
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
        Log: Codeunit "LT TI Company Event Log";
    begin
        Log.Add(EventName);
    end;
}
