// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (table 73057, pages 73069 card and 73070 list, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.RunModal (number, record), (number, record, field number), (number, record, field value), (number, record, FieldRef): result per response of a typed modal handler, record and field after LookupOK with SetRecord, Page.Activate inside the handler
// BC versions: 29 (27 and 28 by CI)

codeunit 73080 "LT P94 Page Modal"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";
        ResponseToGive: Action;
        PickId: Integer;
        Seen: Text;
        ActivateMode: Integer;

    [ModalPageHandler]
    procedure ListHandler(var P: Page "LT P94 List"; var Response: Action)
    var
        Row: Record "LT P94 Item";
    begin
        P.GetRecord(Row);
        Seen := 'record=' + Format(Row.Id) + ';lookup=' + Format(P.LookupMode()) + ';before=' + Format(Response);
        if PickId <> 0 then begin
            Row.Get(PickId);
            P.SetRecord(Row);
        end;
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure CardHandler(var P: Page "LT P94 Card"; var Response: Action)
    var
        Row: Record "LT P94 Item";
    begin
        P.GetRecord(Row);
        Seen := 'record=' + Format(Row.Id) + ';lookup=' + Format(P.LookupMode());
        Response := ResponseToGive;
    end;

    [ModalPageHandler]
    procedure ActivateHandler(var P: Page "LT P94 List"; var Response: Action)
    begin
        if ActivateMode = 1 then
            Seen := 'activate=' + Format(P.Activate())
        else
            Seen := 'activateRefresh=' + Format(P.Activate(true));
        Response := Action::Cancel;
    end;

    [TryFunction]
    local procedure TryModalFieldNo(PageNo: Integer; var Item: Record "LT P94 Item"; FieldNo: Integer; var Result: Action)
    begin
        Result := Page.RunModal(PageNo, Item, FieldNo);
    end;

    local procedure Responses(var R: array[8] of Action)
    begin
        R[1] := Action::OK;
        R[2] := Action::Cancel;
        R[3] := Action::LookupOK;
        R[4] := Action::LookupCancel;
        R[5] := Action::Yes;
        R[6] := Action::No;
        R[7] := Action::RunObject;
        R[8] := Action::RunSystem;
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_RecordOnly_EachResponse()
    var
        Item: Record "LT P94 Item";
        R: array[8] of Action;
        Result: Action;
        i: Integer;
    begin
        Helper.Wipe();
        Helper.Seed();
        Responses(R);
        PickId := 0;
        Item.Get(2);
        for i := 1 to 8 do begin
            ResponseToGive := R[i];
            Result := Page.RunModal(Page::"LT P94 List", Item);
            Observer.Observe('r' + Format(i), Format(Result));
        end;
        Observer.Observe('seen', Seen);
        Observer.Expect('r1', 'OK');
        Observer.Expect('r2', 'Cancel');
        Observer.Expect('r3', 'LookupOK');
        Observer.Expect('r4', 'LookupCancel');
        Observer.Expect('r5', 'Yes');
        Observer.Expect('r6', 'No');
        Observer.Expect('r7', 'RunObject');
        Observer.Expect('r8', 'RunSystem');
        Observer.Expect('seen', 'record=2;lookup=Yes;before=None');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldNo_EachResponse()
    var
        Item: Record "LT P94 Item";
        R: array[8] of Action;
        Result: Action;
        i: Integer;
    begin
        Helper.Wipe();
        Helper.Seed();
        Responses(R);
        PickId := 0;
        Item.Get(2);
        for i := 1 to 8 do begin
            ResponseToGive := R[i];
            Result := Page.RunModal(Page::"LT P94 List", Item, Item.FieldNo(Name));
            Observer.Observe('r' + Format(i), Format(Result));
        end;
        Observer.Observe('seen', Seen);
        Observer.Observe('nameAfter', Item.Name);
        Observer.Expect('r1', 'OK');
        Observer.Expect('r2', 'Cancel');
        Observer.Expect('r3', 'LookupOK');
        Observer.Expect('r4', 'LookupCancel');
        Observer.Expect('r5', 'Yes');
        Observer.Expect('r6', 'No');
        Observer.Expect('r7', 'RunObject');
        Observer.Expect('r8', 'RunSystem');
        Observer.Expect('seen', 'record=2;lookup=Yes;before=None');
        Observer.Expect('nameAfter', 'Beta');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldNo_LookupOKPicksRow()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        PickId := 3;
        ResponseToGive := Action::LookupOK;
        Item.Get(1);
        Result := Page.RunModal(Page::"LT P94 List", Item, Item.FieldNo(Name));
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Observe('id', Format(Item.Id));
        Observer.Observe('name', Item.Name);
        Observer.Observe('qty', Format(Item.Qty));
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'record=1;lookup=Yes;before=None');
        Observer.Expect('id', '3');
        Observer.Expect('name', 'Gamma');
        Observer.Expect('qty', '30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldNo_CancelKeepsRow()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        PickId := 3;
        ResponseToGive := Action::LookupCancel;
        Item.Get(1);
        Result := Page.RunModal(Page::"LT P94 List", Item, Item.FieldNo(Name));
        Observer.Observe('result', Format(Result));
        Observer.Observe('id', Format(Item.Id));
        Observer.Observe('name', Item.Name);
        Observer.Expect('result', 'LookupCancel');
        Observer.Expect('id', '3');
        Observer.Expect('name', 'Gamma');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldValue_LookupOKPicksRow()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        PickId := 3;
        ResponseToGive := Action::LookupOK;
        Item.Get(1);
        Result := Page.RunModal(Page::"LT P94 List", Item, Item.Name);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Observe('id', Format(Item.Id));
        Observer.Observe('name', Item.Name);
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'record=1;lookup=Yes;before=None');
        Observer.Expect('id', '3');
        Observer.Expect('name', 'Gamma');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldRef_LookupOKPicksRow()
    var
        Item: Record "LT P94 Item";
        RecRef: RecordRef;
        FRef: FieldRef;
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        PickId := 3;
        ResponseToGive := Action::LookupOK;
        Item.Get(1);
        RecRef.GetTable(Item);
        FRef := RecRef.Field(Item.FieldNo(Name));
        Result := Page.RunModal(Page::"LT P94 List", Item, FRef);
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Observe('fieldValue', Format(FRef.Value()));
        Observer.Observe('itemName', Item.Name);
        Observer.Observe('itemId', Format(Item.Id));
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('seen', 'record=1;lookup=Yes;before=None');
        Observer.Expect('fieldValue', 'Alpha');
        Observer.Expect('itemName', 'Gamma');
        Observer.Expect('itemId', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure RunModal_FieldRef_EachResponse()
    var
        Item: Record "LT P94 Item";
        RecRef: RecordRef;
        FRef: FieldRef;
        R: array[8] of Action;
        Result: Action;
        i: Integer;
    begin
        Helper.Wipe();
        Helper.Seed();
        Responses(R);
        PickId := 0;
        Item.Get(2);
        RecRef.GetTable(Item);
        FRef := RecRef.Field(Item.FieldNo(Name));
        for i := 1 to 8 do begin
            ResponseToGive := R[i];
            Result := Page.RunModal(Page::"LT P94 List", Item, FRef);
            Observer.Observe('r' + Format(i), Format(Result));
        end;
        Observer.Expect('r1', 'OK');
        Observer.Expect('r2', 'Cancel');
        Observer.Expect('r3', 'LookupOK');
        Observer.Expect('r4', 'LookupCancel');
        Observer.Expect('r5', 'Yes');
        Observer.Expect('r6', 'No');
        Observer.Expect('r7', 'RunObject');
        Observer.Expect('r8', 'RunSystem');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure RunModal_Card_FieldNo()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        ResponseToGive := Action::OK;
        Item.Get(2);
        Result := Page.RunModal(Page::"LT P94 Card", Item, Item.FieldNo(Qty));
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        ResponseToGive := Action::Cancel;
        Result := Page.RunModal(Page::"LT P94 Card", Item, Item.FieldNo(Qty));
        Observer.Observe('resultCancel', Format(Result));
        Observer.Expect('result', 'OK');
        Observer.Expect('seen', 'record=2;lookup=Yes');
        Observer.Expect('resultCancel', 'Cancel');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_FieldNoZeroAndUnknown()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        PickId := 0;
        ResponseToGive := Action::LookupOK;
        Item.Get(2);
        if TryModalFieldNo(Page::"LT P94 List", Item, 0, Result) then
            Observer.Observe('zero', Format(Result))
        else
            Observer.Observe('zero', Helper.ErrText());
        if TryModalFieldNo(Page::"LT P94 List", Item, 999, Result) then
            Observer.Observe('unknown', Format(Result))
        else
            Observer.Observe('unknown', Helper.ErrText());
        Observer.Expect('zero', 'error:Unhandled UI: ModalPage 73070|MissingUIHandler');
        Observer.Expect('unknown', 'error:The supplied field number ''999'' cannot be found in the ''LT P94 Item'' table.|FieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_UnknownPage()
    var
        Item: Record "LT P94 Item";
        Result: Action;
    begin
        if TryModalFieldNo(73999, Item, 1, Result) then
            Observer.Observe('missing', Format(Result))
        else
            Observer.Observe('missing', Helper.ErrText());
        Observer.Expect('missing', 'error:You tried to invoke the Page object with the ID 73999 from the object LT P94 Page Modal. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ActivateHandler')]
    procedure Activate_InsideModalHandler()
    var
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        ActivateMode := 1;
        Seen := '';
        Result := Page.RunModal(Page::"LT P94 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'Cancel');
        Observer.Expect('seen', 'activate=Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ActivateHandler')]
    procedure Activate_InsideModalHandlerRefresh()
    var
        Result: Action;
    begin
        Helper.Wipe();
        Helper.Seed();
        ActivateMode := 2;
        Seen := '';
        Result := Page.RunModal(Page::"LT P94 List");
        Observer.Observe('result', Format(Result));
        Observer.Observe('seen', Seen);
        Observer.Expect('result', 'Cancel');
        Observer.Expect('seen', 'activateRefresh=Yes');
        Observer.Verify();
    end;
}
