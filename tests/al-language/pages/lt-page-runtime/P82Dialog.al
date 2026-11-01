// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against BC 29 (runtime 16); the facts are measured later
// Facts: Dialog Open / Update / Close in a test (no UI), Confirm / StrMenu / Message with handlers (text the handler receives, returned value) and without handlers, Error with format arguments and ErrorInfo
// BC versions: 29
// Writer Y64 (2026-11-01, Y64_* tests, al-runner issue 6656): Clear(Dialog) of an unopened and an opened dialog, what Update, Close and Open do after it,
//   Clear twice, ClearAll of a SingleInstance codeunit that holds an open Dialog (codeunit 93300, used only by this test codeunit), Clear of a var parameter.

codeunit 71206 "LT P82 Dialog"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";
        ConfirmAnswer: Boolean;
        MenuAnswer: Integer;

    [TryFunction]
    local procedure TryUpdateNumber(var Dlg: Dialog; FieldNo: Integer; Value: Integer)
    begin
        Dlg.Update(FieldNo, Value);
    end;

    [TryFunction]
    local procedure TryUpdateText(var Dlg: Dialog; FieldNo: Integer; Value: Text)
    begin
        Dlg.Update(FieldNo, Value);
    end;

    [TryFunction]
    local procedure TryOpen(var Dlg: Dialog; Template: Text)
    begin
        Dlg.Open(Template);
    end;

    [TryFunction]
    local procedure TryClose(var Dlg: Dialog)
    begin
        Dlg.Close();
    end;

    [ConfirmHandler]
    procedure ConfirmAnswerHandler(Question: Text[1024]; var Reply: Boolean)
    begin
        Observer.Observe('question', Question);
        Reply := ConfirmAnswer;
    end;

    [StrMenuHandler]
    procedure MenuHandler(Options: Text[1024]; var Choice: Integer; Instruction: Text[1024])
    begin
        Observer.Observe('options', Options);
        Observer.Observe('instruction', Instruction);
        Observer.Observe('default-choice', Format(Choice));
        Choice := MenuAnswer;
    end;

    [MessageHandler]
    procedure MessageObserver(Message: Text[1024])
    begin
        Observer.Observe('message', Message);
    end;

    [Test]
    procedure Dialog_Open_Update_Close()
    var
        Dlg: Dialog;
    begin
        Dlg.Open('Working #1###### and @2@@@@@@@@');
        Observer.Observe('open', 'ok');
        Dlg.Update(1, 'text');
        Observer.Observe('update-text', 'ok');
        Dlg.Update(1, 42);
        Observer.Observe('update-integer', 'ok');
        Dlg.Update(2, 5000);
        Observer.Observe('update-progress', 'ok');
        Dlg.Update(2, 10000);
        Observer.Observe('update-progress-full', 'ok');
        Dlg.Update(1, 1.5);
        Observer.Observe('update-decimal', 'ok');
        Dlg.Update(1, Today());
        Observer.Observe('update-date-no-error', 'ok');
        Dlg.Close();
        Observer.Observe('close', 'ok');
        Observer.Expect('open', 'ok');
        Observer.Expect('update-text', 'ok');
        Observer.Expect('update-integer', 'ok');
        Observer.Expect('update-progress', 'ok');
        Observer.Expect('update-progress-full', 'ok');
        Observer.Expect('update-decimal', 'ok');
        Observer.Expect('update-date-no-error', 'ok');
        Observer.Expect('close', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure Dialog_EdgeCases()
    var
        Dlg: Dialog;
        Dlg2: Dialog;
    begin
        Observer.Observe('close-unopened', Format(TryClose(Dlg2)));
        Observer.Observe('close-unopened-error', GetLastErrorText());
        Observer.Observe('update-unopened', Format(TryUpdateNumber(Dlg2, 1, 1)));
        Observer.Observe('update-unopened-error', GetLastErrorText());
        Observer.Observe('open-empty-template', Format(TryOpen(Dlg, '')));
        Observer.Observe('open-empty-error', GetLastErrorText());
        Observer.Observe('update-unknown-field', Format(TryUpdateNumber(Dlg, 9, 1)));
        Observer.Observe('update-unknown-field-error', GetLastErrorText());
        Observer.Observe('update-zero-field', Format(TryUpdateNumber(Dlg, 0, 1)));
        Observer.Observe('update-zero-field-error', GetLastErrorText());
        Observer.Observe('close-twice-first', Format(TryClose(Dlg)));
        Observer.Observe('close-twice-second', Format(TryClose(Dlg)));
        Observer.Observe('close-twice-error', GetLastErrorText());
        Observer.Observe('open-plain-text', Format(TryOpen(Dlg, 'Just text')));
        Observer.Observe('update-no-placeholder', Format(TryUpdateText(Dlg, 1, 'x')));
        Observer.Observe('update-no-placeholder-error', GetLastErrorText());
        Observer.Observe('open-reopen', Format(TryOpen(Dlg, 'Again #1##')));
        Observer.Observe('open-reopen-error', GetLastErrorText());
        Dlg.Close();
        Observer.Expect('close-unopened', 'No');
        Observer.Expect('close-unopened-error', 'The operation failed because the dialog box is not open.');
        Observer.Expect('update-unopened', 'No');
        Observer.Expect('update-unopened-error', 'The operation failed because the dialog box is not open.');
        Observer.Expect('open-empty-template', 'Yes');
        Observer.Expect('open-empty-error', 'The operation failed because the dialog box is not open.');
        Observer.Expect('update-unknown-field', 'No');
        Observer.Expect('update-unknown-field-error', 'No parameter with index ''9'' was found in the format string ''''.');
        Observer.Expect('update-zero-field', 'No');
        Observer.Expect('update-zero-field-error', 'No parameter with index ''0'' was found in the format string ''''.');
        Observer.Expect('close-twice-first', 'Yes');
        Observer.Expect('close-twice-second', 'No');
        Observer.Expect('close-twice-error', 'The operation failed because the dialog box is not open.');
        Observer.Expect('open-plain-text', 'Yes');
        Observer.Expect('update-no-placeholder', 'No');
        Observer.Expect('update-no-placeholder-error', 'No parameter with index ''1'' was found in the format string ''Just text''.');
        Observer.Expect('open-reopen', 'Yes');
        Observer.Expect('open-reopen-error', 'No parameter with index ''1'' was found in the format string ''Just text''.');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_WithHandler_True()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := true;
        Result := Confirm('Proceed with %1 and %2?', false, 'one', 2);
        Observer.Observe('result', Format(Result));
        Observer.Expect('question', 'Proceed with %1 and %2?');
        Observer.Expect('result', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_WithHandler_False_DefaultTrue()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := false;
        Result := Confirm('Default true?', true);
        Observer.Observe('result', Format(Result));
        Observer.Expect('question', 'Default true?');
        Observer.Expect('result', 'No');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_QuestionOnly()
    var
        Result: Boolean;
    begin
        ConfirmAnswer := true;
        Result := Confirm('Plain question');
        Observer.Observe('result', Format(Result));
        Observer.Expect('question', 'Plain question');
        Observer.Expect('result', 'Yes');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('ConfirmAnswerHandler')]
    procedure Confirm_EmptyAndLongQuestion()
    var
        Result: Boolean;
        Long: Text;
    begin
        ConfirmAnswer := true;
        Result := Confirm('');
        Observer.Observe('empty-result', Format(Result));
        Long := PadStr('', 1100, 'x');
        asserterror Result := Confirm(Long);
        Observer.ObserveError('af163');
        Observer.Observe('long-result', Format(Result));
        Observer.Expect('question', '');
        Observer.Expect('empty-result', 'Yes');
        Observer.Expect('af163|text', 'The length of the string is 1100, but it must be less than or equal to 1024 characters. Value: xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx...');
        Observer.Expect('af163|code', 'StringLengthExceeded');
        Observer.Expect('long-result', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Confirm_WithoutHandler()
    var
        Answer: Boolean;
    begin
        asserterror Answer := Confirm('No handler question');
        Observer.ObserveError('confirm');
        asserterror Answer := Confirm('No handler %1', true, 'again');
        Observer.ObserveError('confirm-with-args');
        Observer.Expect('confirm|text', 'Unhandled UI: Confirm No handler question');
        Observer.Expect('confirm|code', 'MissingUIHandler');
        Observer.Expect('confirm-with-args|text', 'Unhandled UI: Confirm No handler %1');
        Observer.Expect('confirm-with-args|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_WithHandler_Choice()
    var
        Result: Integer;
    begin
        MenuAnswer := 2;
        Result := StrMenu('First,Second,Third', 3, 'Pick one');
        Observer.Observe('result', Format(Result));
        Observer.Expect('options', 'First,Second,Third');
        Observer.Expect('instruction', 'Pick one');
        Observer.Expect('default-choice', '3');
        Observer.Expect('result', '2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_WithHandler_Cancel()
    var
        Result: Integer;
    begin
        MenuAnswer := 0;
        Result := StrMenu('First,Second', 1);
        Observer.Observe('result', Format(Result));
        Observer.Expect('options', 'First,Second');
        Observer.Expect('instruction', '');
        Observer.Expect('default-choice', '1');
        Observer.Expect('result', '0');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_OptionsOnly_Defaults()
    var
        Result: Integer;
    begin
        MenuAnswer := 1;
        Result := StrMenu('Only');
        Observer.Observe('result', Format(Result));
        Observer.Expect('options', 'Only');
        Observer.Expect('instruction', '');
        Observer.Expect('default-choice', '1');
        Observer.Expect('result', '1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_ChoiceOutOfRange_ReturnedAsIs()
    var
        Result: Integer;
    begin
        MenuAnswer := 9;
        Result := StrMenu('A,B', 1, 'x');
        Observer.Observe('result-9', Format(Result));
        MenuAnswer := -1;
        Result := StrMenu('A,B', 1, 'x');
        Observer.Observe('result-minus-1', Format(Result));
        Observer.Expect('options', 'A,B');
        Observer.Expect('instruction', 'x');
        Observer.Expect('default-choice', '1');
        Observer.Expect('result-9', '9');
        Observer.Expect('options', 'A,B');
        Observer.Expect('instruction', 'x');
        Observer.Expect('default-choice', '1');
        Observer.Expect('result-minus-1', '-1');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MenuHandler')]
    procedure StrMenu_EmptyAndEmptyItems()
    var
        Result: Integer;
    begin
        MenuAnswer := 1;
        Result := StrMenu('', 0, '');
        Observer.Observe('empty-result', Format(Result));
        Result := StrMenu(',,A,,', 2, 'items');
        Observer.Observe('empty-items-result', Format(Result));
        Observer.Expect('options', '');
        Observer.Expect('instruction', '');
        Observer.Expect('default-choice', '0');
        Observer.Expect('empty-result', '1');
        Observer.Expect('options', ',,A,,');
        Observer.Expect('instruction', 'items');
        Observer.Expect('default-choice', '2');
        Observer.Expect('empty-items-result', '1');
        Observer.Verify();
    end;

    [Test]
    procedure StrMenu_WithoutHandler()
    var
        Pick: Integer;
    begin
        asserterror Pick := StrMenu('A,B', 1, 'Instr');
        Observer.ObserveError('strmenu');
        Observer.Expect('strmenu|text', 'Unhandled UI: StrMenu A,B');
        Observer.Expect('strmenu|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_WithHandler()
    begin
        Message('Hello %1 and %2', 'world', 5);
        Observer.Expect('message', 'Hello world and 5');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_TwoMessages_TwoCalls()
    begin
        Message('first');
        Message('second');
        Observer.Expect('message', 'first');
        Observer.Expect('message', 'second');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('MessageObserver')]
    procedure Message_FormatCharacters()
    begin
        Message('100% sure %1', 'x');
        Observer.Expect('message', '100% sure x');
        Observer.Verify();
    end;

    [Test]
    procedure Message_WithoutHandler()
    begin
        asserterror Message('No handler message');
        Observer.ObserveError('message');
        asserterror Message('No handler %1', 'x');
        Observer.ObserveError('message-with-args');
        Observer.Expect('message|text', 'Unhandled UI: Message No handler message');
        Observer.Expect('message|code', 'MissingUIHandler');
        Observer.Expect('message-with-args|text', 'Unhandled UI: Message No handler x');
        Observer.Expect('message-with-args|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    [Test]
    procedure Error_Texts()
    begin
        asserterror Error('plain');
        Observer.ObserveError('plain');
        asserterror Error('with %1 and %2', 'text', 3);
        Observer.ObserveError('args');
        asserterror Error('missing %1 %2', 'one');
        Observer.ObserveError('missing-arg');
        asserterror Error('extra', 'unused');
        Observer.ObserveError('unused-arg');
        asserterror Error('');
        Observer.ObserveError('empty');
        asserterror Error('percent 100%');
        Observer.ObserveError('percent');
        asserterror Error('decimal %1 date %2 bool %3', 1.5, DMY2Date(2, 3, 2024), true);
        Observer.ObserveError('formatted');
        asserterror Error(PadStr('', 3000, 'e'));
        Observer.Observe('long-length', Format(StrLen(GetLastErrorText())));
        ClearLastError();
        Observer.Expect('plain|text', 'plain');
        Observer.Expect('plain|code', 'Dialog');
        Observer.Expect('args|text', 'with text and 3');
        Observer.Expect('args|code', 'Dialog');
        Observer.Expect('missing-arg|text', 'missing one %2');
        Observer.Expect('missing-arg|code', 'Dialog');
        Observer.Expect('unused-arg|text', 'extra');
        Observer.Expect('unused-arg|code', 'Dialog');
        Observer.Expect('empty|text', '');
        Observer.Expect('empty|code', 'Dialog');
        Observer.Expect('percent|text', 'percent 100%');
        Observer.Expect('percent|code', 'Dialog');
        Observer.Expect('formatted|text', 'decimal 1.5 date 03/02/24 bool Yes');
        Observer.Expect('formatted|code', 'Dialog');
        Observer.Expect('long-length', '3000');
        Observer.Verify();
    end;

    [Test]
    procedure Error_ErrorInfo()
    var
        Info: ErrorInfo;
    begin
        asserterror Error(ErrorInfo.Create('info message'));
        Observer.ObserveError('create');
        Info.Message := 'set message';
        Info.Title := 'a title';
        asserterror Error(Info);
        Observer.ObserveError('set');
        Observer.Expect('create|text', 'info message');
        Observer.Expect('create|code', 'Dialog');
        Observer.Expect('set|text', 'set message');
        Observer.Expect('set|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure Error_Rolls_Back_And_Clears()
    begin
        asserterror Error('first');
        Observer.Observe('has-error', Format(GetLastErrorText() <> ''));
        ClearLastError();
        Observer.Observe('after-clear', GetLastErrorText());
        Observer.Observe('code-after-clear', GetLastErrorCode());
        Observer.Expect('has-error', 'Yes');
        Observer.Expect('after-clear', '');
        Observer.Expect('code-after-clear', '');
        Observer.Verify();
    end;

    [Test]
    procedure Y64_Clear_UnopenedDialog()
    var
        Dlg: Dialog;
    begin
        Clear(Dlg);
        Observer.Observe('clear unopened', 'no error');
        ClearLastError();
        Observer.Observe('update after clear', Format(TryUpdateNumber(Dlg, 1, 1)));
        Observer.Observe('update after clear error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('close after clear', Format(TryClose(Dlg)));
        Observer.Observe('close after clear error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('open after clear', Format(TryOpen(Dlg, 'Value #1####')));
        ClearLastError();
        Observer.Observe('update after open', Format(TryUpdateNumber(Dlg, 1, 5)));
        ClearLastError();
        Observer.Observe('close after open', Format(TryClose(Dlg)));
        Clear(Dlg);
        Clear(Dlg);
        Observer.Observe('clear twice', 'no error');
        Observer.Finish();
    end;

    [Test]
    procedure Y64_Clear_OpenedDialog()
    var
        Dlg: Dialog;
    begin
        Dlg.Open('Value #1####');
        Clear(Dlg);
        Observer.Observe('clear opened', 'no error');
        ClearLastError();
        Observer.Observe('update after clear', Format(TryUpdateNumber(Dlg, 1, 1)));
        Observer.Observe('update after clear error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('close after clear', Format(TryClose(Dlg)));
        Observer.Observe('close after clear error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('open after clear', Format(TryOpen(Dlg, 'Other #1####')));
        Observer.Observe('open after clear error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('update after reopen', Format(TryUpdateText(Dlg, 1, 'x')));
        Observer.Observe('update after reopen error', GetLastErrorText());
        ClearLastError();
        Observer.Observe('close after reopen', Format(TryClose(Dlg)));
        Observer.Observe('close after reopen error', GetLastErrorText());
        Observer.Finish();
    end;

    [Test]
    procedure Y64_Clear_DialogInSingleInstanceCodeunit()
    var
        Status: Codeunit "LT Y64 Status Dialog";
        Again: Codeunit "LT Y64 Status Dialog";
    begin
        Status.Reset();
        Observer.Observe('reset unopened', Status.State());
        Status.Open();
        Observer.Observe('after open', Status.State());
        Status.Reset();
        Observer.Observe('reset opened', Status.State());
        Observer.Observe('update after reset', Status.TryUpdate());
        Status.Open();
        Observer.Observe('reopen', Status.State());
        Status.ResetAll();
        Observer.Observe('clearall opened', Again.State());
        Observer.Observe('update after clearall', Again.TryUpdate());
        Again.Open();
        Status.ResetVar();
        Observer.Observe('clear var parameter', Status.State());
        Observer.Observe('update after var clear', Status.TryUpdate());
        Status.Reset();
        Observer.Finish();
    end;
}

// Reporter shape of al-runner issue 6656: a SingleInstance status dialog with a Reset that clears the Dialog. Used only by test codeunit 71206.
codeunit 93300 "LT Y64 Status Dialog"
{
    SingleInstance = true;

    var
        IsOpen: Boolean;
        Window: Dialog;

    procedure Open()
    begin
        IsOpen := true;
        Window.Open('#1####');
    end;

    procedure Reset()
    begin
        Clear(IsOpen);
        Clear(Window);
    end;

    procedure ResetAll()
    begin
        ClearAll();
    end;

    procedure ResetVar()
    begin
        ClearDialog(Window);
        Clear(IsOpen);
    end;

    local procedure ClearDialog(var Dlg: Dialog)
    begin
        Clear(Dlg);
    end;

    procedure State(): Text
    begin
        exit('IsOpen=' + Format(IsOpen));
    end;

    procedure TryUpdate(): Text
    begin
        ClearLastError();
        if DoUpdate() then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure DoUpdate()
    begin
        Window.Update(1, 'x');
    end;
}
