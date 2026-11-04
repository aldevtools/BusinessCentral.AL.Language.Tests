// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-handler-methods
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT CB Row / Hnd Log / Hnd Card / Hnd Dialog (CbFixtures.al)
// Probe: corpus issue #667 items 17 to 23 (handlers and UI): FilterPageBuilder.RunModal without a handler; a handler and a plain procedure
//        of the same name; a second Message, Confirm and StrMenu in one test; Message while a Dialog is open; TestPage.Close() inside a
//        ModalPageHandler; a RunObject action to a StandardDialog with RunPageLink, RunPageView and RunPageMode; a trapped TestPage whose
//        action opens a modal page. Compile-only halves: must-not-compile cases 1608 and 1609.
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. 27.5 and 28.5 by the CI matrix.
// BC versions: 27 to 29 (CI matrix)

codeunit 84168 "LT CB Handler Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CB Hnd Log";

    local procedure Seed()
    var
        Row: Record "LT CB Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row."No." := 'R1';
        Row.Name := 'One';
        Row.Qty := 1;
        Row.Insert();
        Row.Init();
        Row."No." := 'R2';
        Row.Name := 'Two';
        Row.Qty := 0;
        Row.Insert();
        Log.Take();
    end;

    // ---------- item 17: FilterPageBuilder.RunModal without a FilterPageHandler ----------

    [TryFunction]
    local procedure TryFpbRunModal(var Fpb: FilterPageBuilder; var Result: Text)
    begin
        Result := Format(Fpb.RunModal());
    end;

    [Test]
    procedure FilterPageBuilder_RunModal_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Fpb: FilterPageBuilder;
        Result: Text;
    begin
        Fpb.AddTable('Rows', Database::"LT CB Row");
        ClearLastError();
        Observer.Observe('ok', Format(TryFpbRunModal(Fpb, Result)));
        Observer.Observe('result', Result);
        Observer.ObserveError('run');
        Observer.Expect('ok', 'Yes');
        Observer.Expect('result', 'No');
        Observer.Expect('run|text', 'Unhandled UI: FilterPage 9598');
        Observer.Expect('run|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // ---------- item 18: a handler and a plain procedure of the same name (an overload) ----------

    [Test]
    [HandlerFunctions('PickHandler')]
    procedure Handler_OverloadedWithPlainProcedure_IsTheHandler()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        PickHandler(7);
        Observer.Observe('result', Format(Page.RunModal(Page::"LT CB Hnd Dialog")));
        Observer.Observe('log', Log.Take());
        Observer.Expect('result', 'LookupOK');
        Observer.Expect('log', 'plain PickHandler 7;dialog OnOpenPage filters=[] editable=Yes;handler PickHandler;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure PickHandler(var Pg: TestPage "LT CB Hnd Dialog")
    begin
        Log.Add('handler PickHandler');
        Pg.OK().Invoke();
    end;

    procedure PickHandler(Value: Integer)
    begin
        Log.Add('plain PickHandler ' + Format(Value));
    end;

    // ---------- item 19: the same handler answers every Message, Confirm and StrMenu ----------

    [Test]
    [HandlerFunctions('CountMessageHandler,CountConfirmHandler,CountStrMenuHandler')]
    procedure Handlers_AnswerEverySecondCall()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Log.Take();
        Message('m1');
        Message('m2');
        Observer.Observe('confirm1', Format(Confirm('c1')));
        Observer.Observe('confirm2', Format(Confirm('c2')));
        Observer.Observe('strmenu1', Format(StrMenu('A,B,C', 1, 's1')));
        Observer.Observe('strmenu2', Format(StrMenu('A,B,C', 1, 's2')));
        Observer.Observe('log', Log.Take());
        Observer.Expect('confirm1', 'No');
        Observer.Expect('confirm2', 'Yes');
        Observer.Expect('strmenu1', '2');
        Observer.Expect('strmenu2', '3');
        Observer.Expect('log', 'msg m1;msg m2;confirm c1;confirm c2;strmenu s1;strmenu s2;');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure CountMessageHandler(Msg: Text[1024])
    begin
        Log.Add('msg ' + Msg);
    end;

    [ConfirmHandler]
    procedure CountConfirmHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Log.Add('confirm ' + Question);
        Reply := Question = 'c2';
    end;

    [StrMenuHandler]
    procedure CountStrMenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Log.Add('strmenu ' + Instruction);
        if Instruction = 's1' then
            Choice := 2
        else
            Choice := 3;
    end;

    // ---------- item 20: Message while a progress Dialog is open ----------

    [Test]
    [HandlerFunctions('CountMessageHandler')]
    procedure Message_WhileDialogOpen_IsHandledAtOnce()
    var
        Observer: Codeunit "Probe Observer";
        Dlg: Dialog;
    begin
        Log.Take();
        Dlg.Open('Working #1####');
        Log.Add('opened');
        Message('during open');
        Log.Add('after message 1');
        Dlg.Update(1, 5);
        Message('after update');
        Log.Add('after message 2');
        Dlg.Close();
        Message('after close');
        Log.Add('after message 3');
        Observer.Observe('log', Log.Take());
        Observer.Expect('log', 'opened;msg during open;after message 1;msg after update;after message 2;msg after close;after message 3;');
        Observer.Verify();
    end;

    // ---------- item 21: TestPage.Close() inside a ModalPageHandler ----------

    [TryFunction]
    local procedure TryRunModalDialog(WithRecord: Boolean; var Result: Text)
    var
        Row: Record "LT CB Row";
    begin
        if WithRecord then begin
            Row.Get('R1');
            Result := Format(Page.RunModal(Page::"LT CB Hnd Dialog", Row));
        end else
            Result := Format(Page.RunModal(Page::"LT CB Hnd Dialog"));
    end;

    [Test]
    [HandlerFunctions('CloseHandler')]
    procedure ModalHandler_CallsClose_RunModalOutcome()
    var
        Observer: Codeunit "Probe Observer";
        Result: Text;
    begin
        Seed();
        ClearLastError();
        Observer.Observe('norec_ok', Format(TryRunModalDialog(false, Result)));
        Observer.Observe('norec_result', Result);
        Observer.ObserveError('norec');
        Result := '';
        Observer.Observe('rec_ok', Format(TryRunModalDialog(true, Result)));
        Observer.Observe('rec_result', Result);
        Observer.ObserveError('rec');
        Observer.Observe('log', Log.Take());
        Observer.Expect('norec_ok', 'No');
        Observer.Expect('norec_result', '');
        Observer.Expect('norec|text', 'The RunModal procedure could not close the page 84172 as it has already been closed.');
        Observer.Expect('norec|code', 'TestCodeUnit');
        Observer.Expect('rec_ok', 'No');
        Observer.Expect('rec_result', '');
        Observer.Expect('rec|text', 'The RunModal procedure could not close the page 84172 as it has already been closed.');
        Observer.Expect('rec|code', 'TestCodeUnit');
        Observer.Expect('log', 'dialog OnOpenPage filters=[] editable=Yes;handler no=R1;handler after Close;dialog OnOpenPage filters=[] editable=Yes;handler no=R1;handler after Close;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure CloseHandler(var Pg: TestPage "LT CB Hnd Dialog")
    begin
        Log.Add('handler no=' + Pg.NoCtl.Value());
        Pg.Close();
        Log.Add('handler after Close');
    end;

    // ---------- item 22: RunObject action to a StandardDialog with RunPageLink, RunPageView, RunPageMode ----------

    // Held (publisher, bump 29): in the full run 39315232637 the first Invoke raised 'Unexpected CLR exception thrown.:
    // System.Reflection.TargetException: Object does not match target type.' on BC 27.5 and 28.5 (green in the writer's own runs).
    // Windows BC 27.5 and 28.5 full runs (2026-10-20, all corpus codeunits, this test enabled) pass it with no TargetException.
    // Windows BC 29.0 raises the same TargetException in a full TestRunnerHub run (the codeunit run just before is 69640
    // "TPT Teardown Tests") and passes when run alone. So the failure comes from state left by an earlier codeunit in the run
    // order, on Windows too: it is not a Linux-only bug (bc-linux #162). Held under LT_HELD_BCLINUX_162 on every version.
#if LT_HELD_BCLINUX_162
    [Test]
    [HandlerFunctions('LinkedDialogHandler')]
#endif
    procedure RunObjectAction_StandardDialog_LinkViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT CB Hnd Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Log.Take();
        Card.DialogLinked.Invoke();
        Observer.Observe('r1_log', Log.Take());
        Card.GoToKey('R2');
        Log.Take();
        Card.DialogLinked.Invoke();
        Observer.Observe('r2_log', Log.Take());
        Card.Close();
        Observer.Expect('r1_log', 'dialog OnOpenPage filters=[No.: R1] editable=Yes;handler rows=R1, editable=Yes qtyEditable=Yes;');
        Observer.Expect('r2_log', 'dialog OnOpenPage filters=[No.: R2] editable=Yes;handler rows= editable=Yes qtyEditable=No;');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure LinkedDialogHandler(var Pg: TestPage "LT CB Hnd Dialog")
    var
        Rows: Text;
    begin
        if Pg.First() then
            repeat
                Rows += Pg.NoCtl.Value() + ',';
            until not Pg.Next();
        Log.Add('handler rows=' + Rows + ' editable=' + Format(Pg.Editable()) + ' qtyEditable=' + Format(Pg.QtyCtl.Editable()));
        Pg.OK().Invoke();
    end;

    // ---------- item 23: a trapped TestPage whose action opens a modal page ----------

    [TryFunction]
    local procedure TryReadName(var Card: TestPage "LT CB Hnd Card"; var Value: Text)
    begin
        Value := Card.NameCtl.Value();
    end;

    [TryFunction]
    local procedure TryCloseCard(var Card: TestPage "LT CB Hnd Card")
    begin
        Card.Close();
    end;

    [Test]
    [HandlerFunctions('OkDialogHandler')]
    procedure TrappedPage_ActionOpensModal_StateAfter()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT CB Row";
        Card: TestPage "LT CB Hnd Card";
        Value: Text;
    begin
        Seed();
        Row.Get('R1');
        Card.Trap();
        Page.Run(Page::"LT CB Hnd Card", Row);
        Log.Take();
        Card.OpenDialogModal.Invoke();
        Observer.Observe('action_log', Log.Take());
        ClearLastError();
        Observer.Observe('read_ok', Format(TryReadName(Card, Value)));
        Observer.Observe('read_value', Value);
        Observer.ObserveError('read');
        Observer.Observe('close_ok', Format(TryCloseCard(Card)));
        Observer.ObserveError('close');
        Observer.Expect('action_log', 'card OnAfterGetRecord R1;card OnAction OpenDialogModal;dialog OnOpenPage filters=[] editable=Yes;handler no=R1;card RunModal=OK;card OnAfterGetRecord R1;card OnAfterGetRecord R1;card OnAfterGetCurrRecord R1;');
        Observer.Expect('read_ok', 'Yes');
        Observer.Expect('read_value', 'One');
        Observer.Expect('read|text', '');
        Observer.Expect('read|code', '');
        Observer.Expect('close_ok', 'Yes');
        Observer.Expect('close|text', '');
        Observer.Expect('close|code', '');
        Observer.Verify();
    end;

    [ModalPageHandler]
    procedure OkDialogHandler(var Pg: TestPage "LT CB Hnd Dialog")
    begin
        Log.Add('handler no=' + Pg.NoCtl.Value());
        Pg.OK().Invoke();
    end;
}
