// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-trap-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT F3 Row / Log Mgt / Card / List / Dialog (F3Fixtures.al)
// Probe: (1) a TestPage variable trapped, its page run and left open; the next test of the same codeunit traps the same variable and runs the page again: does the second run open, and which close triggers run for the first page.
//        (2) Page.RunModal(Page, Rec, Rec.Field) with a handler that invokes OK, invokes Cancel, does nothing, or is Page-typed; for a card, a StandardDialog and a list in lookup mode: returned Action, the field afterwards, what the handler sees.
// Object ids 67091 - 67092.

codeunit 67091 "LT F3 Trapped Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        TrappedCard: TestPage "LT F3 Card";

    [Test]
    procedure Trapped_01_RunLeavesPageOpen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
    begin
        Log.Seed(3);
        Log.Clear();
        Row.Get('R1001');
        TrappedCard.Trap();
        Page.Run(Page::"LT F3 Card", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('no', TrappedCard.NoCtl.Value());
        Observer.Expect('log', 'Card.OnOpenPage(R1001) | ');
        Observer.Expect('no', 'R1001');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_02_SameVariableTrappedAgain()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
    begin
        Log.Seed(3);
        Log.Clear();
        Row.Get('R1002');
        TrappedCard.Trap();
        Page.Run(Page::"LT F3 Card", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('no', TrappedCard.NoCtl.Value());
        Observer.Expect('log', 'Card.OnQueryClosePage(OK) | Card.OnClosePage(R1001) | Card.OnOpenPage(R1002) | ');
        Observer.Expect('no', 'R1002');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_03_CloseTheVariable()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
    begin
        Log.Clear();
        TrappedCard.Close();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'Card.OnQueryClosePage(OK) | Card.OnClosePage(R1002) | ');
        Observer.Verify();
    end;

    [Test]
    procedure Trapped_04_RunAgainAfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT F3 Log Mgt";
        Row: Record "LT F3 Row";
    begin
        Log.Seed(3);
        Log.Clear();
        Row.Get('R1003');
        TrappedCard.Trap();
        Page.Run(Page::"LT F3 Card", Row);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', 'Card.OnOpenPage(R1003) | ');
        Observer.Verify();
    end;
}

codeunit 67092 "LT F3 RunModal Field"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        HandlerMode: Integer;

    [ModalPageHandler]
    procedure CardHandler(var P: TestPage "LT F3 Card")
    begin
        Observer.Observe('h_name', P.NameCtl.Value());
        case HandlerMode of
            0:
                begin
                    P.NameCtl.SetValue('Edited');
                    P.OK().Invoke();
                end;
            1:
                begin
                    P.NameCtl.SetValue('Edited');
                    P.Cancel().Invoke();
                end;
            2:
                P.NameCtl.SetValue('Edited');
        end;
    end;

    [ModalPageHandler]
    procedure CardPageHandler(var P: Page "LT F3 Card"; var Response: Action)
    begin
        Observer.Observe('h_page', 'called');
    end;

    [ModalPageHandler]
    procedure DialogHandler(var P: TestPage "LT F3 Dialog")
    begin
        Observer.Observe('h_name', P.NameCtl.Value());
        case HandlerMode of
            0:
                begin
                    P.NameCtl.SetValue('Edited');
                    P.OK().Invoke();
                end;
            1:
                begin
                    P.NameCtl.SetValue('Edited');
                    P.Cancel().Invoke();
                end;
            2:
                P.NameCtl.SetValue('Edited');
        end;
    end;

    [ModalPageHandler]
    procedure DialogPageHandler(var P: Page "LT F3 Dialog"; var Response: Action)
    begin
        Observer.Observe('h_page', 'called');
    end;

    [ModalPageHandler]
    procedure ListHandler(var P: TestPage "LT F3 List")
    begin
        Observer.Observe('h_name', P.NameCtl.Value());
        if P.GoToKey('R1002') then;
        Observer.Observe('h_after_goto', P.NameCtl.Value());
        case HandlerMode of
            0:
                P.OK().Invoke();
            1:
                P.Cancel().Invoke();
        end;
    end;

    [ModalPageHandler]
    procedure ListPageHandler(var P: Page "LT F3 List"; var Response: Action)
    begin
        Observer.Observe('h_page', 'called');
    end;

    [TryFunction]
    local procedure TryRunModal(PageId: Integer; var Row: Record "LT F3 Row"; var Result: Action)
    begin
        Result := Page.RunModal(PageId, Row, Row.Name);
    end;

    local procedure Run(PageId: Integer; Mode: Integer)
    var
        Row: Record "LT F3 Row";
        Log: Codeunit "LT F3 Log Mgt";
        Result: Action;
        Ok: Boolean;
    begin
        Log.Seed(3);
        HandlerMode := Mode;
        Row.Get('R1001');
        ClearLastError();
        Ok := TryRunModal(PageId, Row, Result);
        Observer.Observe('ok', Format(Ok));
        if not Ok then begin
            Observer.Observe('error', GetLastErrorText());
            Observer.Observe('code', GetLastErrorCode());
        end;
        Observer.Observe('action', Format(Result));
        Observer.Observe('row_no', Row."No.");
        Observer.Observe('row_name', Row.Name);
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_OK()
    begin
        Run(Page::"LT F3 Card", 0);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Edited');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_Cancel()
    begin
        Run(Page::"LT F3 Card", 1);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Edited');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_HandlerDoesNothing()
    begin
        Run(Page::"LT F3 Card", 3);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Name 1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure Card_HandlerEditsOnly()
    begin
        Run(Page::"LT F3 Card", 2);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Edited');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure Card_PageTypedHandler()
    begin
        Run(Page::"LT F3 Card", 3);
        Observer.Expect('h_page', 'called');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'None');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Name 1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_OK()
    begin
        Run(Page::"LT F3 Dialog", 0);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Edited');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_Cancel()
    begin
        Run(Page::"LT F3 Dialog", 1);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Edited');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogHandler')]
    procedure Dialog_HandlerDoesNothing()
    begin
        Run(Page::"LT F3 Dialog", 3);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Name 1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('DialogPageHandler')]
    procedure Dialog_PageTypedHandler()
    begin
        Run(Page::"LT F3 Dialog", 3);
        Observer.Expect('h_page', 'called');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'None');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Name 1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_OK()
    begin
        Run(Page::"LT F3 List", 0);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('h_after_goto', 'Name 2');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupOK');
        Observer.Expect('row_no', 'R1002');
        Observer.Expect('row_name', 'Name 2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_Cancel()
    begin
        Run(Page::"LT F3 List", 1);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('h_after_goto', 'Name 2');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1002');
        Observer.Expect('row_name', 'Name 2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListHandler')]
    procedure List_HandlerDoesNothing()
    begin
        Run(Page::"LT F3 List", 3);
        Observer.Expect('h_name', 'Name 1');
        Observer.Expect('h_after_goto', 'Name 2');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'LookupCancel');
        Observer.Expect('row_no', 'R1002');
        Observer.Expect('row_name', 'Name 2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ListPageHandler')]
    procedure List_PageTypedHandler()
    begin
        Run(Page::"LT F3 List", 3);
        Observer.Expect('h_page', 'called');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('action', 'None');
        Observer.Expect('row_no', 'R1001');
        Observer.Expect('row_name', 'Name 1');
        Observer.Verify();
    end;
}
