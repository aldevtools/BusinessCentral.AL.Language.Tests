// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/dialog/dialog-data-type
// Scope: in-scope
// Fixtures used: none (self-contained)
// Note: proves a BC progress (status) Dialog is a faithful headless no-op —
// code after Dialog.Open/Update/Close must run to completion identically
// for every Update overload, including the no-argument one
// whether or not a window appeared, and must not swallow a subsequent error.
// BC versions: 24+

codeunit 60218 "Test Handlers Dialog NoOp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Window: Dialog;

    [Test]
    procedure ProgressDialog_OpenUpdateClose_IsNoOp_CodeAfterRuns()
    var
        Counter: Integer;
        Total: Integer;
    begin
        Initialize();
        // [GIVEN] a progress dialog with an integer parameter token (#1#####).
        //         The token forces NavDialog.ALOpenAsync<T> to build a
        //         NavFormSourceExpressionGetterAsync[] — the exact path that NREd.
        Window.Open('Processing record #1######');

        // [WHEN] the dialog is updated and closed, and real work runs in between
        Total := 0;
        for Counter := 1 to 5 do begin
            Window.Update(1, Counter);
            Total += Counter;
        end;
        Window.Close();

        // [THEN] the code after Dialog.Open/Update/Close ran to completion and
        //        produced a concrete value (1+2+3+4+5 = 15). If the dialog had
        //        thrown (the old NRE) or swallowed control flow, Total would be 0.
        Assert.AreEqual(15, Total, 'Code after a progress Dialog must run and accumulate.');
    end;

    [Test]
    procedure ProgressDialog_DoesNotSwallowSubsequentError()
    begin
        Initialize();
        // [GIVEN] a progress dialog is opened (headless no-op) ...
        Window.Open('Working #1######');
        Window.Update(1, 1);

        // [WHEN] AL code after the dialog raises an error
        // [THEN] that error must still propagate — the dialog no-op must not
        //        disturb normal control flow or swallow the exception.
        asserterror Error('BOOM-AFTER-DIALOG');
        Assert.ExpectedError('BOOM-AFTER-DIALOG');

        Window.Close();
    end;

    [Test]
    procedure ProgressDialog_UpdateWithNoArguments_IsNoOp_CodeAfterRuns()
    var
        Counter: Integer;
        Total: Integer;
    begin
        Initialize();
        // [GIVEN] a progress dialog with an integer parameter token (#1#####).
        Window.Open('Processing record #1######');

        // [WHEN] the dialog is updated with NO arguments. Both of Dialog.Update's
        //        parameters are optional: `Update()` updates every '#'/'@' field in
        //        the active window using the values of the variables named in Open.
        //        That is a DIFFERENT platform overload from Update(Number) and
        //        Update(Number, Value), which the two tests above already cover —
        //        so it is the one form of Dialog.Update this codeunit never reached.
        Total := 0;
        for Counter := 1 to 5 do begin
            Window.Update();
            Total += Counter;
        end;
        Window.Close();

        // [THEN] the code after it ran to completion and produced a concrete value
        //        (1+2+3+4+5 = 15). If the no-argument overload had thrown, Total
        //        would be 0.
        Assert.AreEqual(15, Total, 'Code after a no-argument Dialog.Update must run and accumulate.');
    end;

    [Test]
    procedure ProgressDialog_UpdateWithNoArguments_DoesNotSwallowSubsequentError()
    begin
        Initialize();
        // [GIVEN] a progress dialog updated with no arguments ...
        Window.Open('Working #1######');
        Window.Update();

        // [WHEN] AL code after it raises an error
        // [THEN] that error must still propagate — the no-argument overload must not
        //        disturb normal control flow or swallow the exception.
        asserterror Error('BOOM-AFTER-NOARG-UPDATE');
        Assert.ExpectedError('BOOM-AFTER-NOARG-UPDATE');

        Window.Close();
    end;

    local procedure Initialize()
    begin
    end;

    // Writer BP (corpus issue 664, microsoft/AL issue 2689): an array of Dialog (once a compiler crash) compiles, and each element is
    // a progress dialog that is a headless no-op like a single Dialog variable.
    [Test]
    procedure ProgressDialog_ArrayOfDialog_EachElementIsNoOp_BP()
    var
        Windows: array[5] of Dialog;
        Counter: Integer;
        Total: Integer;
    begin
        Initialize();
        for Counter := 1 to 5 do
            Windows[Counter].Open('Step ' + Format(Counter) + ' #1######');
        for Counter := 1 to 5 do begin
            Windows[Counter].Update(1, Counter * 10);
            Total += Counter;
        end;
        for Counter := 1 to 5 do
            Windows[Counter].Close();
        Assert.AreEqual(15, Total, 'the code after Open, Update and Close of every array element ran');
        Assert.AreEqual(5, ArrayLen(Windows), 'ArrayLen of an array of Dialog');
    end;
}
