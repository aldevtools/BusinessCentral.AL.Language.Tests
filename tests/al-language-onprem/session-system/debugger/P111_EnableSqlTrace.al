// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/debugger/debugger-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
codeunit 61219 "LT P111 Dbg EnableSqlTrace"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure Try_invalid_0()
    begin
        Debugger.EnableSqlTrace(0);
    end;

    [TryFunction]
    local procedure Try_invalid_neg1_false()
    begin
        Debugger.EnableSqlTrace(-1, false);
    end;

    [TryFunction]
    local procedure Try_invalid_neg1_true()
    begin
        Debugger.EnableSqlTrace(-1, true);
    end;

    [TryFunction]
    local procedure Try_own_false()
    begin
        Debugger.EnableSqlTrace(SessionId(), false);
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
    procedure P111_EnableSqlTrace_NoDebugger()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := Try_invalid_0();
        Note(Observer, 'invalid_0', Ok);
        Ok := Try_invalid_neg1_false();
        Note(Observer, 'invalid_neg1_false', Ok);
        Ok := Try_invalid_neg1_true();
        Note(Observer, 'invalid_neg1_true', Ok);
        Ok := Try_own_false();
        Note(Observer, 'own_false', Ok);
        Observer.Expect('invalid_0_ok', 'Yes');
        Observer.Expect('invalid_neg1_false_ok', 'Yes');
        Observer.Expect('invalid_neg1_true_ok', 'Yes');
        Observer.Expect('own_false_ok', 'Yes');
        Observer.Verify();
    end;
}
