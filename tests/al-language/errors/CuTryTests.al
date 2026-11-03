// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors-using-try-methods
// Scope: in-scope
// Fixtures used: Probe Observer (69160), LT CU Row (85300)
// Corpus #670 items 32, 33, 34, 35: writes inside a [TryFunction] in the corpus container (expression form and statement form),
// temporary-record writes inside a TryFunction, and IsolatedStorage.Get into Text of a value stored as SecretText.
// BC versions: 27.5, 28.5, 29.0

codeunit 85310 "LT CU Try Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Initialize()
    var
        Row: Record "LT CU Row";
    begin
        Row.DeleteAll();
        Commit();
        ClearLastError();
    end;

    local procedure Rows(): Text
    var
        Row: Record "LT CU Row";
    begin
        exit(Format(Row.Count()));
    end;

    [TryFunction]
    local procedure TryInsertThenError(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Insert();
        Error('try error after insert');
    end;

    local procedure IfNotTryInsertThenError(Id: Integer; var Branch: Text)
    begin
        if not TryInsertThenError(Id) then
            Branch := 'not ok'
        else
            Branch := 'ok';
    end;

    [TryFunction]
    local procedure TryInsertOnly(Id: Integer)
    var
        Row: Record "LT CU Row";
    begin
        Row.Id := Id;
        Row.Insert();
    end;

    [TryFunction]
    local procedure TryTempWrites(var Log: Text)
    var
        Tmp: Record "LT CU Row" temporary;
    begin
        Tmp.Id := 1;
        Tmp.Insert();
        Log += 'insert;';
        Tmp.Name := 'changed';
        Tmp.Modify();
        Log += 'modify;';
        Tmp.ModifyAll(Name, 'all');
        Log += 'modifyall;';
        Tmp.DeleteAll();
        Log += 'deleteall;';
        Log += 'count=' + Format(Tmp.Count()) + ';';
    end;

    [TryFunction]
    local procedure TryGetText(StorageKey: Text; var Value: Text)
    begin
        IsolatedStorage.Get(StorageKey, DataScope::Module, Value);
    end;

    // Item 32/33: TryFunction that inserts and then errors, its result consumed.
    [Test]
    procedure TryInsertThenError_ExpressionForm()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        asserterror Ok := TryInsertThenError(1);
        Observer.Observe('expression|text', MaskRunnerScope(GetLastErrorText()));
        Observer.Observe('expression|code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows after', Rows());
        Commit();
        Observer.Observe('rows after commit', Rows());
        Observer.Expect('expression|text', 'Call to the function ''INSERT'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Expect('expression|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows after', '0');
        Observer.Expect('rows after commit', '0');
        Observer.Verify();
    end;

    // Item 32: the same in the `if not Try() then` form.
    [Test]
    procedure TryInsertThenError_IfNotForm()
    var
        Observer: Codeunit "Probe Observer";
        Branch: Text;
    begin
        Initialize();
        asserterror IfNotTryInsertThenError(2, Branch);
        Observer.ObserveError('if not');
        Observer.Observe('branch', Branch);
        Observer.Observe('rows after', Rows());
        Observer.Expect('if not|text', 'Call to the function ''INSERT'' is not allowed inside the call to ''TryInsertThenError_IfNotForm'' when it is used as a TryFunction.');
        Observer.Expect('if not|code', 'TryFunctionWrite');
        Observer.Expect('branch', '');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    // Item 32: a TryFunction called as a plain statement.
    [Test]
    procedure TryInsertThenError_StatementForm()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Initialize();
        asserterror TryInsertThenError(3);
        Observer.ObserveError('statement');
        Observer.Observe('rows after', Rows());
        Observer.Expect('statement|text', 'try error after insert');
        Observer.Expect('statement|code', 'Dialog');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    // Item 32/33: a TryFunction that only inserts, its result consumed.
    [Test]
    procedure TryInsertOnly_ExpressionForm()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Initialize();
        asserterror Ok := TryInsertOnly(4);
        Observer.Observe('expression|text', MaskRunnerScope(GetLastErrorText()));
        Observer.Observe('expression|code', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('rows after', Rows());
        Observer.Expect('expression|text', 'Call to the function ''INSERT'' is not allowed inside the call to ''<scope>'' when it is used as a TryFunction.');
        Observer.Expect('expression|code', 'TryFunctionWrite');
        Observer.Expect('ok', 'No');
        Observer.Expect('rows after', '0');
        Observer.Verify();
    end;

    // Item 34: Insert, Modify, ModifyAll, DeleteAll on a temporary record inside a TryFunction, its result consumed.
    [Test]
    procedure TryTemporaryWrites_ExpressionForm()
    var
        Observer: Codeunit "Probe Observer";
        Log: Text;
        Ok: Boolean;
    begin
        Initialize();
        Ok := TryTempWrites(Log);
        Observer.Observe('ok', Format(Ok));
        Observer.Observe('log', Log);
        Observer.Observe('lasterror', GetLastErrorText());
        Observer.Expect('ok', 'Yes');
        Observer.Expect('log', 'insert;modify;modifyall;deleteall;count=0;');
        Observer.Expect('lasterror', '');
        Observer.Verify();
    end;

    // Item 35: IsolatedStorage.Get into a Text of a value stored with SetEncrypted(SecretText), inside a TryFunction.
    [Test]
    procedure SecretText_GetIntoText_InTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Value: Text;
    begin
        Initialize();
        Secret := SecretStrSubstNo('lt-cu-secret');
        Observer.Observe('set', Format(IsolatedStorage.SetEncrypted('LTCU_s1', Secret, DataScope::Module)));
        Observer.Observe('try ok', Format(TryGetText('LTCU_s1', Value)));
        Observer.Observe('value', Value);
        Observer.Observe('lasterror', GetLastErrorText());
        Observer.Observe('lastcode', GetLastErrorCode());
        ClearLastError();
        Observer.Observe('set plain', Format(IsolatedStorage.Set('LTCU_s2', Secret, DataScope::Module)));
        Observer.Observe('try ok plain', Format(TryGetText('LTCU_s2', Value)));
        Observer.Observe('lasterror plain', GetLastErrorText());
        ClearLastError();
        IsolatedStorage.Delete('LTCU_s1', DataScope::Module);
        IsolatedStorage.Delete('LTCU_s2', DataScope::Module);
        Observer.Expect('set', 'Yes');
        Observer.Expect('try ok', 'No');
        Observer.Expect('value', '');
        Observer.Expect('lasterror', 'The operation was aborted to prevent exposing a secret value.');
        Observer.Expect('lastcode', 'ForbiddenSecretAccess');
        Observer.Expect('set plain', 'Yes');
        Observer.Expect('try ok plain', 'No');
        Observer.Expect('lasterror plain', 'The operation was aborted to prevent exposing a secret value.');
        Observer.Verify();
    end;

    // Item 35: the same Get called directly.
    [Test]
    procedure SecretText_GetIntoText_Direct()
    var
        Observer: Codeunit "Probe Observer";
        Secret: SecretText;
        Value: Text;
    begin
        Initialize();
        Secret := SecretStrSubstNo('lt-cu-secret');
        IsolatedStorage.SetEncrypted('LTCU_s3', Secret, DataScope::Module);
        asserterror IsolatedStorage.Get('LTCU_s3', DataScope::Module, Value);
        Observer.ObserveError('get');
        Observer.Observe('value', Value);
        Observer.Observe('stored after', Format(IsolatedStorage.Contains('LTCU_s3', DataScope::Module)));
        Observer.Expect('get|text', 'The operation was aborted to prevent exposing a secret value.');
        Observer.Expect('get|code', 'ForbiddenSecretAccess');
        Observer.Expect('value', '');
        Observer.Expect('stored after', 'No');
        Observer.Verify();
    end;

    // The error names the outermost method of the test runner, not anything in this app: 'RunTests' ("Test Runner - Mgt.",
    // the classic runner; BC 27.5 full run 39322214364) or 'RootMethodScope' (the TestRunnerHub runner; BC 28.5/29.0).
    // The scope name is masked so the pin holds under either runner (publisher, bump 29).
    local procedure MaskRunnerScope(ErrorText: Text): Text
    var
        Marker: Text;
        StartPos: Integer;
        EndPos: Integer;
    begin
        Marker := 'inside the call to ''';
        StartPos := ErrorText.IndexOf(Marker);
        if StartPos = 0 then
            exit(ErrorText);
        StartPos += StrLen(Marker);
        EndPos := ErrorText.Substring(StartPos).IndexOf('''');
        if EndPos = 0 then
            exit(ErrorText);
        exit(ErrorText.Substring(1, StartPos - 1) + '<scope>' + ErrorText.Substring(StartPos + EndPos - 1));
    end;
}
