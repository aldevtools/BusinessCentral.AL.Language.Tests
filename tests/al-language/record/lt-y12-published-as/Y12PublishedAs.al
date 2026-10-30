// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-example
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe (al-runner issue 6438, writer Y12): column 16 "Published As" of "NAV App Installed App" (2000000153) for this app, a corpus
// dependency app ("AL Internals Test Fixture") and Microsoft apps, and filters on it. The value follows how the app was published: the
// corpus CI and the SaaS sandbox both publish the corpus apps through the dev endpoint. A separate codeunit from
// record/TestNavAppInstalledAppSysTable.al because that file needs the Assert fixture, which the SaaS sandbox cannot compile (it depends on
// a test library the sandbox lacks). Object id 91553.

codeunit 91553 "LT Y12 Published As"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        AppNameTok: Label 'AL Language Coverage Tests', Locked = true;
        FixtureAppIdTok: Label '{f1e2d3c4-b5a6-7890-fedc-ba9876543210}', Locked = true;

    local procedure PublishedAsOf(AppIdText: Text): Text
    var
        Row: Record "NAV App Installed App";
        AppId: Guid;
    begin
        Evaluate(AppId, AppIdText);
        if not Row.Get(AppId) then
            exit('no row');
        exit(Format(Row."Published As") + '|' + Format(Row."Published As".AsInteger()));
    end;

    [Test]
    procedure Y12_PublishedAs_PerApp()
    var
        Observer: Codeunit "Probe Observer";
        ThisModule: ModuleInfo;
    begin
        NavApp.GetCurrentModuleInfo(ThisModule);
        Observer.Observe('this_app', PublishedAsOf(Format(ThisModule.Id())));
        Observer.Observe('fixture_dependency', PublishedAsOf(FixtureAppIdTok));
        Observer.Observe('system_application', PublishedAsOf('{63ca2fa4-4f03-4f2b-a480-172fef340d3f}'));
        Observer.Observe('base_application', PublishedAsOf('{437dbf0e-84ff-417a-965d-ed2bb9650972}'));
        Observer.Observe('system_platform', PublishedAsOf('{8874ed3a-0643-4247-9ced-7a7002f7135d}'));
        Observer.Finish();
    end;

    [Test]
    procedure Y12_PublishedAs_Filters()
    var
        Row: Record "NAV App Installed App";
        Observer: Codeunit "Probe Observer";
    begin
        Row.SetRange(Name, AppNameTok);
        Row.SetRange("Published As", Row."Published As"::Global);
        Observer.Observe('this_app_global_isempty', Format(Row.IsEmpty()));
        Row.SetRange("Published As", Row."Published As"::Dev);
        Observer.Observe('this_app_dev_isempty', Format(Row.IsEmpty()));
        Row.SetRange("Published As", Row."Published As"::PTE);
        Observer.Observe('this_app_pte_isempty', Format(Row.IsEmpty()));
        Row.Reset();
        Row.SetRange(Publisher, 'Microsoft');
        Row.SetFilter("Published As", '<>%1', Row."Published As"::Global);
        Observer.Observe('microsoft_not_global_isempty', Format(Row.IsEmpty()));
        Row.SetRange("Published As", Row."Published As"::Global);
        Observer.Observe('microsoft_global_isempty', Format(Row.IsEmpty()));
        Row.Reset();
        Row.SetRange(Publisher, 'AL Language');
        Row.SetRange("Published As", Row."Published As"::Global);
        Observer.Observe('corpus_publisher_global_count', Format(Row.Count()));
        Observer.Finish();
    end;
}
