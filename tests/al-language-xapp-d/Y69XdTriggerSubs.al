// Cross-app fixture of writer Y69 (al-runner issue 6718 by SShadowS), app D (depends on A, not on B). The install code of D writes row 10 of A's table
// 61180 with Insert(true) (tests/al-language-xapp-a/Y8XaInstallOrder.al); the table extension below runs when a row is inserted into 61180 while D is
// installed and then writes the same number to D's own table 61192 with Insert(true), so the first write to 61192 happens inside an install.
// App B has the mirror (tests/al-language-xapp-b/Y69XbTriggerSubs.al: table 61358, extension 61359). The subscriber below watches B's table 61358 (by
// number: D has no dependency on B) through the platform events "Global Triggers".GetDatabaseTableTriggerSetup and OnDatabaseInsert; it never changes a
// flag. It notes 'Y69|<n>|D-setup|in=<flags>' or 'Y69|<n>|D-insert|row=<No.>' in table 61354 of A (Hub.Note, `Insert()` without triggers, so the note asks for no
// trigger setup). Test: tests/al-language/install/lt-y69-install-trigger-setup/Y69InstallTriggerSetup.al.

table 61192 "LT Y69 XD Row"
{
    DataClassification = SystemMetadata;
    DataPerCompany = false;

    fields
    {
        field(1; "No."; Integer) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 61193 "LT Y69 XD Data Ext" extends "LT Y8 XA Data"
{
    trigger OnBeforeInsert()
    var
        Row: Record "LT Y69 XD Row";
    begin
        Row."No." := Rec."No.";
        if Row.Insert(true) then;
    end;
}

codeunit 61191 "LT Y69 XD Trigger Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId <> 61358 then
            exit;
        Note('D-setup|in=' + Format(OnDatabaseInsert) + Format(OnDatabaseModify) + Format(OnDatabaseDelete) + Format(OnDatabaseRename));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    begin
        if RecRef.Number <> 61358 then
            exit;
        Note('D-insert|row=' + Format(RecRef.Field(1).Value));
    end;

    local procedure Note(Detail: Text)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
        Row: Record "LT Y64 XA Install Subs";
        Next: Integer;
    begin
        Next := 1;
        if Row.FindSet() then
            repeat
                if Row.Tag.StartsWith('Y69|') then
                    Next += 1;
            until Row.Next() = 0;
        Hub.Note('Y69|' + CopyStr(Format(100 + Next), 2) + '|' + Detail);
    end;
}
