// Fixtures for "LT CK Event Leads" (84712), corpus issue 669 item 4: SkipOnMissingPermission on a subscriber codeunit the
// effective permission sets do not grant Execute on. The test narrows the sets to the shared fixture set ALTPermissionSet (60022),
// which grants table data only (no codeunit). No permission set of its own: a new permission set makes CI run the whole corpus.

codeunit 84710 "LT CK Ev Perm Sub Strict"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnPerm', '', false, false)]
    local procedure OnPerm(var X: Integer)
    begin
        X := X + 10;
    end;
}

codeunit 84711 "LT CK Ev Perm Sub Skip"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT CK Ev Pub", 'OnPerm', '', true, true)]
    local procedure OnPerm(var X: Integer)
    begin
        X := X + 100;
    end;
}
