// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-data-type
// Scope: in-scope
// Fixtures used: P94Fixtures.al (table 73057, pages 73069 card and 73070 list, helper 73071), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Page.Run (number, record, field number / field value) with page handlers, Page.RunModal (number, record, field number / field value / FieldRef) with typed modal handlers and every Action as response, Page.Activate
// Skipped (runtime 17 and later): the overloads with a fully qualified name.
// BC versions: 29 (27 and 28 by CI)

codeunit 73079 "LT P94 Page Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P94 Helper";
        Seen: Text;

    [PageHandler]
    procedure CardHandler(var P: TestPage "LT P94 Card")
    begin
        Seen := 'id=' + P.Id.Value() + ';name=' + P.Name.Value() + ';qty=' + P.Qty.Value();
    end;

    [PageHandler]
    procedure ListHandler(var P: TestPage "LT P94 List")
    begin
        Seen := 'first:id=' + P.Id.Value() + ';name=' + P.Name.Value();
        if P.Next() then
            Seen += '|second:id=' + P.Id.Value();
    end;

    [TryFunction]
    local procedure TryRunFieldNo(PageNo: Integer; var Item: Record "LT P94 Item"; FieldNo: Integer)
    begin
        Page.Run(PageNo, Item, FieldNo);
    end;

    [TryFunction]
    local procedure TryRunNumber(PageNo: Integer)
    begin
        Page.Run(PageNo);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Run_NumberOnly()
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Page.Run(Page::"LT P94 Card");
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'id=1;name=Alpha;qty=10');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Run_WithRecord()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.Get(2);
        Page.Run(Page::"LT P94 Card", Item);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'id=2;name=Beta;qty=20');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Run_WithRecordNotInTable()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.Id := 99;
        Item.Name := 'Ghost';
        Page.Run(Page::"LT P94 Card", Item);
        Observer.Observe('seen', Seen);
        Observer.Observe('items', Format(Helper.CountItems()));
        Observer.Expect('seen', 'id=3;name=Gamma;qty=30');
        Observer.Expect('items', '3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Run_WithRecordAndFieldNo()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.Get(3);
        Page.Run(Page::"LT P94 Card", Item, Item.FieldNo(Name));
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'id=3;name=Gamma;qty=30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Run_WithRecordAndFieldValue()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.Get(3);
        Page.Run(Page::"LT P94 Card", Item, Item.Name);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'id=3;name=Gamma;qty=30');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Run_ListNoRecord()
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Page.Run(Page::"LT P94 List");
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'first:id=1;name=Alpha|second:id=2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Run_ListWithFilteredRecord()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.SetFilter(Id, '>=2');
        Page.Run(Page::"LT P94 List", Item);
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'first:id=2;name=Beta|second:id=3');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure Run_ListWithRecordAndFieldNo()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Seen := '';
        Item.Get(2);
        Page.Run(Page::"LT P94 List", Item, Item.FieldNo(Qty));
        Observer.Observe('seen', Seen);
        Observer.Expect('seen', 'first:id=2;name=Beta|second:id=3');
        Observer.Verify();
    end;

    [Test]
    procedure Run_FieldNoZeroAndUnknown()
    var
        Item: Record "LT P94 Item";
    begin
        Helper.Wipe();
        Helper.Seed();
        Item.Get(1);
        if TryRunFieldNo(Page::"LT P94 Card", Item, 0) then
            Observer.Observe('zero', 'ok')
        else
            Observer.Observe('zero', Helper.ErrText());
        if TryRunFieldNo(Page::"LT P94 Card", Item, 999) then
            Observer.Observe('unknown', 'ok')
        else
            Observer.Observe('unknown', Helper.ErrText());
        if TryRunFieldNo(Page::"LT P94 Card", Item, -1) then
            Observer.Observe('negative', 'ok')
        else
            Observer.Observe('negative', Helper.ErrText());
        Observer.Expect('zero', 'error:Unhandled UI: Page 73069|MissingUIHandler');
        Observer.Expect('unknown', 'error:The supplied field number ''999'' cannot be found in the ''LT P94 Item'' table.|FieldNotFound');
        Observer.Expect('negative', 'error:Unhandled UI: Page 73069|MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Run_UnknownPage()
    begin
        if TryRunNumber(73999) then
            Observer.Observe('missing', 'ok')
        else
            Observer.Observe('missing', Helper.ErrText());
        if TryRunNumber(0) then
            Observer.Observe('zero', 'ok')
        else
            Observer.Observe('zero', Helper.ErrText());
        if TryRunNumber(-5) then
            Observer.Observe('negative', 'ok')
        else
            Observer.Observe('negative', Helper.ErrText());
        Observer.Expect('missing', 'error:You tried to invoke the Page object with the ID 73999 from the object LT P94 Page Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('zero', 'error:You tried to invoke the Page object with the ID 0 from the object LT P94 Page Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Expect('negative', 'error:You tried to invoke the Page object with the ID -5 from the object LT P94 Page Run. An object with that ID does not exist in the current application compiled with emit version n.|AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Run_UnknownPageWithoutTry()
    begin
        asserterror Page.Run(73999);
        Observer.ObserveError('missing');
        Observer.Expect('missing|text', 'You tried to invoke the Page object with the ID 73999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('missing|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Activate_PageNotRunning()
    var
        P: Page "LT P94 Card";
    begin
        P.Activate();
        Observer.Observe('activate', 'no error');
        Observer.Expect('activate', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Activate_PageNotRunningRefresh()
    var
        P: Page "LT P94 Card";
    begin
        P.Activate(true);
        Observer.Observe('activateRefresh', 'no error');
        Observer.Expect('activateRefresh', 'no error');
        Observer.Verify();
    end;
}
