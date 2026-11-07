// Two-top cross-app subscriber order probe (writer TT, al-runner 6924 waldo). Subscriber of app N, an app without dependencies that only
// app T depends on: appends 'N;' to the Display Name of a temporary Company named 'LT TT ORDER'.
// Tests: tests/al-language/events/subscriber-order/TtSubscriberOrderTests.al.

codeunit 97810 "LT TT N Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT TT ORDER' then
            exit;
        Rec."Display Name" += 'N;';
    end;
}
