// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-event-types
// Scope: in-scope
// Fixtures used: Probe Observer (69160); helper 90827 (tests/al-language/events/lt-y3-setup-order/); XApp A tests/al-language-xapp-a/Y3XaSetupOrder.al (log 61139, subscriber 61137), XApp C
//   tests/al-language-xapp-c/Y3XcSetupOrder.al (table 61152, subscriber 61153); Tests-TestLibraries codeunit 130011 "Backup Management".
// Probe: the order of subscribers from apps that do not depend on each other, a Microsoft app against partner apps, on one event
//   (Base Application GlobalTriggerManagement.OnAfterGetDatabaseTableTriggerSetup). 130011 assigns all four flags true; XApp C (app id
//   0df0fadc-..., below Tests-TestLibraries 5d86850b-...; publisher "Bravo Probe Publisher") and XApp A (cd6a4292-..., above it; publisher
//   "AL Language") log the flags they receive and their place in the call (seq). Yes flags = ran after 130011.
//   Tests-TestLibraries is in the container before the corpus apps are published.
//   Measured on BC 27.5, 28.5 and 29.0 (CI TestLibraries job): A runs first, then C, and neither sees 130011's flags.
// BC versions: 27 - 29

codeunit 81639 "LT Y3 Setup Order"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure SetupOrder_MicrosoftTestLibrariesAgainstPartnerApps()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y3 Setup Order Helper";
    begin
        Observer.Observe('C below | A above', Helper.InsertRowAndReadLog());
        Observer.Expect('C below | A above', 'C: seq=2 in=NoNoNoNo | A: seq=1 in=NoNoNoNo');
        Observer.Verify();
    end;

    [Test]
    procedure SetupOrder_UnrelatedPartnerAppsAroundTestLibraries()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT Y3 Setup Order Helper";
    begin
        // Second form: main app M (a1b2c3d4-..., below 5d86850b-...) and XApp D (e92be076-..., above it), no dependency path between them,
        // table 90828 (measured on BC 27.5, 28.5, 29.0: D runs, then 130011, then M). 'Final' is logged only when the kept OnDatabaseInsert flag is true, which in this job only 130011 sets.
        Observer.Observe('M below | D above', Helper.InsertMainRowAndReadLog());
        Observer.Expect('M below | D above', 'M: seq=2 in=YesYesYesYes | D: seq=1 in=NoNoNoNo | Final: seq=3 in=YesNoNoNo');
        Observer.Verify();
    end;
}
