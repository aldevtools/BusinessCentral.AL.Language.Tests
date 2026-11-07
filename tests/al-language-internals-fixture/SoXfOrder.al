// Cross-app subscriber order probe (writer SO, al-runner 6924 waldo: two apps without a dependency path between them, subscribing to the same
// table event; on BC the higher-id app ran first). Subscriber of app F: appends its tag 'F;' to a temporary record named 'LT SO ORDER'.
// Events: Company OnAfterModifyEvent (every app), Reason Code OnAfterModifyEvent and Sales Header
// OnAfterCopyShipToCustomerAddressFieldsFromCustomer (a Base Application table event and integration event; not in the fixture app, which has no
// dependency on Base Application). Tests: tests/al-language/events/subscriber-order/SoSubscriberOrderTests.al.

codeunit 96310 "LT SO F Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT SO ORDER' then
            exit;
        Rec."Display Name" += 'F;';
    end;
}
