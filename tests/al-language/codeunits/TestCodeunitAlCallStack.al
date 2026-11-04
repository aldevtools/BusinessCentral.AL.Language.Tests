// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/getlasterrorcallstack-method
// Scope: in-scope
// Fixtures used: none (self-contained helper codeunit)
// BC versions: 24+

codeunit 60211 "Test Codeunit Al Call Stack"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure CallStack_AfterAssertError_ContainsALFrames()
    var
        Stack: Text;
    begin
        // Arrange — call a procedure that raises an AL error through a helper
        asserterror RaiseViaHelper();

        // Act — retrieve the call stack
        Stack := GetLastErrorCallStack();

        // Assert — the frame for THIS codeunit must appear with its object ID
        // (60211) and the mandatory app-tail tokens.
        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60211)'),
            'Call stack must contain "(CodeUnit 60211)". Actual stack: ' + Stack);

        Assert.IsTrue(
            Stack.Contains(' by '),
            'Call stack must contain the " by " publisher token');

        Assert.IsTrue(
            Stack.Contains(' version '),
            'Call stack must contain the " version " token from app.json');

        // The helper frame must also appear with its object ID (60212)
        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60212)'),
            'Call stack must contain "(CodeUnit 60212)" for the helper codeunit');

        // Every frame must include a line number
        Assert.IsTrue(
            Stack.Contains(' line '),
            'Call stack must contain " line " (AL source line numbers)');
    end;

    [Test]
    procedure CallStack_WhenNoError_ReturnsEmpty()
    var
        Stack: Text;
    begin
        Initialize();
        // No error was raised in THIS test — GetLastErrorCallStack must return
        // empty / blank. Explicitly clear first: BC does not reset the
        // last-error call stack between [Test] methods in the same codeunit
        // run, so a prior test's asserterror (e.g.
        // CallStack_AfterAssertError_ContainsALFrames) would otherwise leak
        // its stack into this assertion.
        ClearLastError();
        Stack := GetLastErrorCallStack();
        Assert.AreEqual('', Stack, 'GetLastErrorCallStack must be empty when no error occurred');
    end;

    [Test]
    procedure CallStack_ErrorInsideOnRunTrigger_MarksTheFrameAsATrigger()
    // CLAIM: a frame for an AL TRIGGER carries the "(Trigger)" marker BC appends directly
    // after the method name, and a frame for an ordinary procedure does not. Both frames are
    // produced by the same mechanism in the same stack, so the pair pins the DISTINCTION
    // rather than merely the presence of the token somewhere in the text.
    var
        TriggerHelper: Codeunit "AL Call Stack Trigger Helper";
        Stack: Text;
    begin
        ClearLastError();

        // Arrange/Act — Run() enters the helper's OnRun trigger, which errors.
        asserterror TriggerHelper.Run();
        Stack := GetLastErrorCallStack();

        // Assert — the trigger frame names the helper AND is marked as a trigger.
        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60228)'),
            'Call stack must contain "(CodeUnit 60228)" for the trigger helper. Actual stack: ' + Stack);

        Assert.IsTrue(
            Stack.Contains('OnRun(Trigger)'),
            'The OnRun trigger frame must be marked "OnRun(Trigger)". Actual stack: ' + Stack);
    end;

    [Test]
    procedure CallStack_ErrorInsideAProcedure_DoesNotMarkTheFrameAsATrigger()
    // CLAIM: the negative half of the pair above. RaiseError is an ordinary procedure, so its
    // frame carries the method name with NO "(Trigger)" marker. Without this arm a runner that
    // marked EVERY frame as a trigger would pass the positive test.
    var
        Stack: Text;
    begin
        ClearLastError();

        asserterror RaiseViaHelper();
        Stack := GetLastErrorCallStack();

        Assert.IsTrue(
            Stack.Contains('(CodeUnit 60212)'),
            'Call stack must contain "(CodeUnit 60212)" for the helper codeunit. Actual stack: ' + Stack);

        Assert.IsFalse(
            Stack.Contains('RaiseError(Trigger)'),
            'A plain procedure frame must NOT be marked as a trigger. Actual stack: ' + Stack);
    end;

    local procedure Initialize()
    begin
    end;

    local procedure RaiseViaHelper()
    var
        Helper: Codeunit "AL Call Stack Helper";
    begin
        Helper.RaiseError();
    end;
}
