// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-activate-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Debugger.Activate with and without a result variable, in a TryFunction, outside a debugger session; the state the other Debugger members report afterwards.
// BC versions: 27, 28, 29
codeunit 61288 "LT P Dbg Activate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_activate_no_result()
    begin
        Debugger.Activate();
    end;

    [TryFunction]
    local procedure Try_activate_result(var Result: Boolean)
    begin
        Result := Debugger.Activate();
    end;

    [TryFunction]
    local procedure Try_is_active(var Result: Boolean)
    begin
        Result := Debugger.IsActive();
    end;

    local procedure Note(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        Observer.Observe(Name + '_ok', Format(Ok));
        if not Ok then begin
            Observer.Observe(Name + '_code', GetLastErrorCode());
            Observer.Observe(Name + '_text', CopyStr(GetLastErrorText(), 1, 120));
            ClearLastError();
        end;
    end;

    [Test]
    procedure PActivate_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Result: Boolean;
    begin
        ClearLastError();
        Ok := Try_activate_no_result();
        Note(Observer, 'no_result', Ok);
        Ok := Try_activate_result(Result);
        Note(Observer, 'with_result', Ok);
        if Ok then
            Observer.Observe('with_result_value', Format(Result));
        Ok := Try_is_active(Result);
        Note(Observer, 'is_active_after', Ok);
        if Ok then
            Observer.Observe('is_active_after_value', Format(Result));
        Observer.Expect('no_result_ok', 'No');
        Observer.Expect('no_result_code', 'ObsoleteMethod');
        Observer.Expect('no_result_text', 'The Activate method is obsolete.');
        Observer.Expect('with_result_ok', 'No');
        Observer.Expect('with_result_code', 'ObsoleteMethod');
        Observer.Expect('with_result_text', 'The Activate method is obsolete.');
        Observer.Expect('is_active_after_ok', 'No');
        Observer.Expect('is_active_after_code', 'ObsoleteMethod');
        Observer.Expect('is_active_after_text', 'The IsActive method is obsolete.');
        Observer.Verify();
    end;
}
