// Two-top cross-app subscriber order probe (writer TT, al-runner 6924 waldo). Subscriber of app T, an app that depends on app N only and that no app depends on
// (a second top-level app): appends 'T;' to the Display Name of a temporary Company named 'LT TT ORDER'.
// Tests: tests/al-language/events/subscriber-order/TtSubscriberOrderTests.al.

codeunit 97815 "LT TT T Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT TT ORDER' then
            exit;
        Rec."Display Name" += 'T;';
    end;
}
