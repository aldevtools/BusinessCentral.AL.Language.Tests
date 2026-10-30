// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extension-example
// Scope: in-scope
// Fixtures used: Assert (60021), from the AL Language Coverage Tests app
// BC versions: 27.0+
//
// WHAT THIS TABLE IS
//   "NAV App Installed App" (2000000153) is the platform's tenant-database registry of the
//   apps that are INSTALLED on the tenant: one row per installed app, keyed on "App ID"
//   alone, carrying that app's manifest identity (name, publisher, four version parts) and a
//   "Package ID" naming the specific package version behind it.
//
//   It is the table ordinary AL reads to ask "is this app installed, and at what version".
//   The platform itself joins it to Tenant Application Storage ON [Package ID], so the pair
//   ("App ID", "Package ID") is the registry's whole answer about identity.
//
// WHY THIS FILE IS IN THE CLOUD APP, UNLIKE ITS OnPrem NEIGHBOUR
//   Its sibling registry "Published Application" (2000000206) is declared Scope = OnPrem in
//   System.app, so naming that record type from a Target = Cloud app fails to compile with
//   error AL0296, and TestPublishedApplicationSysTable.al lives in the OnPrem app for exactly
//   that reason.
//
//   2000000153 is declared Scope = Cloud, so it IS nameable here - and belongs here, because
//   the eight cloud legs are the required contexts. The two files are deliberately parallel:
//   what differs between them is which app-lifecycle question the platform answers through
//   which table, and that is the thing worth having measured on a real tier.
//
// WHY "FINDS A ROW" IS NOT ENOUGH, AND WHAT EACH NEGATIVE CASE RULES OUT
//   Every positive assertion below has a negative twin, because a registry that returned SOME
//   row for ANY id would satisfy the positive half alone:
//
//     * an unknown App ID must select NO row - otherwise the filter matches everything;
//     * Get on an unknown App ID must RAISE the platform's record-not-found error rather than
//       inventing a row;
//     * this app's row must carry a non-blank Package ID that is not shared with the row of
//       any other installed app - otherwise the platform's own Package ID join is ambiguous.
//
//   The version parts are derived from ModuleInfo rather than written out as literals, so
//   bumping app.json's version cannot break this test with a failure pointing away from the
//   manifest; a guard first rejects a zero version, which would satisfy the comparisons
//   vacuously.
//
//   One more shape a single row would satisfy: every positive test but the last reads the row
//   of the app whose tests are RUNNING, reached through GetCurrentModuleInfo. A registry
//   carrying exactly one row, or answering that one row to every key, would pass all of them.
//   The last test therefore names a SECOND app by a literal id taken from its own app.json -
//   "AL Internals Test Fixture", which this app declares as a dependency - and requires the
//   registry to answer about it with ITS name and ITS package id, distinct from this app's.

codeunit 60887 "Test NAVApp Installed App"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AppNameTok: Label 'AL Language Coverage Tests', Locked = true;
        PublisherTok: Label 'AL Language', Locked = true;
        FixtureAppIdTok: Label '{f1e2d3c4-b5a6-7890-fedc-ba9876543210}', Locked = true;
        FixtureAppNameTok: Label 'AL Internals Test Fixture', Locked = true;

    [Test]
    procedure NavAppInstalledApp_Get_ThisAppsId_ReturnsItsManifestIdentity()
    // CLAIM: installing this app wrote a row, keyed on the app's own id, carrying the
    // manifest's name, publisher and four version parts - not blanks, and not another row's
    // values.
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        ThisModule: ModuleInfo;
        ThisVersion: Version;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        ThisVersion := ThisModule.AppVersion();

        Assert.IsTrue(
            NavAppInstalledApp.Get(ThisModule.Id()),
            'This app must have a NAV App Installed App row keyed on its own app id.');

        Assert.AreEqual(AppNameTok, NavAppInstalledApp.Name, 'Name must be the manifest''s name.');
        Assert.AreEqual(PublisherTok, NavAppInstalledApp.Publisher, 'Publisher must be the manifest''s publisher.');

        // Guard first: two surfaces both reporting a zero version would satisfy the four
        // comparisons below without proving anything.
        Assert.AreNotEqual('0.0.0.0', Format(ThisVersion),
            'ModuleInfo must report a non-zero manifest version, otherwise the comparisons below prove nothing.');

        Assert.AreEqual(ThisVersion.Major(), NavAppInstalledApp."Version Major", 'Version Major must be the manifest version''s first part.');
        Assert.AreEqual(ThisVersion.Minor(), NavAppInstalledApp."Version Minor", 'Version Minor must be the manifest version''s second part.');
        Assert.AreEqual(ThisVersion.Build(), NavAppInstalledApp."Version Build", 'Version Build must be the manifest version''s third part.');
        Assert.AreEqual(ThisVersion.Revision(), NavAppInstalledApp."Version Revision", 'Version Revision must be the manifest version''s fourth part.');

        // The same values ModuleInfo reports, so the two platform surfaces cannot disagree
        // about who this app is.
        Assert.AreEqual(ThisModule.Name(), NavAppInstalledApp.Name, 'Name must agree with ModuleInfo.');
        Assert.AreEqual(ThisModule.Publisher(), NavAppInstalledApp.Publisher, 'Publisher must agree with ModuleInfo.');
        Assert.AreEqual(ThisModule.Id(), NavAppInstalledApp."App ID", 'App ID must be the id ModuleInfo reports.');
    end;

    [Test]
    procedure NavAppInstalledApp_Find_UnknownAppId_ReturnsNoRow()
    // CLAIM: the "App ID" filter SELECTS. Without this, the test above would also pass against
    // a registry whose every row answered to every app id.
    var
        NavAppInstalledApp: Record "NAV App Installed App";
    begin
        Initialize();

        NavAppInstalledApp.SetRange("App ID", CreateGuid());
        Assert.IsTrue(NavAppInstalledApp.IsEmpty(), 'No app is installed under a freshly created app id.');
    end;

    [Test]
    procedure NavAppInstalledApp_Get_UnknownAppId_RaisesRecordNotFound()
    // CLAIM: "App ID" is the primary key and the platform does not invent a row for an id
    // nobody installed - Get raises record-not-found rather than answering.
    var
        NavAppInstalledApp: Record "NAV App Installed App";
    begin
        Initialize();

        asserterror NavAppInstalledApp.Get(CreateGuid());
        Assert.ExpectedErrorCannotFind(Database::"NAV App Installed App");
    end;

    [Test]
    procedure NavAppInstalledApp_ThisAppsPackageId_IsNonBlankAndNotSharedWithAnotherApp()
    // CLAIM: "Package ID" identifies a PACKAGE, not a constant. The platform joins Tenant
    // Application Storage to this table on that column, so a blank or shared value would make
    // that join ambiguous - and an implementation that left the column at its type default
    // would pass every other test in this file.
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        ThisModule: ModuleInfo;
        MyPackageId: Guid;
        EmptyId: Guid;
        Others: Integer;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);

        NavAppInstalledApp.Get(ThisModule.Id());
        MyPackageId := NavAppInstalledApp."Package ID";
        Assert.AreNotEqual(EmptyId, MyPackageId, 'An installed app must carry a non-blank Package ID.');

        // A tenant running this test always has more installed apps than this one (System
        // Application and Base Application at minimum), so this loop is never empty.
        NavAppInstalledApp.Reset();
        NavAppInstalledApp.SetFilter("App ID", '<>%1', ThisModule.Id());
        Assert.IsTrue(NavAppInstalledApp.FindSet(), 'A tenant carries installed apps besides this one.');
        repeat
            Others += 1;
            Assert.AreNotEqual(EmptyId, NavAppInstalledApp."App ID", 'No installed app may carry a blank App ID.');
            Assert.AreNotEqual(MyPackageId, NavAppInstalledApp."Package ID",
                'Two different installed apps must not share a Package ID.');
        until NavAppInstalledApp.Next() = 0;

        Assert.IsTrue(Others > 0, 'There must be at least one installed app besides this one.');
    end;

    [Test]
    procedure NavAppInstalledApp_EveryListedRow_IsGettableByItsOwnAppId()
    // CLAIM: the registry is self-consistent - a row that appears in a walk is retrievable by
    // the "App ID" it reports, and the keyed read returns that same row. A registry listing an
    // app it cannot then answer about would fail here and nowhere else.
    var
        NavAppInstalledApp: Record "NAV App Installed App";
        Probe: Record "NAV App Installed App";
        EmptyId: Guid;
        Walked: Integer;
    begin
        Initialize();

        Assert.IsTrue(NavAppInstalledApp.FindSet(), 'A tenant has installed apps.');
        repeat
            Assert.AreNotEqual(EmptyId, NavAppInstalledApp."App ID", 'No listed row may carry a blank App ID.');
            Assert.IsTrue(Probe.Get(NavAppInstalledApp."App ID"),
                'Every listed row must be gettable by the App ID it reports.');
            Assert.AreEqual(NavAppInstalledApp.Name, Probe.Name,
                'The keyed read must return the same row the walk was on.');
            Walked += 1;
        until NavAppInstalledApp.Next() = 0;

        Assert.IsTrue(Walked > 0, 'The walk must have visited at least one row.');
    end;

    [Test]
    procedure NavAppInstalledApp_ASecondNamedApp_IsListedWithItsOwnIdentity()
    // CLAIM: the registry answers about a SECOND, independently named app - and answers about
    // it with that app's OWN identity, not this one's.
    //
    // WHY THIS EXISTS ALONGSIDE THE TESTS ABOVE. Every other positive test in this file reads
    // the row belonging to the app whose tests are running, reached through
    // GetCurrentModuleInfo. A registry that carried exactly ONE row - this app's - would
    // satisfy all of them. So would one that answered this app's row to every key.
    //
    // "AL Internals Test Fixture" is a separate app with its own manifest, its own app id and
    // its own object range, which this app declares as a dependency and which is therefore
    // installed on any tenant running these tests. Naming its id as a literal, rather than
    // discovering it from the registry, is the point: the id comes from the fixture's app.json,
    // so a registry that invented rows or renamed them cannot satisfy this by construction.
    var
        FixtureApp: Record "NAV App Installed App";
        ThisApp: Record "NAV App Installed App";
        ThisModule: ModuleInfo;
        FixtureAppId: Guid;
        EmptyId: Guid;
    begin
        Initialize();
        NavApp.GetCurrentModuleInfo(ThisModule);
        Evaluate(FixtureAppId, FixtureAppIdTok);

        // Guard: the two apps really are different, so the comparisons below are not a row
        // being compared with itself.
        Assert.AreNotEqual(ThisModule.Id(), FixtureAppId, 'The fixture app and this app must have different app ids.');

        Assert.IsTrue(FixtureApp.Get(FixtureAppId),
            'The fixture app this one depends on must be listed as installed.');

        // Its OWN name, not this app's - the assertion a registry echoing one row back fails.
        Assert.AreEqual(FixtureAppNameTok, FixtureApp.Name, 'The row keyed on the fixture app id must carry the fixture app''s name.');
        Assert.AreEqual(PublisherTok, FixtureApp.Publisher, 'The fixture app is published by the same publisher.');
        Assert.AreEqual(FixtureAppId, FixtureApp."App ID", 'The row must report the app id it was keyed on.');
        Assert.AreNotEqual(EmptyId, FixtureApp."Package ID", 'The fixture app must carry a non-blank Package ID.');

        // And the two rows are genuinely distinct records, not one row reached twice.
        Assert.IsTrue(ThisApp.Get(ThisModule.Id()), 'This app must have a row of its own.');
        Assert.AreNotEqual(ThisApp.Name, FixtureApp.Name, 'Two different apps must not report the same name.');
        Assert.AreNotEqual(ThisApp."Package ID", FixtureApp."Package ID", 'Two different apps must not share a Package ID.');
    end;

    local procedure Initialize()
    begin
        // "NAV App Installed App" is a read-only platform registry written by installing an
        // app, not by test code -- nothing to DeleteAll.
    end;
}
