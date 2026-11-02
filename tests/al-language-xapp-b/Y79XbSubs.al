// Cross-app fixture of writer Y79 (al-runner issues 6644 and 6755), app B (B sets flags). Mirror in the other of B and D; see tests/al-language-xapp-a/Y79XaObjects.al.
// The subscribers and table extensions below note, while the hub of A is armed (an install code runs the probe), which install they ran in. The platform
// events on the tables 61370 (per company), 61371 and 61377-61379 (DataPerCompany = false) of A are noted in a test session too (the hub is not armed then,
// the note says '-'). B sets flags and mask bits (61370 and 61371: insert flag and mask 1; 61377: modify flag and mask 2; 61378: delete flag and mask 4;
// 61379: rename flag and mask 8); D only notes what it is given.

tableextension 61381 "LT Y79 XB Reason Code Ext" extends "Reason Code"
{
    trigger OnBeforeInsert()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('B-rc-ext|' + Hub.Armed() + '|' + Rec.Code);
    end;
}

tableextension 61382 "LT Y79 XB Job Queue Ext" extends "Job Queue Entry"
{
    trigger OnBeforeInsert()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('B-jqe-ext|' + Hub.Armed());
    end;
}

codeunit 61383 "LT Y79 XB Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(TableId) then
            exit;
        Hub.Note('B-setup|' + Hub.Where() + '|t=' + Format(TableId) + '|in=' + Format(OnDatabaseInsert) + Format(OnDatabaseModify) + Format(OnDatabaseDelete) + Format(OnDatabaseRename));
        case TableId of
            61370, 61371:
                OnDatabaseInsert := true;
            61377:
                OnDatabaseModify := true;
            61378:
                OnDatabaseDelete := true;
            61379:
                OnDatabaseRename := true;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-dbinsert|' + Hub.Where() + '|t=' + Format(RecRef.Number) + '|row=' + Format(RecRef.Field(1).Value));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseModify', '', false, false)]
    local procedure OnModify(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-dbmodify|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseDelete', '', false, false)]
    local procedure OnDelete(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-dbdelete|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseRename', '', false, false)]
    local procedure OnRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-dbrename|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure OnMask(TableID: Integer; var TableTriggerMask: Integer)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(TableID) then
            exit;
        Hub.Note('B-mask|' + Hub.Where() + '|t=' + Format(TableID) + '|in=' + Format(TableTriggerMask));
        case TableID of
            61370, 61371:
                TableTriggerMask := TableTriggerMask + 1;
            61377:
                TableTriggerMask := TableTriggerMask + 2;
            61378:
                TableTriggerMask := TableTriggerMask + 4;
            61379:
                TableTriggerMask := TableTriggerMask + 8;
        end;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-globalinsert|' + Hub.Where() + '|t=' + Format(RecRef.Number) + '|row=' + Format(RecRef.Field(1).Value));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-globalmodify|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-globaldelete|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('B-globalrename|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('B-tags-co|' + Hub.Armed());
        PerCompanyUpgradeTags.Add('LT-Y79-B');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('B-tags-db|' + Hub.Armed());
        PerDatabaseUpgradeTags.Add('LT-Y79-B');
    end;

    // The per-company table 61370 and the DataPerCompany = false table 61371 of A (by number: B and D have no dependency on each other).
    local procedure Watched(TableId: Integer): Boolean
    begin
        exit((TableId = 61370) or (TableId = 61371) or ((TableId >= 61377) and (TableId <= 61379)));
    end;
}
