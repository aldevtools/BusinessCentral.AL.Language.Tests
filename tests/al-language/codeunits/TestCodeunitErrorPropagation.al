// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope

codeunit 60082 "Test CU ErrorPropagation"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    // ── Error Handling and Propagation ───────────────────────────────────────

    [Test]
    procedure ErrorPropagation_Error_ThrowsWithMessage()
    var
        ErrorText: Text;
    begin
        asserterror Error('Test error message');
        ErrorText := GetLastErrorText();
        Assert.AreEqual('Test error message', ErrorText, 'Error must propagate exact message');
    end;

    [Test]
    procedure ErrorPropagation_Error_ClearLastError_ClearsText()
    begin
        asserterror Error('Some error');
        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'ClearLastError must empty the error text');
    end;

    [Test]
    procedure ErrorPropagation_NestedAssertError_CapturesInnerError()
    var
        ErrorText: Text;
        Found: Boolean;
    begin
        asserterror begin
            Error('Inner error');
        end;
        ErrorText := GetLastErrorText();
        Found := StrPos(ErrorText, 'Inner error') > 0;
        Assert.IsTrue(Found, 'Inner error message must be captured in error text');
    end;

    [Test]
    procedure ErrorPropagation_Error_FormatString_IncludesArgs()
    var
        ErrorText: Text;
        Found: Boolean;
    begin
        asserterror Error('Value is %1', 42);
        ErrorText := GetLastErrorText();
        Found := StrPos(ErrorText, '42') > 0;
        Assert.IsTrue(Found, 'Formatted error must include argument value (42)');
    end;

    [Test]
    procedure ErrorPropagation_NoError_GetLastErrorText_ReturnsEmpty()
    begin
        ClearLastError();
        // no error raised
        Assert.AreEqual('', GetLastErrorText(), 'Without error, GetLastErrorText must be empty');
    end;
}
