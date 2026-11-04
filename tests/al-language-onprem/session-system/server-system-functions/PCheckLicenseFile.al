// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-checklicensefile-method
// Scope: in-scope (OnPrem app only: Database.CheckLicenseFile)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61248
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: reads the license state only; key numbers that do not exist
//
// CheckLicenseFile(KeyNumber) with key numbers that do not exist (large, negative): outcome, error text and code. The license is never changed.
// BC versions: 29 (27 and 28 by CI)
codeunit 61248 "LT P109 CheckLicenseFile"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryCheck(KeyNumber: Integer)
    begin
        Database.CheckLicenseFile(KeyNumber);
    end;

    local procedure Outcome(KeyNumber: Integer): Text
    begin
        if TryCheck(KeyNumber) then
            exit('ok');
        exit('error:' + CopyStr(GetLastErrorText(), 1, 120) + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_CheckLicenseFile_UnknownKeys()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('key_9999', Outcome(9999));
        Observer.Observe('key_negative', Outcome(-1));
        Observer.Observe('key_max', Outcome(2147483647));
        Observer.Observe('key_min', Outcome(-2147483647));
        Observer.Expect('key_9999', 'ok');
        Observer.Expect('key_negative', 'error:Sorry, the current permissions prevented the action. (System -1 -1 Execute: AL Language Coverage Tests (OnPrem))|DB:ExecuteObjDenied');
        Observer.Expect('key_max', 'error:Sorry, the current permissions prevented the action. (System 2147483647 2147483647 Execute: AL Language Coverage Tests (|DB:ExecuteObjDenied');
        Observer.Expect('key_min', 'error:Sorry, the current permissions prevented the action. (System -2147483647 -2147483647 Execute: AL Language Coverage Tests|DB:ExecuteObjDenied');
        Observer.Verify();
    end;
}
