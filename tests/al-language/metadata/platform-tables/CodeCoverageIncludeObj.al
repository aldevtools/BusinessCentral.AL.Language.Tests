// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-codecoverageload-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained codeunit 74026
// Probe: written against BC 29 (P95 draft; observation only, the lead measures the facts)
// Facts: CodeCoverageInclude with AllObj rows: matching, no match, filter state
// BC versions: 29
// Tag: P95

codeunit 74026 "LT P95 CodeCoverage Include"
{
    Subtype = Test;
    TestPermissions = Disabled;


    local procedure Err(): Text
    begin
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryInclude(var AO: Record AllObj)
    begin
        CodeCoverageInclude(AO);
    end;

    [Test]
    procedure CodeCoverageIncludeObj()
    var
        Observer: Codeunit "Probe Observer";
        AO: Record AllObj;
    begin
        AO.SetRange("Object Type", AO."Object Type"::Codeunit);
        AO.SetRange("Object ID", 1);
        if TryInclude(AO) then
            Observer.Observe('codeunit_1', 'ok')
        else
            Observer.Observe('codeunit_1', Err());
        AO.Reset();
        AO.SetRange("Object Type", AO."Object Type"::Codeunit);
        AO.SetRange("Object ID", 2147483647);
        if TryInclude(AO) then
            Observer.Observe('no_match', 'ok')
        else
            Observer.Observe('no_match', Err());
        Observer.Observe('filters_kept', AO.GetFilters());

        Observer.Expect('codeunit_1', 'ok');
        Observer.Expect('no_match', 'ok');
        Observer.Expect('filters_kept', 'Object Type: Codeunit, Object ID: 2147483647');
        Observer.Verify();
    end;

}
