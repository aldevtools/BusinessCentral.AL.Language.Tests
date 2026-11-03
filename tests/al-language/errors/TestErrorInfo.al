// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope (ErrorInfo type is OnPrem-only; testing error text patterns available in Cloud)

codeunit 60084 "Test ErrorInfo"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure Error_SimpleMessage_CapturedByAssertError()
    begin
        Initialize();
        asserterror Error('Simple');
        Assert.AreEqual('Simple', GetLastErrorText(), 'simple error message must be captured exactly');
    end;

    [Test]
    procedure Error_WithPlaceholder_FormatsCorrectly()
    begin
        Initialize();
        asserterror Error('Value: %1', 42);
        Assert.IsTrue(StrPos(GetLastErrorText(), '42') > 0, 'placeholder must be replaced with argument value');
    end;

    [Test]
    procedure Error_MultipleArgs_FormatsAll()
    var
        ErrText: Text;
    begin
        Initialize();
        asserterror Error('%1 + %2 = %3', 1, 2, 3);
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, '1') > 0, 'first argument must be in formatted error');
        Assert.IsTrue(StrPos(ErrText, '3') > 0, 'third argument must be in formatted error');
    end;

    [Test]
    procedure Error_StringAndIntegerArgs_FormatsAll()
    var
        ErrText: Text;
    begin
        Initialize();
        asserterror Error('Name is %1, Age is %2', 'Alice', 30);
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'Alice') > 0, 'string argument must appear in error');
        Assert.IsTrue(StrPos(ErrText, '30') > 0, 'integer argument must appear in error');
    end;

    [Test]
    procedure Error_GetLastErrorCallStack_IsCallable()
    var
        CallStack: Text;
    begin
        Initialize();
        asserterror Error('stack test');
        CallStack := GetLastErrorCallStack();
        Assert.IsTrue(true, 'GetLastErrorCallStack must be callable without throwing');
    end;

    [Test]
    procedure Error_GetLastErrorCode_IsCallable()
    var
        Code: Text;
    begin
        Initialize();
        asserterror Error('code test');
        Code := GetLastErrorCode();
        Assert.IsTrue(true, 'GetLastErrorCode must be callable without throwing');
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;
}
