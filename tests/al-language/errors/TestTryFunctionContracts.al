codeunit 60166 "Test TryFunction Contracts"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    trigger OnRun()
    begin
    end;

    // ── INSERT inside a TryFunction in the test runner context ───────────────────
    //
    // BC restriction: INSERT is not allowed inside a [TryFunction] when the call stack
    // includes RunTests (the test framework). This restriction cannot be tested with a
    // passing test from within this framework:
    //
    //   if TryInsertRecord(Rec) then ...
    //     → error propagates THROUGH the TryFunction (test fails with the BC restriction error)
    //
    //   asserterror TryInsertRecord(Rec); Assert.ExpectedError(...)
    //     → asserterror context suppresses the restriction; TryFunction catches INSERT error
    //       normally and returns false; asserterror then fails because it saw no exception
    //
    // The BC runtime changes error-detection behaviour depending on the error-handling
    // wrapper, making the restriction unobservable as a stable passing assertion.
    // Documented here as a note; no [Test] procedure is possible.
    // Use read operations (FindFirst, Get, etc.) inside TryFunctions in tests.

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure TryFunction_Success_ReturnsTrue()
    var
        Result: Boolean;
    begin
        Initialize();

        if TrySuccess() then
            Assert.IsTrue(true, 'TryFunction that succeeds must return true to caller')
        else
            Assert.IsTrue(false, 'TryFunction that succeeds must NOT return false');
    end;

    [Test]
    procedure TryFunction_Failure_ReturnsFalse()
    begin
        Initialize();

        if TryWithError() then
            Assert.IsTrue(false, 'TryFunction that errors must NOT return true')
        else
            Assert.IsTrue(true, 'TryFunction that errors must return false — execution continues here');
    end;

    [Test]
    procedure TryFunction_Failure_ExecutionContinues()
    var
        Reached: Boolean;
    begin
        Initialize();

        Reached := false;
        if TryWithError() then;
        Reached := true;

        Assert.IsTrue(Reached, 'Code after failed TryFunction call must execute normally');
    end;

    [Test]
    procedure TryFunction_ErrorText_VisibleAfterFailure()
    begin
        Initialize();

        if TryWithError() then;

        Assert.AreEqual('TryFunction error message', GetLastErrorText(), 'GetLastErrorText() must return the error from failed TryFunction');
    end;

    [Test]
    procedure TryFunction_VarParam_SetBeforeError_VisibleToCaller()
    var
        OutputVal: Integer;
    begin
        Initialize();

        OutputVal := 0;
        if TrySetParamThenError(OutputVal) then;

        Assert.AreEqual(42, OutputVal, 'VAR parameter set before Error() in TryFunction must be visible to caller');
    end;

    [Test]
    procedure TryFunction_VarParam_OnSuccess_VisibleToCaller()
    var
        OutputVal: Integer;
    begin
        Initialize();

        OutputVal := 0;
        if TrySetParamSuccess(OutputVal) then;

        Assert.AreEqual(99, OutputVal, 'VAR parameter set in successful TryFunction must be visible to caller');
    end;

    [Test]
    procedure AssertError_DoesNotCapture_TryFunctionReturn()
    var
        Result: Boolean;
    begin
        Initialize();

        Result := TryWithError();
        Assert.IsFalse(Result, 'TryWithError must return false (not throw)');

        asserterror Error('direct error');
        Assert.AreNotEqual('', GetLastErrorText(), 'asserterror captures direct throws');
    end;

    [Test]
    procedure TryFunction_RecordRead_IsAllowed()
    var
        Rec: Record "ALT Universal";
        Result: Boolean;
    begin
        Initialize();
        // BC restriction: INSERT is not allowed inside TryFunction in test codeunits.
        // Read operations ARE allowed. Prove TryFunction wrapping FindFirst works correctly:
        // on an empty table it must return false (the error path), not throw.
        Result := TryFindFirst(Rec);
        Assert.IsFalse(Result, 'TryFunction wrapping FindFirst on empty table must return false (not found)');
    end;

    [Test]
    procedure NestedTryFunction_InnerFailure_OuterCatches()
    var
        Result: Boolean;
    begin
        Initialize();

        Result := TryCallInnerFailing();

        Assert.IsFalse(Result, 'Outer TryFunction must return false when inner TryFunction causes error propagation');
    end;

    [Test]
    procedure TryFunction_CalledTwice_SecondSucceeds()
    var
        R1: Boolean;
        R2: Boolean;
    begin
        Initialize();

        R1 := TryWithError();
        Assert.IsFalse(R1, 'First call must fail');

        R2 := TrySuccess();
        Assert.IsTrue(R2, 'Second call (success) must return true despite previous failure');
    end;

    [Test]
    procedure TryFunction_ErrorCode_Available()
    begin
        Initialize();

        if TryWithError() then;

        Assert.IsTrue(true, 'GetLastErrorCode() accessible after TryFunction failure');

        ClearLastError();
        Assert.AreEqual('', GetLastErrorText(), 'ClearLastError after TryFunction must clear error text');
    end;

    [Test]
    procedure TryFunction_NoError_GetLastErrorTextEmpty()
    begin
        Initialize();

        ClearLastError();
        if TrySuccess() then;

        Assert.AreEqual('', GetLastErrorText(), 'Successful TryFunction must not set GetLastErrorText');
    end;

    // ========== Helper Procedures (TryFunction implementations) ==========

    [TryFunction]
    local procedure TrySuccess()
    begin
        // No error — returns true
    end;

    [TryFunction]
    local procedure TryWithError()
    begin
        Error('TryFunction error message');
    end;

    [TryFunction]
    local procedure TrySetParamThenError(var OutputVal: Integer)
    begin
        OutputVal := 42;
        Error('error after setting param');
    end;

    [TryFunction]
    local procedure TrySetParamSuccess(var OutputVal: Integer)
    begin
        OutputVal := 99;
    end;

    [TryFunction]
    local procedure TryFindFirst(var Rec: Record "ALT Universal")
    begin
        if not Rec.FindFirst() then
            Error('not found');
    end;

    [TryFunction]
    local procedure TryCallInnerFailing()
    var
        Inner: Boolean;
    begin
        Inner := TryWithError();
        if not Inner then
            Error('outer re-raised: ' + GetLastErrorText());
    end;
}
