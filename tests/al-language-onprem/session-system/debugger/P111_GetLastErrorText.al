// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61220 "LT P111 Dbg GetLastErrorText"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_initial(var Result: Text)
    begin
        Result := Format(Debugger.GetLastErrorText());
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
    procedure P111_GetLastErrorText_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
        Result: Text;
    begin
        ClearLastError();
        Ok := Try_initial(Result);
        Note(Observer, 'initial', Ok);
        if Ok then
            Observer.Observe('initial_value', CopyStr(Result, 1, 120));
        Observer.Expect('initial_ok', 'No');
        Observer.Expect('initial_code', 'ObsoleteMethod');
        Observer.Expect('initial_text', 'The GetLastErrorText method is obsolete.');
        Observer.Verify();
    end;
}
