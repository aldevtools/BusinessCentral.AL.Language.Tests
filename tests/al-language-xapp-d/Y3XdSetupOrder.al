// Cross-app subscriber order probe (corpus writer Y3), second form: see tests/al-language-testlibraries/lt-y3-setup-order/Y3SetupOrderTests.al.
// XApp D (e92be076-..., app id above Tests-TestLibraries 5d86850b-...) and the main test app (a1b2c3d4-..., below it) have no dependency path
// between them. Both subscribe to OnAfterGetDatabaseTableTriggerSetup for main-app table 90828 and log the flags they receive. This file is why
// XApp D declares Base Application as a dependency (it needs the GlobalTriggerManagement codeunit).

codeunit 61163 "LT Y3 XD Setup Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Codeunit "LT Y3 XA Order Log Mgt";
    begin
        if TableId <> 90828 then
            exit;
        Log.Add('D', OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;
}
