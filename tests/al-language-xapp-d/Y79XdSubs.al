// Cross-app fixture of writer Y79 (al-runner issues 6644 and 6755), app D (D sets no flags). Mirror in the other of B and D; see tests/al-language-xapp-a/Y79XaObjects.al.
// The subscribers and table extensions below note, while the hub of A is armed (an install code runs the probe), which install they ran in. The two
// platform events on the tables 61370 (per company) and 61371 (DataPerCompany = false) of A are noted in a test session too (the hub is not armed then,
// the note says '-').

tableextension 61391 "LT Y79 XD Reason Code Ext" extends "Reason Code"
{
    trigger OnBeforeInsert()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-rc-ext|' + Hub.Armed() + '|' + Rec.Code);
    end;
}

tableextension 61392 "LT Y79 XD Job Queue Ext" extends "Job Queue Entry"
{
    trigger OnBeforeInsert()
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-jqe-ext|' + Hub.Armed());
    end;
}

codeunit 61393 "LT Y79 XD Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(TableId) then
            exit;
        Hub.Note('D-setup|' + Hub.Where() + '|t=' + Format(TableId) + '|in=' + Format(OnDatabaseInsert) + Format(OnDatabaseModify) + Format(OnDatabaseDelete) + Format(OnDatabaseRename));

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('D-dbinsert|' + Hub.Where() + '|t=' + Format(RecRef.Number) + '|row=' + Format(RecRef.Field(1).Value));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetGlobalTableTriggerMask', '', false, false)]
    local procedure OnMask(TableID: Integer; var TableTriggerMask: Integer)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(TableID) then
            exit;
        Hub.Note('D-mask|' + Hub.Where() + '|t=' + Format(TableID) + '|in=' + Format(TableTriggerMask));

    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalInsert', '', false, false)]
    local procedure OnGlobalInsert(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('D-globalinsert|' + Hub.Where() + '|t=' + Format(RecRef.Number) + '|row=' + Format(RecRef.Field(1).Value));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalModify', '', false, false)]
    local procedure OnGlobalModify(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('D-globalmodify|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalDelete', '', false, false)]
    local procedure OnGlobalDelete(RecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('D-globaldelete|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnGlobalRename', '', false, false)]
    local procedure OnGlobalRename(RecRef: RecordRef; xRecRef: RecordRef)
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if not Watched(RecRef.Number) then
            exit;
        Hub.Note('D-globalrename|' + Hub.Where() + '|t=' + Format(RecRef.Number));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerCompanyUpgradeTags', '', false, false)]
    local procedure OnCompanyTags(var PerCompanyUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-tags-co|' + Hub.Armed());
        PerCompanyUpgradeTags.Add('LT-Y79-D');
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Upgrade Tag", 'OnGetPerDatabaseUpgradeTags', '', false, false)]
    local procedure OnDatabaseTags(var PerDatabaseUpgradeTags: List of [Code[250]])
    var
        Hub: Codeunit "LT Y79 XA Hub";
    begin
        if Hub.Armed() = '' then
            exit;
        Hub.Note('D-tags-db|' + Hub.Armed());
        PerDatabaseUpgradeTags.Add('LT-Y79-D');
    end;

    // The per-company table 61370 and the DataPerCompany = false table 61371 of A (by number: B and D have no dependency on each other).
    local procedure Watched(TableId: Integer): Boolean
    begin
        exit((TableId = 61370) or (TableId = 61371));
    end;
}
