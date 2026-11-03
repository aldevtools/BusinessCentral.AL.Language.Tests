// Cross-app subscriber order probe (corpus writer Y3), second form: see tests/al-language-testlibraries/lt-y3-setup-order/Y3SetupOrderTests.al.
// The main test app (a1b2c3d4-..., app id below Tests-TestLibraries 5d86850b-...) subscribes for table 90828 next to XApp D
// (tests/al-language-xapp-d/Y3XdSetupOrder.al); no dependency path joins the two apps. Tests-TestLibraries codeunit 130011 ASSIGNS all four flags
// true for a table id in 1..99999 when a company is open (BackupStorage.GetDatabaseTableTriggerSetup), so a subscriber that runs after it sees Yes.
// The OnAfterOnDatabaseInsert subscriber logs 'Final' when the flags the platform kept had OnDatabaseInsert true: it shows whether 130011 took part.

table 90828 "LT Y3 M Order Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 90829 "LT Y3 M Setup Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterGetDatabaseTableTriggerSetup', '', false, false)]
    local procedure AfterSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Log: Codeunit "LT Y3 XA Order Log Mgt";
    begin
        if TableId <> Database::"LT Y3 M Order Row" then
            exit;
        Log.Add('M', OnDatabaseInsert, OnDatabaseModify, OnDatabaseDelete, OnDatabaseRename);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::GlobalTriggerManagement, 'OnAfterOnDatabaseInsert', '', false, false)]
    local procedure AfterDbInsert(RecRef: RecordRef)
    var
        Log: Codeunit "LT Y3 XA Order Log Mgt";
    begin
        if RecRef.Number <> Database::"LT Y3 M Order Row" then
            exit;
        Log.Add('Final', true, false, false, false);
    end;
}
