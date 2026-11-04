// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-getlasterrortext-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160); own objects below
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: GetLastErrorText(true) and (false) when no error is pending: fresh test, after ClearLastError, after a successful TryFunction, after a handled-then-cleared error (assumption get-last-error-text-flag-without-error); errors/lt-last-error-and-events/P70_02LastErrFlag.al:342-344 pins the call after ClearLastError, and with an error pending.
// BC versions: 29 (27 and 28 by CI)

codeunit 70663 "LT LastErr FlagNoError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TrySucceeds()
    begin
    end;

    [TryFunction]
    local procedure TryFails()
    begin
        Error('boom');
    end;

    [Test]
    procedure Flag_FreshTest_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        ClearLastError();
        Observer.Observe('true', GetLastErrorText(true));
        Observer.Observe('false', GetLastErrorText(false));
        Observer.Observe('default', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('true', '');
        Observer.Expect('false', '');
        Observer.Expect('default', '');
        Observer.Expect('code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_AfterSuccessfulTryFunction_Result()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TrySucceeds();
        Observer.Observe('try_result', Format(Ok));
        Observer.Observe('true', GetLastErrorText(true));
        Observer.Observe('false', GetLastErrorText(false));
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('try_result', 'Yes');
        Observer.Expect('true', '');
        Observer.Expect('false', '');
        Observer.Expect('code', '');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_SuccessAfterFailedTryFunction_Result()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryFails();
        Observer.Observe('failed_try_result', Format(Ok));
        Observer.Observe('failed_false', GetLastErrorText(false));
        Ok := TrySucceeds();
        Observer.Observe('second_try_result', Format(Ok));
        Observer.Observe('after_success_true', GetLastErrorText(true));
        Observer.Observe('after_success_false', GetLastErrorText(false));
        Observer.Expect('failed_try_result', 'No');
        Observer.Expect('failed_false', 'boom');
        Observer.Expect('second_try_result', 'Yes');
        Observer.Expect('after_success_true', 'Use ERROR with a text constant to improve telemetry details');
        Observer.Expect('after_success_false', 'boom');
        Observer.Verify();
    end;

    [Test]
    procedure Flag_AfterClear_Result()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Ok := TryFails();
        Observer.Observe('failed_try_result', Format(Ok));
        ClearLastError();
        Observer.Observe('cleared_true', GetLastErrorText(true));
        Observer.Observe('cleared_false', GetLastErrorText(false));
        Observer.Expect('failed_try_result', 'No');
        Observer.Expect('cleared_true', '');
        Observer.Expect('cleared_false', '');
        Observer.Verify();
    end;
}
