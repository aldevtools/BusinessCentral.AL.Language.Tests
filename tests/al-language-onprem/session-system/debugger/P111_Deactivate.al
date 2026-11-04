// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61217 "LT P111 Dbg Deactivate"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_first()
    begin
        Debugger.Deactivate();
    end;

    [TryFunction]
    local procedure Try_second()
    begin
        Debugger.Deactivate();
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
    procedure P111_Deactivate_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Try_first();
        Note(Observer, 'first', Ok);
        Ok := Try_second();
        Note(Observer, 'second', Ok);
        Observer.Expect('first_ok', 'No');
        Observer.Expect('first_code', 'ObsoleteMethod');
        Observer.Expect('first_text', 'The Deactivate method is obsolete.');
        Observer.Expect('second_ok', 'No');
        Observer.Expect('second_code', 'ObsoleteMethod');
        Observer.Expect('second_text', 'The Deactivate method is obsolete.');
        Observer.Verify();
    end;
}
