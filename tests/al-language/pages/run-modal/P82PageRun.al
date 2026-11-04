// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-run-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P82 Card (71187), LT P82 List (71188), LT P82 Item (71184), LT P82 Log (71186) from P82Fixtures.al
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: Page.Run / Page.RunModal overloads (number; number and record; number, record and field), the Action returned by RunModal, SetRecord, SetTableView, GetRecord, LookupMode of a Page variable
// BC versions: 29

codeunit 71200 "LT P82 Page Run"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P82 Log";

    local procedure Seed()
    var
        Item: Record "LT P82 Item";
    begin
        Item.DeleteAll();
        Log.Reset();
        Item."No." := 'A';
        Item.Name := 'Alpha';
        Item.Qty := 1;
        Item.Insert();
        Item."No." := 'B';
        Item.Name := 'Beta';
        Item.Qty := 2;
        Item.Insert();
        Item."No." := 'C';
        Item.Name := 'Gamma';
        Item.Qty := 3;
        Item.Insert();
    end;

    [ModalPageHandler]
    procedure CardOk(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        Observer.Observe('card-name', P.NameCtl.Value());
        Observer.Observe('card-editable', Format(P.Editable()));
        Observer.Observe('card-caption', P.Caption());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CardCancel(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        P.Cancel().Invoke();
    end;

    [ModalPageHandler]
    procedure CardActClose(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('card-no', P.NoCtl.Value());
        P.ActClose.Invoke();
    end;

    [ModalPageHandler]
    procedure ListOk(var P: TestPage "LT P82 List")
    begin
        Observer.Observe('list-no', P.NoCtl.Value());
        Observer.Observe('list-caption', P.Caption());
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListScan(var P: TestPage "LT P82 List")
    var
        N: Integer;
    begin
        if P.First() then
            repeat
                N += 1;
                Observer.Observe('row' + Format(N), P.NoCtl.Value());
            until not P.Next();
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListPickC(var P: TestPage "LT P82 List")
    begin
        P.GoToKey('C');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure ListClose(var P: TestPage "LT P82 List")
    begin
        P.ActClose.Invoke();
    end;

    [ModalPageHandler]
    procedure ListCancel(var P: TestPage "LT P82 List")
    begin
        P.Cancel().Invoke();
    end;

    [PageHandler]
    procedure CardPlain(var P: TestPage "LT P82 Card")
    begin
        Observer.Observe('plain-no', P.NoCtl.Value());
        Observer.Observe('plain-name', P.NameCtl.Value());
        Observer.Observe('plain-editable', Format(P.Editable()));
    end;

    [PageHandler]
    procedure ListPlain(var P: TestPage "LT P82 List")
    begin
        Observer.Observe('plain-no', P.NoCtl.Value());
        Observer.Observe('plain-rows', Format(P.First()));
    end;

    [Test]
    [HandlerFunctions('CardOk')]
    procedure RunModal_Number_OnCard()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 Card");
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('card-no', 'A');
        Observer.Expect('card-name', 'Alpha');
        Observer.Expect('card-editable', 'Yes');
        Observer.Expect('card-caption', 'LT P82 Card Caption - A');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardOk')]
    procedure RunModal_NumberAndRecord()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('card-no', 'B');
        Observer.Expect('card-name', 'Beta');
        Observer.Expect('card-editable', 'Yes');
        Observer.Expect('card-caption', 'LT P82 Card Caption - B');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(B);OnQueryClosePage(LookupOK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardCancel')]
    procedure RunModal_NumberAndRecord_Cancel()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('C');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('card-no', 'C');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(C);OnAfterGetRecord(C);OnQueryClosePage(LookupCancel);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardActClose')]
    procedure RunModal_CurrPageClose_Action()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('A');
        Result := Page.RunModal(Page::"LT P82 Card", Item);
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('card-no', 'A');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnAfterGetRecord(A);OnQueryClosePage(LookupCancel);OnClosePage;OnAfterGetRecord(A)');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListClose')]
    procedure RunModal_List_CurrPageClose_Action()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 List");
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('log', 'List OnOpenPage filter=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure RunModal_NumberRecordField()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('B');
        Result := Page.RunModal(Page::"LT P82 List", Item, Item.FieldNo(Name));
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('list-no', 'B');
        Observer.Expect('list-caption', 'LT P82 List Caption');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('log', 'List OnOpenPage filter=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure RunModal_NumberRecordField_NoFieldMatch()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.Get('C');
        Result := Page.RunModal(Page::"LT P82 List", Item, 0);
        Observer.Observe('action', Format(Result));
        Observer.Expect('list-no', 'C');
        Observer.Expect('list-caption', 'LT P82 List Caption');
        Observer.Expect('action', 'LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure RunModal_List_NoRecord_AllRows()
    var
        Result: Action;
    begin
        Seed();
        Result := Page.RunModal(Page::"LT P82 List");
        Observer.Observe('action', Format(Result));
        Observer.Expect('row1', 'A');
        Observer.Expect('row2', 'B');
        Observer.Expect('row3', 'C');
        Observer.Expect('action', 'LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure RunModal_List_RecordWithFilter_PassedFilterIgnored()
    var
        Item: Record "LT P82 Item";
        Result: Action;
    begin
        Seed();
        Item.SetFilter(Qty, '>=2');
        Item.FindFirst();
        Result := Page.RunModal(Page::"LT P82 List", Item);
        Observer.Observe('action', Format(Result));
        Observer.Expect('row1', 'B');
        Observer.Expect('row2', 'C');
        Observer.Expect('action', 'LookupOK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure PageVar_SetTableView_Filters()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Item.SetFilter(Qty, '>=2');
        Pg.SetTableView(Item);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('row1', 'B');
        Observer.Expect('row2', 'C');
        Observer.Expect('row3', '');
        Observer.Expect('action', 'OK');
        Observer.Expect('log', 'List OnOpenPage filter=Qty: >=2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListScan')]
    procedure PageVar_SetTableView_Sorting()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
    begin
        Seed();
        Item.SetCurrentKey(Qty);
        Item.Ascending(false);
        Pg.SetTableView(Item);
        Pg.RunModal();
        Observer.Expect('row1', 'C');
        Observer.Expect('row2', 'B');
        Observer.Expect('row3', 'A');
        Observer.Expect('row4', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListOk')]
    procedure PageVar_SetRecord_Positions()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 List";
    begin
        Seed();
        Item.Get('C');
        Pg.SetRecord(Item);
        Pg.RunModal();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('list-no', 'C');
        Observer.Expect('list-caption', 'LT P82 List Caption');
        Observer.Expect('log', 'List OnOpenPage filter=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPickC')]
    procedure PageVar_LookupMode_GetRecord()
    var
        Item: Record "LT P82 Item";
        Picked: Record "LT P82 Item";
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Observer.Observe('lookupmode-default', Format(Pg.LookupMode()));
        Pg.LookupMode(true);
        Observer.Observe('lookupmode-set', Format(Pg.LookupMode()));
        Item.Get('A');
        Pg.SetRecord(Item);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Pg.GetRecord(Picked);
        Observer.Observe('picked', Picked."No.");
        Observer.Observe('picked-name', Picked.Name);
        Observer.Observe('lookupmode-after', Format(Pg.LookupMode()));
        Observer.Expect('lookupmode-default', 'No');
        Observer.Expect('lookupmode-set', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('picked', 'C');
        Observer.Expect('picked-name', 'Gamma');
        Observer.Expect('lookupmode-after', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListCancel')]
    procedure PageVar_LookupMode_Cancel_Action()
    var
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Pg.LookupMode(true);
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Expect('action', 'LookupCancel');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPickC')]
    procedure PageVar_NotLookupMode_HandlerSees()
    var
        Pg: Page "LT P82 List";
        Result: Action;
    begin
        Seed();
        Result := Pg.RunModal();
        Observer.Observe('action', Format(Result));
        Observer.Expect('action', 'OK');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure Run_NumberAndRecord_Modeless()
    var
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('B');
        Page.Run(Page::"LT P82 Card", Item);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('plain-no', 'B');
        Observer.Expect('plain-name', 'Beta');
        Observer.Expect('plain-editable', 'Yes');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(B);OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure Run_Number_Modeless()
    begin
        Seed();
        Page.Run(Page::"LT P82 Card");
        Observer.Observe('log', Log.Dump());
        Observer.Expect('plain-no', 'A');
        Observer.Expect('plain-name', 'Alpha');
        Observer.Expect('plain-editable', 'Yes');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPlain')]
    procedure Run_NumberRecordField_Modeless()
    var
        Item: Record "LT P82 Item";
    begin
        Seed();
        Item.Get('C');
        Page.Run(Page::"LT P82 List", Item, Item.FieldNo(Qty));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('plain-no', 'C');
        Observer.Expect('plain-rows', 'Yes');
        Observer.Expect('log', 'List OnOpenPage filter=');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure PageVar_Run_AfterSetRecord()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 Card";
    begin
        Seed();
        Item.Get('A');
        Pg.SetRecord(Item);
        Pg.Run();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('plain-no', 'A');
        Observer.Expect('plain-name', 'Alpha');
        Observer.Expect('plain-editable', 'Yes');
        Observer.Expect('log', 'OnOpenPage;OnAfterGetRecord(A);OnQueryClosePage(OK);OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPlain')]
    procedure PageVar_Editable_BeforeRun()
    var
        Item: Record "LT P82 Item";
        Pg: Page "LT P82 Card";
    begin
        Seed();
        Item.Get('A');
        Pg.SetRecord(Item);
        Observer.Observe('editable-default', Format(Pg.Editable()));
        Pg.Editable(false);
        Observer.Observe('editable-after-set', Format(Pg.Editable()));
        Pg.Run();
        Observer.Expect('editable-default', 'Yes');
        Observer.Expect('editable-after-set', 'No');
        Observer.Expect('plain-no', 'A');
        Observer.Expect('plain-name', 'Alpha');
        Observer.Expect('plain-editable', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_UnknownPageNumber()
    begin
        asserterror Page.RunModal(71999);
        Observer.ObserveError('modal-unknown');
        asserterror Page.Run(71999);
        Observer.ObserveError('run-unknown');
        asserterror Page.RunModal(0);
        Observer.ObserveError('modal-zero');
        asserterror Page.Run(-1);
        Observer.ObserveError('run-negative');
        Observer.Expect('modal-unknown|text', 'You tried to invoke the Page object with the ID 71999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('modal-unknown|code', 'AL:MetadataNotFound');
        Observer.Expect('run-unknown|text', 'You tried to invoke the Page object with the ID 71999 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run-unknown|code', 'AL:MetadataNotFound');
        Observer.Expect('modal-zero|text', 'You tried to invoke the Page object with the ID 0 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('modal-zero|code', 'AL:MetadataNotFound');
        Observer.Expect('run-negative|text', 'You tried to invoke the Page object with the ID -1 from the object Test Runner - Mgt. An object with that ID does not exist in the current application compiled with emit version n.');
        Observer.Expect('run-negative|code', 'AL:MetadataNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure RunModal_WithoutHandler()
    var
        Result: Action;
    begin
        Seed();
        asserterror Result := Page.RunModal(Page::"LT P82 List");
        Observer.ObserveError('modal-no-handler');
        asserterror Page.Run(Page::"LT P82 Card");
        Observer.ObserveError('run-no-handler');
        Observer.Expect('modal-no-handler|text', 'Unhandled UI: ModalPage 71188');
        Observer.Expect('modal-no-handler|code', 'MissingUIHandler');
        Observer.Expect('run-no-handler|text', 'Unhandled UI: Page 71187');
        Observer.Expect('run-no-handler|code', 'MissingUIHandler');
        Observer.Verify();
    end;
}
