// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61214 "LT P111 Dbg BreakOnError"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_false()
    begin
        Debugger.BreakOnError(false);
    end;

    [TryFunction]
    local procedure Try_true()
    begin
        Debugger.BreakOnError(true);
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
    procedure P111_BreakOnError_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Try_false();
        Note(Observer, 'false', Ok);
        Ok := Try_true();
        Note(Observer, 'true', Ok);
        Observer.Expect('false_ok', 'No');
        Observer.Expect('false_code', 'ObsoleteMethod');
        Observer.Expect('false_text', 'The BreakOnError method is obsolete.');
        Observer.Expect('true_ok', 'No');
        Observer.Expect('true_code', 'ObsoleteMethod');
        Observer.Expect('true_text', 'The BreakOnError method is obsolete.');
        Observer.Verify();
    end;
}
