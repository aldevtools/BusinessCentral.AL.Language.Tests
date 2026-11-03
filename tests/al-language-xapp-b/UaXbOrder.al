// Cross-app subscriber order probe (writer UA, al-runner NP Retail install refusal on OnAfterGetDatabaseTableTriggerSetup): a platform
// table event (Company OnBeforeModifyEvent) with two subscribers in each of six apps, among them apps that do not depend on each other.
// Each subscriber appends its tag to "Display Name" of a temporary Company record named 'LT UA ORDER' and does nothing for any
// other record. Tests: tests/al-language/events/lt-bw-subscriber-order/BwSubscriberOrderTests.al (writer UA).

codeunit 61118 "LT UA XB Subs 1"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT UA ORDER' then
            exit;
        Rec."Display Name" += 'B1;';
    end;
}

codeunit 61146 "LT UA XB Subs 2"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT UA ORDER' then
            exit;
        Rec."Display Name" += 'B2;';
    end;
}
