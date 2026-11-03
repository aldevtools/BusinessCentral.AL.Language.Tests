// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61212 "LT P111 Dbg Attach"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_invalid_0()
    begin
        Debugger.Attach(0);
    end;

    [TryFunction]
    local procedure Try_invalid_neg1()
    begin
        Debugger.Attach(-1);
    end;

    [TryFunction]
    local procedure Try_invalid_big()
    begin
        Debugger.Attach(2147483647);
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
    procedure P111_Attach_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Try_invalid_0();
        Note(Observer, 'invalid_0', Ok);
        Ok := Try_invalid_neg1();
        Note(Observer, 'invalid_neg1', Ok);
        Ok := Try_invalid_big();
        Note(Observer, 'invalid_big', Ok);
        Observer.Expect('invalid_0_ok', 'No');
        Observer.Expect('invalid_0_code', 'ObsoleteMethod');
        Observer.Expect('invalid_0_text', 'The Attach method is obsolete.');
        Observer.Expect('invalid_neg1_ok', 'No');
        Observer.Expect('invalid_neg1_code', 'ObsoleteMethod');
        Observer.Expect('invalid_neg1_text', 'The Attach method is obsolete.');
        Observer.Expect('invalid_big_ok', 'No');
        Observer.Expect('invalid_big_code', 'ObsoleteMethod');
        Observer.Expect('invalid_big_text', 'The Attach method is obsolete.');
        Observer.Verify();
    end;
}
