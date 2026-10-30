// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); XApp A tests/al-language-xapp-a/Y3XaSetupOrder.al (log 61139, subscriber 61137), XApp C
//   tests/al-language-xapp-c/Y3XcSetupOrder.al (table 61152, subscriber 61153); Tests-TestLibraries codeunit 130011 "Backup Management".
// Probe: the order of subscribers from apps that do not depend on each other, a Microsoft app against partner apps, on one event
//   (Base Application GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup). 130011 assigns all four flags true; XApp C (app id
//   0df0fadc-..., below Tests-TestLibraries 5d86850b-...; publisher "Bravo Probe Publisher") and XApp A (cd6a4292-..., above it; publisher
//   "AL Language") log the flags they receive and their place in the call (seq). Yes flags = ran after 130011.
//   Tests-TestLibraries is in the container before the corpus apps are published.
// BC versions: 27 - 29

codeunit 81639 "LT Y3 Setup Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Entry(Who: Text): Text
    var
        L: Record "LT Y3 Order Log";
    begin
        if not L.Get(Who) then
            exit('not called');
        exit(L.Detail);
    end;

    [Test]
    procedure SetupOrder_MicrosoftTestLibrariesAgainstPartnerApps()
    var
        Observer: Codeunit "Probe Observer";
        L: Record "LT Y3 Order Log";
        R: Record "LT Y3 XC Order Row";
    begin
        L.DeleteAll();
        R.DeleteAll();
        R.Id := 1;
        R.Insert(true);
        Observer.Observe('C below | A above', 'C: ' + Entry('C') + ' | A: ' + Entry('A'));
        Observer.Expect('C below | A above', 'TBD');
        Observer.Verify();
    end;
}
