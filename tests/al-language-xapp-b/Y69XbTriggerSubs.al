// Cross-app fixture of writer Y69 (al-runner issue 6718 by SShadowS), app B (depends on A, not on D). A subscriber to the platform event
// "Global Triggers".GetDatabaseTableTriggerSetup in the form of the issue (TableId and three flags) that SETS OnDatabaseInsert for fixture A's table 61180
// (written by the install code of A, D and B). D's subscriber (tests/al-language-xapp-d/Y69XdTriggerSubs.al) leaves every flag alone. Notes
// 'Y69|B-setup' (once) in table 61354 of A. Test: tests/al-language/install/lt-y69-install-trigger-setup/Y69InstallTriggerSetup.al.

codeunit 61357 "LT Y69 XB Trigger Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if TableId <> Database::"LT Y8 XA Data" then
            exit;
        Hub.Note('Y69|B-setup');
        OnDatabaseInsert := true;
    end;
}
