// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope

codeunit 60086 "Test GetLastError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure GetLastErrorText_AfterError_ReturnsMessage()
    begin
        Initialize();
        asserterror Error('msg');
        Assert.AreEqual('msg', GetLastErrorText(), 'must return exact error message');
    end;

    [Test]
    procedure GetLastErrorText_WithoutError_ReturnsEmpty()
    begin
        Initialize();
        Assert.AreEqual('', GetLastErrorText(), 'must be empty when no error was raised');
    end;

    [Test]
    procedure GetLastErrorText_AfterClearLastError_ReturnsEmpty()
    begin
        Initialize();
        asserterror Error('x');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'must be empty after ClearLastError');
    end;

    [Test]
    procedure GetLastErrorText_FormattedError_ReturnsFormatted()
    begin
        Initialize();
        asserterror Error('val=%1', 7);
        Assert.AreEqual('val=7', GetLastErrorText(), 'must return fully formatted message');
    end;

    [Test]
    procedure GetLastErrorText_MultipleFormatArgs_ReturnsComplete()
    var
        ErrText: Text;
    begin
        Initialize();
        asserterror Error('X=%1, Y=%2', 'A', 'B');
        ErrText := GetLastErrorText();
        Assert.IsTrue(StrPos(ErrText, 'A') > 0, 'first argument must be in error text');
        Assert.IsTrue(StrPos(ErrText, 'B') > 0, 'second argument must be in error text');
    end;

    [Test]
    procedure GetLastErrorCallStack_AfterError_IsCallable()
    var
        CallStack: Text;
    begin
        Initialize();
        asserterror Error('stack test');
        CallStack := GetLastErrorCallStack();
        Assert.IsTrue(true, 'GetLastErrorCallStack must be callable');
    end;

    [Test]
    procedure GetLastErrorCallStack_WithoutError_ReturnsEmpty()
    var
        CallStack: Text;
    begin
        Initialize();
        CallStack := GetLastErrorCallStack();
        Assert.AreEqual('', CallStack, 'GetLastErrorCallStack with no error must return empty');
    end;

    [Test]
    procedure GetLastErrorCode_AfterError_IsCallable()
    var
        Code: Text;
    begin
        Initialize();
        asserterror Error('code test');
        Code := GetLastErrorCode();
        Assert.IsTrue(true, 'GetLastErrorCode must be callable');
    end;

    [Test]
    procedure GetLastErrorCode_WithoutError_ReturnsEmpty()
    var
        Code: Text;
    begin
        Initialize();
        Code := GetLastErrorCode();
        Assert.AreEqual('', Code, 'GetLastErrorCode with no error must return empty');
    end;

    [Test]
    procedure GetLastErrorCode_DatabaseError_IsCallable()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
        Code: Text;
    begin
        Initialize();
        Rec."Entry No." := 999;
        Rec.Insert();
        Rec2."Entry No." := 999;
        asserterror Rec2.Insert();
        Code := GetLastErrorCode();
        Assert.IsTrue(true, 'GetLastErrorCode callable after database error');
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;
}
