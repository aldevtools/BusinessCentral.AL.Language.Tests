// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61218 "LT P111 Dbg SessionIds"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_debugged(var Result: Text)
    begin
        Result := Format(Debugger.DebuggedSessionID());
    end;

    [TryFunction]
    local procedure Try_debugging(var Result: Text)
    begin
        Result := Format(Debugger.DebuggingSessionID());
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
    procedure P111_SessionIds_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        Ok := Try_debugged(Result);
        Note(Observer, 'debugged', Ok);
        if Ok then
            Observer.Observe('debugged_value', CopyStr(Result, 1, 120));
        Ok := Try_debugging(Result);
        Note(Observer, 'debugging', Ok);
        if Ok then
            Observer.Observe('debugging_value', CopyStr(Result, 1, 120));
        Observer.Expect('debugged_ok', 'No');
        Observer.Expect('debugged_code', 'ObsoleteMethod');
        Observer.Expect('debugged_text', 'The DebuggedSessionId method is obsolete.');
        Observer.Expect('debugging_ok', 'No');
        Observer.Expect('debugging_code', 'ObsoleteMethod');
        Observer.Expect('debugging_text', 'The DebuggingSessionID method is obsolete.');
        Observer.Verify();
    end;
}
