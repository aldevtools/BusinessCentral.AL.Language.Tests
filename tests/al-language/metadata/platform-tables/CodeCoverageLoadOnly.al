// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoverageload-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74024
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: CodeCoverageLoad called with logging inactive: no error or error text
// BC versions: 29
// Tag: P95

codeunit 74024 "LT P95 CodeCoverage Load"
{
    Subtype = Test;
    TestPermissions = Disabled;


    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryLoad()
    begin
        CodeCoverageLoad();
    end;

    [Test]
    procedure CodeCoverageLoadOnly()
    var
        Observer: Codeunit "Probe Observer";

    begin
        if TryLoad() then
            Observer.Observe('load', 'ok')
        else
            Observer.Observe('load', Err());
        if TryLoad() then
            Observer.Observe('load_again', 'ok')
        else
            Observer.Observe('load_again', Err());

        Observer.Expect('load', 'error:Code coverage must be enabled before calling CODECOVERAGELOAD.|AL');
        Observer.Expect('load_again', 'error:Code coverage must be enabled before calling CODECOVERAGELOAD.|AL');
        Observer.Verify();
    end;

}
