// Cross-app fixture of writer Y69 (al-runner issue 6718 by SShadowS), app B (depends on A, not on D). Mirror of tests/al-language-xapp-d/Y69XdTriggerSubs.al:
// the table extension below writes B's own table 61358 with Insert(true) when a row is inserted into A's table 61180 while B is installed (B's install
// code writes row 20; D's row 10 too when B is installed first). The subscriber, in the form of the issue (TableId and three flags), watches A's table 61180 and D's
// table 61192 (by number: B has no dependency on D) and SETS OnDatabaseInsert for it. Notes 'Y69|B-setup|in=<flag>' and 'Y69|B-insert|row=<No.>' in table 61354
// of A (each noted once per distinct text). Test: tests/al-language/install/lt-y69-install-trigger-setup/Y69InstallTriggerSetup.al.

table 61358 "LT Y69 XB Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 61359 "LT Y69 XB Data Ext" extends "LT Y8 XA Data"
{
    trigger OnBeforeInsert()
    var
        Row: Record "LT Y69 XB Row";
    begin
        Row."No." := Rec."No.";
        if Row.Insert(true) then;
    end;
}

codeunit 61357 "LT Y69 XB Trigger Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if not Watched(TableId) then
            exit;
        Hub.Note('Y69|B-setup|t=' + Format(TableId) + '|in=' + Format(OnDatabaseInsert));
        OnDatabaseInsert := true;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('Y69|B-insert|t=' + Format(RecRef.Number) + '|row=' + Format(RecRef.Field(1).Value));
    end;

    // A's table 61180 (written by every install code) and D's table 61192.
    local procedure Watched(TableId: Integer): Boolean
    begin
        exit((TableId = Database::"LT Y8 XA Data") or (TableId = 61192));
    end;
}
