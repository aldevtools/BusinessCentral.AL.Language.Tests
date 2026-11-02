// Cross-app fixture of writer Y69 (al-runner issue 6718 by SShadowS), app D (depends on A, not on B). Subscribers to the platform events
// "Global Triggers".GetDatabaseTableTriggerSetup and OnDatabaseInsert that watch only fixture A's table 61180 (the table the install code of A, D and B
// writes with Insert(true), tests/al-language-xapp-a/Y8XaInstallOrder.al). D's setup subscriber never changes a flag. Each call notes
// 'Y69|<n>|D-setup|in=<flags>' or 'Y69|<n>|D-insert|row=<No.>' in table 61354 of A (Hub.Note, `Insert()` without triggers, so the note itself asks for no
// trigger setup). Test: tests/al-language/install/lt-y69-install-trigger-setup/Y69InstallTriggerSetup.al. Nothing else is noted.

codeunit 61191 "LT Y69 XD Trigger Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'GetDatabaseTableTriggerSetup', '', false, false)]
    local procedure OnSetup(TableId: Integer; var OnDatabaseInsert: Boolean; var OnDatabaseModify: Boolean; var OnDatabaseDelete: Boolean; var OnDatabaseRename: Boolean)
    begin
        if TableId <> Database::"LT Y8 XA Data" then
            exit;
        Note('D-setup|in=' + Format(OnDatabaseInsert) + Format(OnDatabaseModify) + Format(OnDatabaseDelete) + Format(OnDatabaseRename));
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Global Triggers", 'OnDatabaseInsert', '', false, false)]
    local procedure OnInsert(RecRef: RecordRef)
    begin
        if RecRef.Number <> Database::"LT Y8 XA Data" then
            exit;
        Note('D-insert|row=' + Format(RecRef.Field(1).Value));
    end;

    local procedure Note(Detail: Text)
    var
        Hub: Codeunit "LT Y64 XA Install Hub";
        Row: Record "LT Y64 XA Install Subs";
        Next: Integer;
    begin
        Row.SetFilter(Tag, 'Y69|*');
        Next := Row.Count() + 1;
        Hub.Note('Y69|' + CopyStr(Format(100 + Next), 2) + '|' + Detail);
    end;
}
