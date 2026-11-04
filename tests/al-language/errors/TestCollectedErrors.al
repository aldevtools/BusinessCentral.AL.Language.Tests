// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope

codeunit 60085 "Test Collected Errors"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure CollectedErrors_SingleError_CapturedByAssertError()
    begin
        Initialize();
        asserterror Error('error1');
        Assert.AreEqual('error1', GetLastErrorText(), 'single error must be captured exactly');
    end;

    [Test]
    procedure CollectedErrors_AfterClear_NoError()
    begin
        Initialize();
        asserterror Error('e');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'error must be cleared from last error buffer');
    end;

    [Test]
    procedure CollectedErrors_MultipleErrors_LastCaptured()
    begin
        Initialize();
        asserterror Error('error A');
        asserterror Error('error B');
        asserterror Error('final');
        Assert.AreEqual('final', GetLastErrorText(), 'last error in sequence must be captured');
    end;

    [Test]
    procedure CollectedErrors_ErrorInHelper_PropagatesUp()
    begin
        Initialize();
        asserterror ThrowError();
        Assert.AreNotEqual('', GetLastErrorText(), 'error from helper must propagate to outer scope');
    end;

    [Test]
    procedure CollectedErrors_NestedHelpers_PreservesError()
    var
        ErrText: Text;
    begin
        Initialize();
        asserterror OuterHelper();
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'inner') > 0, 'error from nested helper must be visible');
    end;

    [Test]
    procedure CollectedErrors_ClearBetweenErrors_Isolation()
    begin
        Initialize();
        asserterror Error('first');
        Assert.AreEqual('first', GetLastErrorText(), 'first error must be captured');
        ClearLastError();
        asserterror Error('second');
        Assert.AreEqual('second', GetLastErrorText(), 'second error after clear must not include first');
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;

    local procedure ThrowError()
    begin
        Error('from helper');
    end;

    local procedure OuterHelper()
    begin
        InnerHelper();
    end;

    local procedure InnerHelper()
    begin
        Error('inner error');
    end;
}
