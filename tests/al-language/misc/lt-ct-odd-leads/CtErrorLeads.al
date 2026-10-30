// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-error-collection
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-commitbehavior-attribute
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained table 85241 and codeunits 85242..85246
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: corpus issue 670 (odd AL behavior leads, part E), items 18, 19, 20, 22, 24, 25, 26, 27, 29 (writer CT):
//   an ErrorBehavior(Collect) callee inside a CommitBehavior(Error) caller; asserterror in a non-test codeunit followed by a write and Commit;
//   asserterror around an unhandled Confirm; backslashes in Message, Confirm and Error texts; ClearLastError after Codeunit.Run, in a
//   TryFunction and in a Collect scope; Codeunit.Run inside a Collect scope; database writes kept after ClearCollectedErrors and rolled back
//   by a Collect scope that ends with errors; the four call forms of a TryFunction raising Error(''); an error raised while a TryFunction
//   argument is evaluated; [TryFunction] on a [Test] procedure.
// BC versions: 29 (27 and 28 by CI)

table 85241 "LT CT Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

// Item 19: asserterror outside a test codeunit, then a write, a Commit and an error.
codeunit 85243 "LT CT Asserterror Runner"
{
    trigger OnRun()
    var
        Row: Record "LT CT Row";
    begin
        asserterror Error('');
        Row.Id := 19;
        Row.Name := 'after asserterror: ' + GetLastErrorText();
        Row.Insert();
        Commit();
        Row.Id := 1919;
        Row.Insert();
        Error('x');
    end;
}

// Items 22, 24, 27: a codeunit run by Codeunit.Run; the mode is in Rec.Name.
codeunit 85242 "LT CT Run Target"
{
    TableNo = "LT CT Row";

    trigger OnRun()
    var
        Row: Record "LT CT Row";
    begin
        case Rec.Name of
            'fail':
                Error('run failed');
            'post plain':
                begin
                    Row.Id := 24;
                    Row.Insert();
                    Error(ErrorInfo.Create('first collectible', true));
                    Error(ErrorInfo.Create('second collectible', true));
                    Error('x');
                end;
            'post collect only':
                begin
                    Row.Id := 241;
                    Row.Insert();
                    Error(ErrorInfo.Create('first collectible', true));
                    Error(ErrorInfo.Create('second collectible', true));
                end;
            'try argument if':
                begin
                    if TryFn(RaiseError()) then
                        Rec.Name := 'returned true'
                    else
                        Rec.Name := 'returned false: ' + GetLastErrorText();
                    Rec.Name += ' continued';
                end;
            'try argument assign':
                begin
                    Ok := TryFn(RaiseError());
                    Rec.Name := 'assigned ' + Format(Ok) + ': ' + GetLastErrorText() + ' continued';
                end;
            'try argument bare':
                begin
                    TryFn(RaiseError());
                    Rec.Name := 'bare continued';
                end;
        end;
    end;

    [TryFunction]
    local procedure TryFn(Input: Text)
    begin
    end;

    local procedure RaiseError(): Text
    begin
        Error('argument failed');
    end;

    var
        Ok: Boolean;
}

// Item 25: a Collect scope that inserts a row and ends with a collected error, run through Codeunit.Run.
codeunit 85244 "LT CT Collect Runner"
{
    trigger OnRun()
    begin
        InsertAndCollect();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure InsertAndCollect()
    var
        Row: Record "LT CT Row";
    begin
        Row.Id := 25;
        Row.Insert();
        Error(ErrorInfo.Create('left collected', true));
        Row.Id := 251;
        Row.Insert();
    end;
}

codeunit 85240 "LT CT Error Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // ---------------------------------------------------------------- item 18
    [CommitBehavior(CommitBehavior::Error)]
    local procedure CommitAfterCollectCallee()
    begin
        EmptyCollect();
        Commit();
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure CommitAfterPlainCallee()
    begin
        EmptyPlain();
        Commit();
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure EmptyCollect()
    begin
    end;

    local procedure EmptyPlain()
    begin
    end;

    // Raises the commit error, or 'commit ran' when Commit() ran without error.
    local procedure CallThenMark(Collect: Boolean)
    begin
        if Collect then
            CommitAfterCollectCallee()
        else
            CommitAfterPlainCallee();
        Error('commit ran');
    end;

    [Test]
    procedure Item18_CollectCallee_CommitBehaviorError()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror CallThenMark(false);
        Observer.ObserveError('plain callee');
        asserterror CallThenMark(true);
        Observer.ObserveError('collect callee');
        Observer.Expect('plain callee|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('plain callee|code', 'DB:Ok');
        Observer.Expect('collect callee|text', 'Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.');
        Observer.Expect('collect callee|code', 'DB:Ok');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 19
    [Test]
    procedure Item19_AsserterrorInNonTestCodeunit_ThenCommit()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        Ok := Codeunit.Run(Codeunit::"LT CT Asserterror Runner");
        Observer.Observe('run', Format(Ok));
        Observer.ObserveError('run error');
        Observer.Observe('committed row', Format(Row.Get(19)) + ' ' + Row.Name);
        Observer.Observe('row after commit', Format(Row.Get(1919)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('run', 'No');
        Observer.Expect('run error|text', 'x');
        Observer.Expect('run error|code', 'Dialog');
        Observer.Expect('committed row', 'Yes after asserterror: ');
        Observer.Expect('row after commit', 'No');
        Observer.Verify();
    end;

    local procedure ConfirmThenMark()
    begin
        if Confirm('Proceed?') then
            Error('confirm returned true');
        Error('confirm returned false');
    end;

    [Test]
    procedure Item19_AsserterrorAroundUnhandledConfirm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror ConfirmThenMark();
        Observer.ObserveError('confirm');
        Observer.Expect('confirm|text', 'Unhandled UI: Confirm Proceed?');
        Observer.Expect('confirm|code', 'MissingUIHandler');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 20
    [Test]
    [HandlerFunctions('CaptureMessage')]
    procedure Item20_Backslash_Message()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Message(OneArgBackslashLbl + SecondBackslashLbl + TwoArgBackslashLbl, 7, 'Tx');
        Observer.Observe('message labels', Captured);
        Message('%1\' + 'Second\' + '%2\', 7, 'Tx');
        Observer.Observe('message literals', Captured);
        Message('A\B\C');
        Observer.Observe('message no args', Captured);
        Message('\Lead');
        Observer.Observe('message leading', Captured);
        Observer.Expect('message labels', '7\Second\Tx\');
        Observer.Expect('message literals', '7\Second\Tx\');
        Observer.Expect('message no args', 'A\B\C');
        Observer.Expect('message leading', '\Lead');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CaptureConfirm')]
    procedure Item20_Backslash_Confirm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        if Confirm(OneArgBackslashLbl + SecondBackslashLbl + TwoArgBackslashLbl, false, 7, 'Tx') then;
        Observer.Observe('confirm labels', Captured);
        if Confirm('%1\' + 'Second\' + '%2\', false, 7, 'Tx') then;
        Observer.Observe('confirm literals', Captured);
        if Confirm('Value %1 and %2', false, 7, 'Tx') then;
        Observer.Observe('confirm no backslash', Captured);
        Observer.Expect('confirm labels', '%1\Second\%2\');
        Observer.Expect('confirm literals', '%1\Second\%2\');
        Observer.Expect('confirm no backslash', 'Value %1 and %2');
        Observer.Verify();
    end;

    [Test]
    procedure Item20_Backslash_Error()
    var
        Observer: Codeunit "Probe Observer";
    begin
        asserterror Error(OneArgBackslashLbl + SecondBackslashLbl + TwoArgBackslashLbl, 7, 'Tx');
        Observer.ObserveError('error labels');
        asserterror Error('%1\' + 'Second\' + '%2\', 7, 'Tx');
        Observer.ObserveError('error literals');
        Observer.Expect('error labels|text', '7\Second\Tx\');
        Observer.Expect('error labels|code', 'Dialog');
        Observer.Expect('error literals|text', '7\Second\Tx\');
        Observer.Expect('error literals|code', 'Dialog');
        Observer.Verify();
    end;

    [MessageHandler]
    procedure CaptureMessage(Msg: Text[1024])
    begin
        Captured := Msg;
    end;

    [ConfirmHandler]
    procedure CaptureConfirm(Question: Text[1024]; var Reply: Boolean)
    begin
        Captured := Question;
        Reply := false;
    end;

    // ---------------------------------------------------------------- item 22
    [Test]
    procedure Item22_ClearLastError_AfterCodeunitRun()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Row.Name := 'fail';
        Ok := Codeunit.Run(Codeunit::"LT CT Run Target", Row);
        Observer.Observe('run', Format(Ok));
        Observer.Observe('text before', GetLastErrorText());
        Observer.Observe('code before', GetLastErrorCode());
        Observer.Observe('stack before empty', Format(GetLastErrorCallStack() = ''));
        ClearLastError();
        Observer.Observe('text after', GetLastErrorText());
        Observer.Observe('text after true', GetLastErrorText(true));
        Observer.Observe('code after', GetLastErrorCode());
        Observer.Observe('stack after', GetLastErrorCallStack());
        Observer.Expect('run', 'No');
        Observer.Expect('text before', 'run failed');
        Observer.Expect('code before', 'Dialog');
        Observer.Expect('stack before empty', 'No');
        Observer.Expect('text after', '');
        Observer.Expect('text after true', '');
        Observer.Expect('code after', '');
        Observer.Expect('stack after', '');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryClearInside(var Log: Text)
    begin
        asserterror Error('inner');
        Log += 'inside before=' + GetLastErrorText() + ';';
        ClearLastError();
        Log += 'inside after=' + GetLastErrorText() + '|' + GetLastErrorCode() + ';';
    end;

    [TryFunction]
    local procedure TryClearThenRaise()
    begin
        ClearLastError();
        Error('raised after clear');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectThenClearLastError(var Log: Text)
    begin
        Error(ErrorInfo.Create('collected one', true));
        Log += 'collected text=' + GetLastErrorText() + '|' + GetLastErrorCode() + ';';
        ClearLastError();
        Log += 'after clear text=' + GetLastErrorText() + ' has=' + Format(HasCollectedErrors()) + ';';
        ClearCollectedErrors();
    end;

    [Test]
    procedure Item22_ClearLastError_TryFunctionAndCollect()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        ClearLastError();
        Observer.Observe('try returns', Format(TryClearInside(Log)));
        Observer.Observe('try log', Log);
        Observer.Observe('after try', GetLastErrorText());
        Observer.Observe('clear then raise', Format(TryClearThenRaise()));
        Observer.ObserveError('clear then raise');
        Log := '';
        CollectThenClearLastError(Log);
        Observer.Observe('collect log', Log);
        Observer.Observe('after collect', GetLastErrorText());
        Observer.Expect('try returns', 'Yes');
        Observer.Expect('try log', 'inside before=inner;inside after=|;');
        Observer.Expect('after try', '');
        Observer.Expect('clear then raise', 'No');
        Observer.Expect('clear then raise|text', 'raised after clear');
        Observer.Expect('clear then raise|code', 'Dialog');
        Observer.Expect('collect log', 'collected text=|;after clear text= has=Yes;');
        Observer.Expect('after collect', '');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 24
    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure RunInCollectScope(Mode: Text; var Log: Text)
    var
        Row: Record "LT CT Row";
        Errors: List of [ErrorInfo];
        Info: ErrorInfo;
    begin
        Row.Name := CopyStr(Mode, 1, MaxStrLen(Row.Name));
        ClearLastError();
        if not Codeunit.Run(Codeunit::"LT CT Run Target", Row) then
            Log += 'run false;'
        else
            Log += 'run true;';
        Log += 'text=' + GetLastErrorText() + ';';
        Log += 'has=' + Format(HasCollectedErrors()) + ';';
        Errors := GetCollectedErrors();
        Log += 'count=' + Format(Errors.Count()) + ';';
        foreach Info in Errors do
            Log += 'msg=' + Info.Message() + ';';
        ClearCollectedErrors();
    end;

    [Test]
    procedure Item24_CodeunitRun_InCollectScope()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Row.DeleteAll();
        Commit();
        RunInCollectScope('post plain', Log);
        Observer.Observe('plain log', Log);
        Observer.Observe('plain row kept', Format(Row.Get(24)));
        Log := '';
        RunInCollectScope('post collect only', Log);
        Observer.Observe('collect only log', Log);
        Observer.Observe('collect only row kept', Format(Row.Get(241)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('plain log', 'run false;text=x;has=Yes;count=2;msg=first collectible;msg=second collectible;');
        Observer.Expect('plain row kept', 'No');
        Observer.Expect('collect only log', 'run true;text=;has=Yes;count=2;msg=first collectible;msg=second collectible;');
        Observer.Expect('collect only row kept', 'Yes');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 25
    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure InsertCollectClear(var Log: Text)
    var
        Row: Record "LT CT Row";
    begin
        Row.Id := 252;
        Row.Insert();
        Error(ErrorInfo.Create('to be cleared', true));
        Log += 'continued has=' + Format(HasCollectedErrors()) + ';';
        ClearCollectedErrors();
        Log += 'cleared has=' + Format(HasCollectedErrors()) + ';';
    end;

    [Test]
    procedure Item25_ClearCollectedErrors_KeepsWrites_ScopeEndRollsBack()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Log: Text;
        Ok: Boolean;
    begin
        Row.DeleteAll();
        Commit();
        InsertCollectClear(Log);
        Observer.Observe('clear log', Log);
        Observer.Observe('row after clear', Format(Row.Get(252)));
        Commit();
        Ok := Codeunit.Run(Codeunit::"LT CT Collect Runner");
        Observer.Observe('scope end run', Format(Ok));
        Observer.ObserveError('scope end');
        Observer.Observe('scope end first row', Format(Row.Get(25)));
        Observer.Observe('scope end second row', Format(Row.Get(251)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('clear log', 'continued has=Yes;cleared has=No;');
        Observer.Expect('row after clear', 'Yes');
        Observer.Expect('scope end run', 'No');
        Observer.Expect('scope end|text', 'left collected');
        Observer.Expect('scope end|code', 'Dialog');
        Observer.Expect('scope end first row', 'No');
        Observer.Expect('scope end second row', 'No');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- writer SP (2026-10-28): rollback probes
    // Durability of writes in a Collect scope whose errors are taken with GetCollectedErrors(true), read after an
    // unrelated error. Fixture: "LT SP Collect Get Runner" (89553).
    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure InsertCollectGetTrue(var Log: Text)
    var
        Row: Record "LT CT Row";
        Errors: List of [ErrorInfo];
    begin
        Row.Id := 2533;
        Row.Insert();
        Error(ErrorInfo.Create('taken by get', true));
        Errors := GetCollectedErrors(true);
        Log += 'count=' + Format(Errors.Count()) + ';has=' + Format(HasCollectedErrors()) + ';';
    end;

    [Test]
    procedure SP_GetCollectedErrorsTrue_DirectCall_DoesNotCommit()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Row.DeleteAll();
        Commit();
        InsertCollectGetTrue(Log);
        Observer.Observe('log', Log);
        Observer.Observe('row before error', Format(Row.Get(2533)));
        asserterror Error('unrelated');
        Observer.Observe('row after error', Format(Row.Get(2533)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('log', 'count=1;has=No;');
        Observer.Expect('row before error', 'Yes');
        Observer.Expect('row after error', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SP_GetCollectedErrorsTrue_InCodeunitRun_RunCommits()
    var
        Row: Record "LT CT Row";
        Runner: Codeunit "LT SP Collect Get Runner";
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Commit();
        ClearLastError();
        Observer.Observe('run', Format(Runner.Run()));
        Observer.Observe('lasterror', GetLastErrorText());
        Observer.Observe('log', Runner.GetLog());
        asserterror Error('unrelated');
        Observer.Observe('first row', Format(Row.Get(2531)));
        Observer.Observe('second row', Format(Row.Get(2532)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('run', 'Yes');
        Observer.Expect('lasterror', '');
        Observer.Expect('log', 'count=1;has=No;');
        Observer.Expect('first row', 'Yes');
        Observer.Expect('second row', 'Yes');
        Observer.Verify();
    end;

    // Item 24 follow-up: the caller collects, the run codeunit ("LT CT Run Target", no ErrorBehavior attribute) raises
    // two collectible errors. Is the run codeunit's row durable once the guarded run returns true?
    [Test]
    procedure SP_CallerCollects_RunCodeunitWithoutAttribute_RowDurable()
    var
        Row: Record "LT CT Row";
        Observer: Codeunit "Probe Observer";
        Log: Text;
    begin
        Row.DeleteAll();
        Commit();
        RunInCollectScope('post collect only', Log);
        Observer.Observe('log', Log);
        asserterror Error('unrelated');
        Observer.Observe('row after error', Format(Row.Get(241)));
        Row.DeleteAll();
        Commit();
        Observer.Expect('log', 'run true;text=;has=Yes;count=2;msg=first collectible;msg=second collectible;');
        Observer.Expect('row after error', 'Yes');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 26
    [TryFunction]
    local procedure DoWorkEmpty()
    begin
        Error('');
    end;

    [TryFunction]
    local procedure DoWorkText()
    begin
        Error('work failed');
    end;

    [Test]
    procedure Item26_TryFunction_CallForms_EmptyError()
    var
        Observer: Codeunit "Probe Observer";
        Result: Boolean;
    begin
        ClearLastError();
        asserterror DoWorkEmpty();
        Observer.ObserveError('empty bare');
        Result := DoWorkEmpty();
        Observer.Observe('empty assign', Format(Result));
        Observer.ObserveError('empty assign');
        if DoWorkEmpty() then
            Observer.Observe('empty if', 'true')
        else
            Observer.Observe('empty if', 'false');
        Observer.ObserveError('empty if');
        if not DoWorkEmpty() then
            Observer.Observe('empty if not', 'false')
        else
            Observer.Observe('empty if not', 'true');
        Observer.ObserveError('empty if not');
        asserterror DoWorkText();
        Observer.ObserveError('text bare');
        Result := DoWorkText();
        Observer.Observe('text assign', Format(Result));
        Observer.ObserveError('text assign');
        Observer.Expect('empty bare|text', '');
        Observer.Expect('empty bare|code', 'Dialog');
        Observer.Expect('empty assign', 'No');
        Observer.Expect('empty assign|text', '');
        Observer.Expect('empty assign|code', 'Dialog');
        Observer.Expect('empty if', 'false');
        Observer.Expect('empty if|text', '');
        Observer.Expect('empty if|code', 'Dialog');
        Observer.Expect('empty if not', 'false');
        Observer.Expect('empty if not|text', '');
        Observer.Expect('empty if not|code', 'Dialog');
        Observer.Expect('text bare|text', 'work failed');
        Observer.Expect('text bare|code', 'Dialog');
        Observer.Expect('text assign', 'No');
        Observer.Expect('text assign|text', 'work failed');
        Observer.Expect('text assign|code', 'Dialog');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 27
    local procedure RunArgumentMode(Mode: Text; Name: Text; var Observer: Codeunit "Probe Observer")
    var
        Row: Record "LT CT Row";
        Ok: Boolean;
    begin
        ClearLastError();
        Row.Name := CopyStr(Mode, 1, MaxStrLen(Row.Name));
        Ok := Codeunit.Run(Codeunit::"LT CT Run Target", Row);
        Observer.Observe(Name + ' run', Format(Ok));
        Observer.Observe(Name + ' name', Row.Name);
        Observer.ObserveError(Name);
    end;

    [Test]
    procedure Item27_TryFunction_ArgumentRaises()
    var
        Observer: Codeunit "Probe Observer";
    begin
        RunArgumentMode('try argument if', 'if', Observer);
        RunArgumentMode('try argument assign', 'assign', Observer);
        RunArgumentMode('try argument bare', 'bare', Observer);
        Observer.Expect('if run', 'Yes');
        Observer.Expect('if name', 'returned false: argument failed continued');
        Observer.Expect('if|text', 'argument failed');
        Observer.Expect('if|code', 'Dialog');
        Observer.Expect('assign run', 'Yes');
        Observer.Expect('assign name', 'assigned No: argument failed continued');
        Observer.Expect('assign|text', 'argument failed');
        Observer.Expect('assign|code', 'Dialog');
        Observer.Expect('bare run', 'No');
        Observer.Expect('bare name', 'try argument bare');
        Observer.Expect('bare|text', 'argument failed');
        Observer.Expect('bare|code', 'Dialog');
        Observer.Verify();
    end;

    // ---------------------------------------------------------------- item 29
    // [TryFunction] on a [Test] procedure compiles on BC 27, 28 and 29 (AL 30 compiler). A local BC 29.0 run showed that the test runner
    // ignores the attribute: the same procedure raising Error in its body fails as a test (not asserted: a failing test is no oracle).
    // Called from code, the procedure behaves as a try function: it returns false and the error text is kept.
    [Test]
    [TryFunction]
    procedure Item29_TryFunctionOnTest()
    begin
        if Item29Raise then
            Error('ct item 29 raised');
    end;

    [Test]
    procedure Item29_TryFunctionOnTest_CalledFromCode()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Item29Raise := true;
        Ok := Item29_TryFunctionOnTest();
        Item29Raise := false;
        Observer.Observe('raising call', Format(Ok));
        Observer.ObserveError('raising call');
        Ok := Item29_TryFunctionOnTest();
        Observer.Observe('quiet call', Format(Ok));
        Observer.Expect('raising call', 'No');
        Observer.Expect('raising call|text', 'ct item 29 raised');
        Observer.Expect('raising call|code', 'Dialog');
        Observer.Expect('quiet call', 'Yes');
        Observer.Verify();
    end;

    var
        Captured: Text;
        Item29Raise: Boolean;
        OneArgBackslashLbl: Label '%1\', Locked = true;
        SecondBackslashLbl: Label 'Second\', Locked = true;
        TwoArgBackslashLbl: Label '%2\', Locked = true;
}
