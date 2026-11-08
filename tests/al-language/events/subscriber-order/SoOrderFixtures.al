// Cross-app subscriber order probe (writer SO, al-runner 6924 waldo). Subscriber of this app (M) and the raisers for the three events; the
// subscribers of the other apps are tests/al-language-internals-fixture/SoXfOrder.al and tests/al-language-xapp-a|b|c|d/So*Order.al.

codeunit 96315 "LT SO M Subs"
{
    [EventSubscriber(ObjectType::Table, Database::Company, 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyCompany(var Rec: Record Company; var xRec: Record Company; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Name <> 'LT SO ORDER' then
            exit;
        Rec."Display Name" += 'M;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Reason Code", 'OnAfterModifyEvent', '', false, false)]
    local procedure OnAfterModifyReasonCode(var Rec: Record "Reason Code"; var xRec: Record "Reason Code"; RunTrigger: Boolean)
    begin
        if not Rec.IsTemporary() then
            exit;
        if Rec.Code <> 'LTSO' then
            exit;
        Rec.Description += 'M;';
    end;

    [EventSubscriber(ObjectType::Table, Database::"Sales Header", 'OnAfterCopyShipToCustomerAddressFieldsFromCustomer', '', false, false)]
    local procedure OnAfterCopyShipTo(var SalesHeader: Record "Sales Header"; SellToCustomer: Record Customer; xSalesHeader: Record "Sales Header")
    begin
        if not SalesHeader.IsTemporary() then
            exit;
        if SalesHeader."No." <> 'LTSO' then
            exit;
        SalesHeader."Ship-to Name 2" += 'M;';
    end;
}

codeunit 96316 "LT SO Raiser"
{
    procedure RaiseCompany(): Text
    var
        TempCompany: Record Company temporary;
    begin
        TempCompany.Init();
        TempCompany.Name := 'LT SO ORDER';
        TempCompany.Insert();
        TempCompany."Display Name" := '';
        TempCompany.Modify();
        exit(TempCompany."Display Name");
    end;

    procedure RaiseReasonCode(): Text
    var
        TempReason: Record "Reason Code" temporary;
    begin
        TempReason.Init();
        TempReason.Code := 'LTSO';
        TempReason.Description := '';
        TempReason.Insert();
        TempReason.Modify();
        exit(TempReason.Description);
    end;

    procedure RaiseShipTo(var Result: Text): Boolean
    begin
        exit(TryShipTo(Result));
    end;

    [TryFunction]
    local procedure TryShipTo(var Result: Text)
    var
        TempHeader: Record "Sales Header" temporary;
        TempCustomer: Record Customer temporary;
    begin
        TempCustomer.Init();
        TempCustomer."No." := 'LTSO';
        TempCustomer.Insert();
        TempHeader.Init();
        TempHeader."Document Type" := TempHeader."Document Type"::Order;
        TempHeader."No." := 'LTSO';
        TempHeader.Insert();
        TempHeader.CopyShipToCustomerAddressFieldsFromCust(TempCustomer);
        Result := TempHeader."Ship-to Name 2";
    end;
}
