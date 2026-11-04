// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-savevalues-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT PnG Card (70134), LT PnG Save Card (70144), LT PnG Save Dialog (70145), LT PnG Boom List (70146), LT PnG Item (70130), LT PnG Log (70133)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed.md rows 62 (a non-modal [PageHandler] page is closed when the handler returns: OnQueryClosePage/OnClosePage run, SaveValues stores), 63 (SaveValues restores values after OnInit and before OnOpenPage; TestPage.Close() on a non-dialog and a platform close store them) and 64 (a handler that tears its page down leaves a non-lookup RunModal reporting Cancel)
// Facts: trigger log of a page opened by Page.Run with a [PageHandler], values seen in OnInit/OnOpenPage/OnClosePage of a SaveValues page, the Action returned by RunModal after a teardown inside the handler
// BC versions: 29 (27 and 28 by CI)

codeunit 70179 "LT PnG Page Close"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Mode: Integer;
        HandlerCalls: Integer;
        Seen: Text;

    local procedure SeedOne()
    var
        Item: Record "LT PnG Item";
    begin
        Item.DeleteAll();
        Item."No." := 'C1';
        Item.Name := 'Close One';
        Item.Insert();
    end;

    local procedure ResetSaved()
    var
        Log: Codeunit "LT PnG Log";
        Pg: TestPage "LT PnG Save Card";
    begin
        Log.SetFlag('SaveCardOnInitSets', false);
        Pg.OpenEdit();
        Pg.TxtCtl.SetValue('');
        Pg.IntCtl.SetValue(0);
        Pg.Close();
        Mode := 0;
        Log.Reset();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure NonModalPageHandlerCloseTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        SeedOne();
        Item.Get('C1');
        Log.Reset();
        Mode := 1;
        HandlerCalls := 0;
        Page.Run(Page::"LT PnG Card", Item);
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('calls', '1');
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(C1,Close One);Card.AGCR(C1,Close One);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure NonModalPageHandlerEditThenReturn()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        SeedOne();
        Item.Get('C1');
        Log.Reset();
        Mode := 2;
        HandlerCalls := 0;
        Page.Run(Page::"LT PnG Card", Item);
        Item.Get('C1');
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('stored-name', Item.Name);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('calls', '1');
        Observer.Expect('stored-name', 'Edited in handler');
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(C1,Close One);Card.AGCR(C1,Close One);TblVal(C1,Edited in handler);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CardHandler')]
    procedure NonModalPageHandlerCloseInHandler()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Item: Record "LT PnG Item";
    begin
        SeedOne();
        Item.Get('C1');
        Log.Reset();
        Mode := 3;
        HandlerCalls := 0;
        Page.Run(Page::"LT PnG Card", Item);
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Observe('log', Log.Dump());
        Observer.Expect('calls', '1');
        Observer.Expect('log', 'Card.OnInit;Card.OnOpenPage;Card.AGR(C1,Close One);Card.AGCR(C1,Close One);Card.OnQueryClosePage;Card.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    procedure SaveValuesTestPageCloseThenReopen()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Pg: TestPage "LT PnG Save Card";
    begin
        ResetSaved();
        Pg.OpenEdit();
        Observer.Observe('first-open-log', Log.Dump());
        Pg.TxtCtl.SetValue('stored text');
        Pg.IntCtl.SetValue(42);
        Log.Reset();
        Pg.Close();
        Observer.Observe('close-log', Log.Dump());
        Log.Reset();
        Pg.OpenEdit();
        Observer.Observe('second-open-log', Log.Dump());
        Observer.Observe('second-open-txt', Pg.TxtCtl.Value());
        Observer.Observe('second-open-int', Pg.IntCtl.Value());
        Pg.Close();
        Observer.Expect('first-open-log', 'SaveCard.OnInit(|0);SaveCard.OnOpenPage(|0)');
        Observer.Expect('close-log', 'SaveCard.OnQueryClosePage(OK,stored text);SaveCard.OnClosePage(stored text)');
        Observer.Expect('second-open-log', 'SaveCard.OnInit(|0);SaveCard.OnOpenPage(stored text|42)');
        Observer.Expect('second-open-txt', 'stored text');
        Observer.Expect('second-open-int', '42');
        Observer.Verify();
    end;

    [Test]
    procedure SaveValuesRestoredAfterOnInitBeforeOnOpenPage()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        Pg: TestPage "LT PnG Save Card";
    begin
        ResetSaved();
        Pg.OpenEdit();
        Pg.TxtCtl.SetValue('from client');
        Pg.IntCtl.SetValue(7);
        Pg.Close();
        Log.Reset();
        Log.SetFlag('SaveCardOnInitSets', true);
        Pg.OpenEdit();
        Observer.Observe('log-open-with-init-assign', Log.Dump());
        Observer.Observe('txt-after-open', Pg.TxtCtl.Value());
        Observer.Observe('int-after-open', Pg.IntCtl.Value());
        Pg.Close();
        Log.SetFlag('SaveCardOnInitSets', false);
        Observer.Expect('log-open-with-init-assign', 'SaveCard.OnInit(|0);SaveCard.OnOpenPage(from client|7)');
        Observer.Expect('txt-after-open', 'from client');
        Observer.Expect('int-after-open', '7');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SaveCardHandler')]
    procedure SaveValuesPlatformCloseStores()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
    begin
        ResetSaved();
        Mode := 1;
        HandlerCalls := 0;
        Page.Run(Page::"LT PnG Save Card");
        Observer.Observe('first-log', Log.Dump());
        Log.Reset();
        Mode := 2;
        Page.Run(Page::"LT PnG Save Card");
        Observer.Observe('second-log', Log.Dump());
        Observer.Observe('second-saw', Seen);
        Observer.Observe('calls', Format(HandlerCalls));
        Observer.Expect('first-log', 'SaveCard.OnInit(|0);SaveCard.OnOpenPage(|0);SaveCard.OnQueryClosePage(OK,platform closed);SaveCard.OnClosePage(platform closed)');
        Observer.Expect('second-log', 'SaveCard.OnInit(|0);SaveCard.OnOpenPage(platform closed|13);SaveCard.OnQueryClosePage(OK,platform closed);SaveCard.OnClosePage(platform closed)');
        Observer.Expect('second-saw', 'platform closed|13');
        Observer.Expect('calls', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('SaveDialogHandler')]
    procedure SaveValuesDialogOkAndLogs()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT PnG Log";
        R: Action;
    begin
        ResetSaved();
        Mode := 4;
        Page.RunModal(Page::"LT PnG Save Dialog");
        Log.Reset();
        Mode := 1;
        R := Page.RunModal(Page::"LT PnG Save Dialog");
        Observer.Observe('first-result', Format(R, 0, 2));
        Observer.Observe('first-log', Log.Dump());
        Log.Reset();
        Mode := 2;
        R := Page.RunModal(Page::"LT PnG Save Dialog");
        Observer.Observe('second-result', Format(R, 0, 2));
        Observer.Observe('second-saw', Seen);
        Observer.Observe('second-log', Log.Dump());
        Observer.Expect('first-result', 'LookupOK');
        Observer.Expect('first-log', 'SaveDlg.OnInit();SaveDlg.OnOpenPage();SaveDlg.OnQueryClosePage(LookupOK);SaveDlg.OnClosePage');
        Observer.Expect('second-result', 'LookupCancel');
        Observer.Expect('second-saw', 'dialog value');
        Observer.Expect('second-log', 'SaveDlg.OnInit();SaveDlg.OnOpenPage(dialog value);SaveDlg.OnQueryClosePage(LookupCancel);SaveDlg.OnClosePage');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BoomHandler')]
    procedure TeardownInHandlerReportsForNonLookupRunModal()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Pg: Page "LT PnG Boom List";
        R: Action;
    begin
        Item.DeleteAll();
        Item."No." := 'B1';
        Item.Name := 'fine';
        Item.Insert();
        Item."No." := 'B2';
        Item.Name := 'BOOM';
        Item.Insert();
        Mode := 1;
        asserterror R := Pg.RunModal();
        Observer.ObserveError('af236');
        Observer.Observe('teardown-result', Format(R, 0, 2));
        Observer.Observe('teardown-seen', Seen);
        Observer.Expect('af236|text', 'LT PnG boom on B2');
        Observer.Expect('af236|code', 'ClientPageAbort:FormAbort');
        Observer.Expect('teardown-result', 'None');
        Observer.Expect('teardown-seen', 'dialog value');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BoomHandler')]
    procedure TeardownThenOkInHandler()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Pg: Page "LT PnG Boom List";
        R: Action;
    begin
        Item.DeleteAll();
        Item."No." := 'B1';
        Item.Name := 'fine';
        Item.Insert();
        Item."No." := 'B2';
        Item.Name := 'BOOM';
        Item.Insert();
        Mode := 2;
        asserterror R := Pg.RunModal();
        Observer.ObserveError('af260');
        Observer.Observe('result', Format(R, 0, 2));
        Observer.Observe('seen', Seen);
        Observer.Expect('af260|text', 'LT PnG boom on B2');
        Observer.Expect('af260|code', 'ClientPageAbort:FormAbort');
        Observer.Expect('result', 'None');
        Observer.Expect('seen', 'dialog value');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BoomHandler')]
    procedure TeardownInLookupHandler()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Pg: Page "LT PnG Boom List";
        R: Action;
    begin
        Item.DeleteAll();
        Item."No." := 'B1';
        Item.Name := 'fine';
        Item.Insert();
        Item."No." := 'B2';
        Item.Name := 'BOOM';
        Item.Insert();
        Mode := 1;
        Pg.LookupMode(true);
        asserterror R := Pg.RunModal();
        Observer.ObserveError('af285');
        Observer.Observe('result', Format(R, 0, 2));
        Observer.Observe('seen', Seen);
        Observer.Expect('af285|text', 'LT PnG boom on B2');
        Observer.Expect('af285|code', 'ClientPageAbort:FormAbort');
        Observer.Expect('result', 'None');
        Observer.Expect('seen', 'dialog value');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('BoomHandler')]
    procedure NoTeardownBaselineReturnsWithoutInvoking()
    var
        Observer: Codeunit "Probe Observer";
        Item: Record "LT PnG Item";
        Pg: Page "LT PnG Boom List";
        R: Action;
    begin
        Item.DeleteAll();
        Item."No." := 'B1';
        Item.Name := 'fine';
        Item.Insert();
        Mode := 3;
        R := Pg.RunModal();
        Observer.Observe('result', Format(R, 0, 2));
        Observer.Observe('seen', Seen);
        Clear(Pg);
        Mode := 5;
        R := Pg.RunModal();
        Observer.Observe('result-ok', Format(R, 0, 2));
        Clear(Pg);
        Mode := 6;
        asserterror R := Pg.RunModal();
        Observer.ObserveError('af315');
        Observer.Observe('result-cancel', Format(R, 0, 2));
        Observer.Expect('result', 'OK');
        Observer.Expect('seen', 'returned');
        Observer.Expect('result-ok', 'OK');
        Observer.Expect('af315|text', 'The built-in action = Cancel is not found on the page.');
        Observer.Expect('af315|code', 'TestActionNotFound');
        Observer.Expect('result-cancel', 'OK');
        Observer.Verify();
    end;

    [PageHandler]
    procedure CardHandler(var Card: TestPage "LT PnG Card")
    begin
        HandlerCalls += 1;
        case Mode of
            2:
                Card.NameCtl.SetValue('Edited in handler');
            3:
                Card.Close();
        end;
    end;

    [PageHandler]
    procedure SaveCardHandler(var Pg: TestPage "LT PnG Save Card")
    begin
        HandlerCalls += 1;
        case Mode of
            1:
                begin
                    Pg.TxtCtl.SetValue('platform closed');
                    Pg.IntCtl.SetValue(13);
                end;
            2:
                Seen := Pg.TxtCtl.Value() + '|' + Pg.IntCtl.Value();
        end;
    end;

    [ModalPageHandler]
    procedure SaveDialogHandler(var Dlg: TestPage "LT PnG Save Dialog")
    begin
        case Mode of
            1:
                begin
                    Dlg.TxtCtl.SetValue('dialog value');
                    Dlg.OK().Invoke();
                end;
            2:
                begin
                    Seen := Dlg.TxtCtl.Value();
                    Dlg.Cancel().Invoke();
                end;
            4:
                begin
                    Dlg.TxtCtl.SetValue('');
                    Dlg.OK().Invoke();
                end;
        end;
    end;

    [ModalPageHandler]
    procedure BoomHandler(var Pg: TestPage "LT PnG Boom List")
    begin
        case Mode of
            1:
                begin
                    Pg.First();
                    asserterror begin Pg.Next(); Error('LT-NOERROR'); end;
                    Seen := GetLastErrorText();
                end;
            2:
                begin
                    Pg.First();
                    asserterror begin Pg.Next(); Error('LT-NOERROR'); end;
                    Seen := GetLastErrorText();
                    asserterror begin Pg.OK().Invoke(); Error('LT-NOERROR'); end;
                    Seen += '|' + GetLastErrorText();
                end;
            3:
                Seen := 'returned';
            5:
                Pg.OK().Invoke();
            6:
                Pg.Cancel().Invoke();
        end;
    end;
}
