// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/navapp/navapp-getcallercallstackmoduleinfos-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: which apps NavApp.GetCallerCallstackModuleInfos() lists while a [Test] procedure runs (ids, names, order, count), and whether the
// Test Runner app (23de40a6-dfe8-4f80-80db-d70f83ce8caf) is among them.

// Runs only where the leg executes tests through Microsoft's Test Runner app (the corpus CI does that on 27.5; from 28.0 it runs them
// through altool, which has no Test Runner frames: count 0 there, also through a helper). That is the test host, not a BC version difference.
#if not BC28PLUS
codeunit 99830 "LT SS Caller Modules"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Describe(Infos: List of [ModuleInfo]): Text
    var
        Info: ModuleInfo;
        Result: Text;
    begin
        foreach Info in Infos do
            Result += Format(Info.Id) + '=' + Info.Name + ' | ';
        exit(Result);
    end;

    [Test]
    procedure CallerModules_InTest_ListsApps()
    var
        Observer: Codeunit "Probe Observer";
        Infos: List of [ModuleInfo];
        Info: ModuleInfo;
        Found: Boolean;
    begin
        Infos := NavApp.GetCallerCallstackModuleInfos();
        foreach Info in Infos do
            if Info.Id = '{23de40a6-dfe8-4f80-80db-d70f83ce8caf}' then
                Found := true;
        Observer.Observe('count', Format(Infos.Count()));
        Observer.Observe('test_runner_listed', Format(Found));
        Observer.Observe('apps', Describe(Infos));
        Observer.Expect('count', '1');
        Observer.Expect('test_runner_listed', 'Yes');
        Observer.Expect('apps', '{23DE40A6-DFE8-4F80-80DB-D70F83CE8CAF}=Test Runner | ');
        Observer.Verify();
    end;

    [Test]
    procedure CallerModules_ThroughHelper_ListsApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('apps', Describe(Ask()));
        Observer.Expect('apps', '{A1B2C3D4-E5F6-7890-ABCD-EF1234567890}=AL Language Coverage Tests | {23DE40A6-DFE8-4F80-80DB-D70F83CE8CAF}=Test Runner | ');
        Observer.Verify();
    end;

    local procedure Ask(): List of [ModuleInfo]
    begin
        exit(NavApp.GetCallerCallstackModuleInfos());
    end;
}
#endif
