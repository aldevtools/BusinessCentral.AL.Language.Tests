// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160); objects 80620-80626 (AzHandlerObjects.al)
// Probe: corpus issue 652 (test handlers, dialogs and error texts), items 1 (MessageHandler calling StrMenu, ConfirmHandler calling Confirm or StrMenu), 2 (Confirm), 5, 6 (no handler) and 9, writer AZ.
// Already pinned: the other parts of items 1 and 2 (pages/W1Handlers.al, errors/lt-ms-refusals-133/P133MessageInHandlers.al,
// handlers/TestUnhandledUiAndDialogDefaults.al), item 4 (report/W3ReportRequestPageRun.al), 6 with a handler (platform/lt-platform-members/PlTFilterPageBuilder.al).
// BC versions: 27, 28, 29

codeunit 80627 "LT AZ Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT AZ Hnd Log";
        Mode: Text;
        Depth: Integer;

    local procedure Reset(NewMode: Text)
    begin
        Mode := NewMode;
        Depth := 0;
        Log.Take();
        ClearLastError();
    end;

    local procedure Inner()
    begin
        if Depth > 0 then
            exit;
        Depth += 1;
        case Mode of
            'message':
                begin
                    Message('az inner message');
                    Log.Add('inner message returned');
                end;
            'confirm':
                Log.Add('inner confirm=' + Format(Confirm('az inner confirm')));
            'strmenu':
                Log.Add('inner strmenu=' + Format(StrMenu('A,B,C', 1)));
        end;
    end;

    [TryFunction]
    local procedure TryMessage(Text: Text)
    begin
        Message(Text);
    end;

    [TryFunction]
    local procedure TryConfirm(Text: Text; var Answer: Boolean)
    begin
        Answer := Confirm(Text);
    end;

    local procedure ObserveMessage(Name: Text)
    begin
        Observer.Observe(Name + '_ok', Format(TryMessage('az outer message')));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    local procedure ObserveConfirm(Name: Text)
    var
        Answer: Boolean;
    begin
        Observer.Observe(Name + '_ok', Format(TryConfirm('az outer confirm', Answer)));
        Observer.Observe(Name + '_answer', Format(Answer));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    [MessageHandler]
    procedure AzMsgReenter(Msg: Text)
    begin
        Log.Add('msgh(' + Msg + ')');
        Inner();
    end;

    [ConfirmHandler]
    procedure AzConfirmReenter(Question: Text; var Reply: Boolean)
    begin
        Log.Add('confh(' + Question + ')');
        Reply := true;
        Inner();
    end;

    [StrMenuHandler]
    procedure AzStrMenu2(Options: Text; var Choice: Integer; Instruction: Text)
    begin
        Log.Add('strmenuh(' + Options + ')');
        Choice := 2;
    end;

    // ---- item 1: a MessageHandler or ConfirmHandler that itself calls Message, Confirm or StrMenu ----

    [Test]
    [HandlerFunctions('AzMsgReenter,AzStrMenu2')]
    procedure MessageHandler_CallsStrMenu_WithHandler()
    begin
        Reset('strmenu');
        ObserveMessage('m');
        Observer.Expect('m_ok', 'Yes');
        Observer.Expect('m_log', 'msgh(az outer message);strmenuh(A,B,C);inner strmenu=2;');
        Observer.Expect('m|text', '');
        Observer.Expect('m|code', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AzMsgReenter')]
    procedure MessageHandler_CallsStrMenu_NoHandler()
    begin
        Reset('strmenu');
        ObserveMessage('m');
        Observer.Expect('m_ok', 'No');
        Observer.Expect('m_log', 'msgh(az outer message);');
        Observer.Expect('m|text', 'Unhandled UI: StrMenu A,B,C');
        Observer.Expect('m|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter')]
    procedure ConfirmHandler_CallsConfirm()
    begin
        Reset('confirm');
        ObserveConfirm('c');
        Observer.Expect('c_ok', 'Yes');
        Observer.Expect('c_answer', 'Yes');
        Observer.Expect('c_log', 'confh(az outer confirm);confh(az inner confirm);inner confirm=Yes;');
        Observer.Expect('c|text', '');
        Observer.Expect('c|code', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter,AzStrMenu2')]
    procedure ConfirmHandler_CallsStrMenu_WithHandler()
    begin
        Reset('strmenu');
        ObserveConfirm('c');
        Observer.Expect('c_ok', 'Yes');
        Observer.Expect('c_answer', 'Yes');
        Observer.Expect('c_log', 'confh(az outer confirm);strmenuh(A,B,C);inner strmenu=2;');
        Observer.Expect('c|text', '');
        Observer.Expect('c|code', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('AzConfirmReenter')]
    procedure ConfirmHandler_CallsStrMenu_NoHandler()
    begin
        Reset('strmenu');
        ObserveConfirm('c');
        Observer.Expect('c_ok', 'No');
        Observer.Expect('c_answer', 'No');
        Observer.Expect('c_log', 'confh(az outer confirm);');
        Observer.Expect('c|text', 'Unhandled UI: StrMenu A,B,C');
        Observer.Expect('c|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // ---- item 2: Message and Confirm in the OnRun of a codeunit started with Codeunit.Run, no handler in the test ----

    [Test]
    procedure CodeunitRun_Confirm_NoHandler()
    var
        Cu: Codeunit "LT AZ Hnd Confirm OnRun";
    begin
        Reset('');
        Observer.Observe('run', Format(Cu.Run()));
        Observer.Observe('result', Cu.GetResult());
        Observer.ObserveError('run');
        Observer.Expect('run', 'No');
        Observer.Expect('result', ' answer=No');
        Observer.Expect('run|text', 'Unhandled UI: Confirm az confirm from onrun');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // ---- item 3: two MessageHandlers in one HandlerFunctions list ----
    // Not asserted here (a test with this list cannot pass): it compiles; on BC 29.0 the first listed handler received every Message() and
    // the test then failed with "The following UI handlers were not executed: <second handler>". See the writer AZ report.

    // Linux suspect (not asserted): without the Commit() after SeedRows, Report.Run with a request page ended in "An error occurred and the
    // transaction is stopped. Contact your administrator or partner for further assistance." (code DB:Ok) before the handler ran.
    // ---- items 4 and 5: a RequestPageHandler that neither OKs nor cancels, and one that inserts a row before OK ----

    [RequestPageHandler]
    procedure AzReqInsertThenOk(var RP: TestRequestPage "LT AZ Hnd Report")
    var
        Row: Record "LT AZ Hnd Row";
    begin
        Log.Add('reqh');
        Row.Id := 99;
        Row.Name := 'from handler';
        Row.Insert();
        Log.Add('inserted');
        RP.Tag.SetValue('t5');
        RP.OK().Invoke();
    end;

    local procedure SeedRows()
    var
        Row: Record "LT AZ Hnd Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('AzReqInsertThenOk')]
    procedure RequestPageHandler_InsertBeforeOk()
    var
        Row: Record "LT AZ Hnd Row";
    begin
        SeedRows();
        Commit();
        Reset('');
        asserterror Report.Run(Report::"LT AZ Hnd Report");
        Observer.ObserveError('run');
        Observer.Observe('log', Log.Take());
        Observer.Observe('row99', Format(Row.Get(99)));
        Observer.Observe('count', Format(Row.Count()));
        Observer.Expect('run|text', 'A transaction must be started before changes can be made to the database.');
        Observer.Expect('run|code', 'DB:BWTMissing');
        Observer.Expect('log', 'reqh;');
        Observer.Expect('row99', 'No');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    // ---- item 6: FilterPageBuilder.RunModal with a FilterPageHandler and without one ----

    [TryFunction]
    local procedure TryRunFpb(var Fpb: FilterPageBuilder; var Result: Boolean)
    begin
        Result := Fpb.RunModal();
    end;

    local procedure ObserveFpb(Name: Text)
    var
        Fpb: FilterPageBuilder;
        Result: Boolean;
    begin
        Fpb.AddTable('Rows', Database::"LT AZ Hnd Row");
        Fpb.SetView('Rows', 'WHERE(Id=FILTER(1..5))');
        Observer.Observe(Name + '_ok', Format(TryRunFpb(Fpb, Result)));
        Observer.Observe(Name + '_result', Format(Result));
        Observer.Observe(Name + '_view', Fpb.GetView('Rows'));
        Observer.Observe(Name + '_view_captions', Fpb.GetView('Rows', false));
        Observer.Observe(Name + '_log', Log.Take());
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure FilterPageBuilder_NoHandler()
    begin
        Reset('');
        ObserveFpb('n');
        Observer.Expect('n_ok', 'Yes');
        Observer.Expect('n_result', 'No');
        Observer.Expect('n_view', 'VERSION(1) SORTING(Id) WHERE(Id=FILTER(1..5))');
        Observer.Expect('n_view_captions', 'VERSION(1) SORTING(Field1) WHERE(Field1=1(1..5))');
        Observer.Expect('n_log', '');
        Observer.Expect('n|text', 'Unhandled UI: FilterPage 9598');
        Observer.Expect('n|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // ---- item 9: Dialog.Update without arguments on a closed dialog, Update of a number missing from the template ----

    [TryFunction]
    local procedure TryUpdateNoArgs(var D: Dialog)
    begin
        D.Update();
    end;

    [TryFunction]
    local procedure TryUpdate(var D: Dialog; No: Integer; Value: Variant)
    begin
        D.Update(No, Value);
    end;

    [TryFunction]
    local procedure TryOpen(var D: Dialog; Template: Text)
    begin
        D.Open(Template);
    end;

    [Test]
    procedure Dialog_UpdateEdges()
    var
        D: Dialog;
    begin
        Reset('');
        Observer.Observe('closed_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('closed_noargs');
        Observer.Observe('closed_one', Format(TryUpdate(D, 1, 'x')));
        Observer.ObserveError('closed_one');
        Observer.Observe('open', Format(TryOpen(D, 'Name #1########\Progress @2@@@@@@@@')));
        Observer.ObserveError('open');
        Observer.Observe('open_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('open_noargs');
        Observer.Observe('open_hash', Format(TryUpdate(D, 1, 'abc')));
        Observer.ObserveError('open_hash');
        Observer.Observe('open_at', Format(TryUpdate(D, 2, 5000)));
        Observer.ObserveError('open_at');
        Observer.Observe('open_missing', Format(TryUpdate(D, 3, 'zz')));
        Observer.ObserveError('open_missing');
        Observer.Observe('open_at_text', Format(TryUpdate(D, 2, 'not a number')));
        Observer.ObserveError('open_at_text');
        D.Close();
        Observer.Observe('after_close_noargs', Format(TryUpdateNoArgs(D)));
        Observer.ObserveError('after_close_noargs');
        Observer.Expect('closed_noargs', 'No');
        Observer.Expect('closed_noargs|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('closed_noargs|code', 'Dialog');
        Observer.Expect('closed_one', 'No');
        Observer.Expect('closed_one|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('closed_one|code', 'Dialog');
        Observer.Expect('open', 'Yes');
        Observer.Expect('open|text', '');
        Observer.Expect('open|code', '');
        Observer.Expect('open_noargs', 'Yes');
        Observer.Expect('open_noargs|text', '');
        Observer.Expect('open_noargs|code', '');
        Observer.Expect('open_hash', 'Yes');
        Observer.Expect('open_hash|text', '');
        Observer.Expect('open_hash|code', '');
        Observer.Expect('open_at', 'Yes');
        Observer.Expect('open_at|text', '');
        Observer.Expect('open_at|code', '');
        Observer.Expect('open_missing', 'No');
        Observer.Expect('open_missing|text', 'No parameter with index ''3'' was found in the format string ''Name %s\Progress %d''.');
        Observer.Expect('open_missing|code', 'FormatStringParameterNotFound');
        Observer.Expect('open_at_text', 'Yes');
        Observer.Expect('open_at_text|text', '');
        Observer.Expect('open_at_text|code', '');
        Observer.Expect('after_close_noargs', 'No');
        Observer.Expect('after_close_noargs|text', 'The operation failed because the dialog box is not open.');
        Observer.Expect('after_close_noargs|code', 'Dialog');
        Observer.Verify();
    end;
}
