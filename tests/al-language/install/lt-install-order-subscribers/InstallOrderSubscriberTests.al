// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); XApp A tests/al-language-xapp-a/Y3XaInstallEvents.al (install codeunit 61179, event codeunit 61178,
//   log table 61176, probe table 61177, subscribers 61108); XApp B tests/al-language-xapp-b/Y3XbInstallEvents.al (subscribers 61148, install codeunit 61149);
//   main app subscribers 90824 below.
// Probe: install order and subscribers. XApp A is installed before XApp B (B depends on A) and both before this app. The install code of each app raises
//   A's integration event OnY3Phase and inserts a row of A's table 61177 (platform event OnAfterInsertEvent), per company and per database. Every
//   subscriber logs '<app>-sub|<phase>' (integration event) or '<app>-tsub|<phase>' (table event). The tests read which entries exist: which apps'
//   subscribers ran during A's install, during B's install and at test time, and what A's install code sees of B (NavApp.GetModuleInfo,
//   NavApp.IsInstalled).
// BC versions: 27 - 29

codeunit 90824 "LT Y3 Main Install Subs"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT Y3 XA Events", 'OnY3Phase', '', false, false)]
    local procedure OnPhase(Phase: Text)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('M-sub|' + Phase, '');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT Y3 Probe Row", 'OnAfterInsertEvent', '', false, false)]
    local procedure OnProbeInsert(var Rec: Record "LT Y3 Probe Row"; RunTrigger: Boolean)
    var
        Events: Codeunit "LT Y3 XA Events";
    begin
        Events.Log('M-tsub|' + Rec."Key", '');
    end;
}

codeunit 90823 "LT Install Order Subscribers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Entry(Name: Text): Text
    var
        L: Record "LT Y3 Install Log";
    begin
        if not L.Get(CopyStr(Name, 1, MaxStrLen(L.Entry))) then
            exit('No');
        if L.Detail = '' then
            exit('Yes');
        exit('Yes|' + L.Detail);
    end;

    local procedure ObservePhase(var Observer: Codeunit "Probe Observer"; Phase: Text)
    begin
        Observer.Observe('A-sub ' + Phase, Entry('A-sub|' + Phase));
        Observer.Observe('A-tsub ' + Phase, Entry('A-tsub|' + Phase));
        Observer.Observe('B-sub ' + Phase, Entry('B-sub|' + Phase));
        Observer.Observe('B-tsub ' + Phase, Entry('B-tsub|' + Phase));
        Observer.Observe('M-sub ' + Phase, Entry('M-sub|' + Phase));
        Observer.Observe('M-tsub ' + Phase, Entry('M-tsub|' + Phase));
    end;

    [Test]
    procedure InstallOfA_SubscribersOfDependentApps()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A install company ran', Entry('A-install|a-install-company'));
        Observer.Observe('A install database ran', Entry('A-install|a-install-database'));
        ObservePhase(Observer, 'a-install-company');
        ObservePhase(Observer, 'a-install-database');
        Observer.Finish();
    end;

    [Test]
    procedure InstallOfA_SeesDependentApp()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('A sees B company', Entry('A-seesB|a-install-company'));
        Observer.Observe('A sees B database', Entry('A-seesB|a-install-database'));
        Observer.Finish();
    end;

    [Test]
    procedure InstallOfB_Subscribers()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('B install company ran', Entry('B-install|b-install-company'));
        Observer.Observe('B install database ran', Entry('B-install|b-install-database'));
        ObservePhase(Observer, 'b-install-company');
        ObservePhase(Observer, 'b-install-database');
        Observer.Finish();
    end;

    [Test]
    procedure TestTime_Subscribers()
    var
        Observer: Codeunit "Probe Observer";
        Events: Codeunit "LT Y3 XA Events";
        L: Record "LT Y3 Install Log";
        P: Record "LT Y3 Probe Row";
    begin
        L.SetFilter(Entry, '*|test');
        L.DeleteAll();
        if P.Get('test') then
            P.Delete();
        Events.Raise('test');
        Events.InsertProbe('test');
        ObservePhase(Observer, 'test');
        L.DeleteAll();
        if P.Get('test') then
            P.Delete();
        Observer.Finish();
    end;
}
