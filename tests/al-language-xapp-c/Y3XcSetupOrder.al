// Cross-app subscriber order probe (corpus writer Y3), see tests/al-language-xapp-a/Y3XaSetupOrder.al. XApp C has the lowest app id of the
// subscriber apps (0df0fadc-..., below Tests-TestLibraries 5d86850b-...). This file is why XApp C declares Base Application as a dependency
// (it needs the GlobalTriggerManagement codeunit of Base Application); it depended on Base Application through XApp A before.

table 61152 "LT Y3 XC Order Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 61153 "LT Y3 XC Setup Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Codeunit "LT Y3 XA Order Log Mgt";
    begin
        if TableId <> Database::"LT Y3 XC Order Row" then
            exit;
        Log.Add('C', OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;
}
