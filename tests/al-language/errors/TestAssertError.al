// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-error-handling
// Scope: in-scope

codeunit 60083 "Test AssertError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure AssertError_Error_CapturesError()
    begin
        Initialize();
        asserterror Error('oops');
        Assert.IsTrue(GetLastErrorText() <> '', 'asserterror must capture error text');
    end;

    [Test]
    procedure AssertError_DatabaseError_CapturesDuplicate()
    var
        Rec: Record "ALT Universal";
        Rec2: Record "ALT Universal";
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        Rec2."Entry No." := 1;
        asserterror Rec2.Insert();
        Assert.AreNotEqual('', GetLastErrorText(), 'duplicate key must generate a captured error');
    end;

    [Test]
    procedure AssertError_NestedError_CapturesInnermost()
    begin
        Initialize();
        asserterror Error('inner error');
        Assert.IsTrue(StrPos(GetLastErrorText(), 'inner error') > 0, 'nested error text must be captured');
    end;

    [Test]
    procedure AssertError_FormattedError_IncludesArg()
    begin
        Initialize();
        asserterror Error('Count is %1', 99);
        Assert.IsTrue(StrPos(GetLastErrorText(), '99') > 0, 'formatted argument must appear in error text');
    end;

    [Test]
    procedure AssertError_AfterClearLastError_Empty()
    begin
        Initialize();
        asserterror Error('x');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'error text must be empty after ClearLastError');
    end;

    [Test]
    procedure AssertError_MultipleErrors_LastErrorPreserved()
    begin
        Initialize();
        asserterror Error('error 1');
        asserterror Error('error 2');
        asserterror Error('final');
        Assert.AreEqual('final', GetLastErrorText(), 'last asserterror must capture most recent error');
    end;

    [Test]
    procedure AssertError_ClearLastError_Then_NoError()
    begin
        Initialize();
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'GetLastErrorText must be empty when no error was raised');
    end;

    local procedure Initialize()
    begin
        ClearLastError();
        Cleanup.Initialize();
    end;
}
