// Cross-app subscriber order probe (writer SO, al-runner 6924 waldo: two apps without a dependency path between them, subscribing to the same
// table event; on BC the higher-id app ran first). Subscriber of app A: appends its tag 'A;' to a temporary record named 'LT SO ORDER'.
// Events: Company OnAfterModifyEvent (every app), Reason Code OnAfterModifyEvent and Sales Header
// OnAfterCopyShipToCustomerAddressFieldsFromCustomer (a Base Application table event and integration event; not in the fixture app, which has no
// dependency on Base Application). Tests: tests/al-language/events/subscriber-order/SoSubscriberOrderTests.al.

codeunit 96290 "LT SO A Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT SO ORDER' then
            exit;
        Rec."Display Name" += 'A;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reason Code", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyReasonCode(var Rec: Record "Reason Code"; var xRec: Record "Reason Code"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Code <> 'LTSO' then
            exit;
        Rec.Description += 'A;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure OnAfterCopyShipTo(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; xSalesHeader: Record "Sales Header")
    begin
        if not SalesHeader.IsTemporary() then
            exit;
        if SalesHeader."No." <> 'LTSO' then
            exit;
        SalesHeader."Ship-to Name 2" += 'A;';
    end;
}
