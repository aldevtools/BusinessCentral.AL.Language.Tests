// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (69160); install code of XApp A (tests/al-language-xapp-a/R7169XaInstallPublishedAs.al, table 96080)
// Probe: al-runner issue 7169. "Published As" of "NAV App Installed App" for a dependency app by another publisher (XApp A, publisher
//   "AL Language"), read in that dependency's own OnInstallAppPerCompany and from this test. The value depends on how the dependency was
//   published: the corpus CI publishes every app through the dev endpoint (ci.yml app_dirs), not as a Global or per-tenant extension.
// BC versions: 27, 28, 29

codeunit 96073 "LT R7169 Dep Published As"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        XaAppIdTok: Label '{cd6a4292-f27b-4af9-89bc-15a5956f5c71}', Locked = true;

    [Test]
    procedure R7169_DependencyInstall_ReadsPublishedAs()
    var
        Log: Record "LT R7169 XA Install Log";
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('log_rows', Format(Log.Count()));
        if Log.FindSet() then
            repeat
                Observer.Observe('install_' + Log.Entry, Log.Detail);
            until Log.Next() = 0;
        Observer.Expect('log_rows', '4');
        // XApp A's own row does not exist yet while its install code runs; Base Application is Global; the fixture app (publisher
        // AL Language, installed before A) is already Dev there.
        Observer.Expect('install_own', 'no row');
        Observer.Expect('install_base_application', 'Global|0');
        Observer.Expect('install_filter_publisher_al_language_dev_count', '1');
        Observer.Expect('install_filter_publisher_al_language_global_count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure R7169_Test_ReadsPublishedAsOfDependency()
    var
        Row: Record "NAV App Installed App";
        Observer: Codeunit "Probe Observer";
        AppId: Guid;
    begin
        Evaluate(AppId, XaAppIdTok);
        if Row.Get(AppId) then
            Observer.Observe('xapp_a', Row.Publisher + '|' + Format(Row."Published As") + '|' + Format(Row."Published As", 0, 2))
        else
            Observer.Observe('xapp_a', 'no row');
        Row.Reset();
        Row.SetRange(Publisher, 'AL Language');
        Row.SetRange("Published As", Row."Published As"::Global);
        Observer.Observe('al_language_global_count', Format(Row.Count()));
        Row.SetRange("Published As", Row."Published As"::Dev);
        Observer.Observe('al_language_dev_count', Format(Row.Count()));
        Row.SetRange("Published As", Row."Published As"::PTE);
        Observer.Observe('al_language_pte_count', Format(Row.Count()));
        // Dev: this app, XApp A and the fixture app, all published through the dev endpoint by the corpus CI.
        Observer.Expect('xapp_a', 'AL Language| Dev|2');
        Observer.Expect('al_language_global_count', '0');
        Observer.Expect('al_language_dev_count', '3');
        Observer.Expect('al_language_pte_count', '0');
        Observer.Verify();
    end;
}
