// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Seed (60617), Install Seed Database (60621), Install Seeder (60618), Not An Installer (60619), Assert (60021)
//
// Proves that Subtype=Install codeunit lifecycle triggers fire once per bundle
// BEFORE the first [Test] runs — modelling a freshly-installed app, exactly
// like real BC's NavAppInstallationProcessor raising OnInstallAppPerDatabase /
// OnInstallAppPerCompany on install.
//
// 'DATABASE' (per-database trigger, "Install Seed Database") and 'COMPANY1' /
// 'COMPANY2' (per-company trigger, "Install Seed") must exist with exact
// values; the look-alike procedure on the NORMAL codeunit "Not An Installer"
// must NOT have run (no 'ROGUE' row, count stays exactly 2) — the step is
// scoped to Subtype=Install, not name-matched.
//
// NOTE: deliberately no Initialize()/DeleteAll() here — these tests exist
// specifically to observe the rows seeded by install triggers BEFORE any test
// code runs; clearing the tables would defeat the test's purpose.

codeunit 60620 "Test Install Trigger Seed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure TestInstall_SeededPerCompanyRowsExist()
    var
        Seed: Record "Install Seed";
    begin
        Seed.Get('COMPANY1');
        Assert.AreEqual(11, Seed."Value", 'OnInstallAppPerCompany must have seeded COMPANY1 with Value 11');
        Seed.Get('COMPANY2');
        Assert.AreEqual(22, Seed."Value", 'OnInstallAppPerCompany must have seeded COMPANY2 with Value 22');
    end;

    [Test]
    procedure TestInstall_SeededPerDatabaseRowExists()
    var
        Seed: Record "Install Seed Database";
    begin
        Seed.Get('DATABASE');
        Assert.AreEqual(99, Seed."Value", 'OnInstallAppPerDatabase must have seeded DATABASE with Value 99');
    end;

    [Test]
    procedure TestInstall_ExactlyTheThreeSeededRowsExist()
    var
        Seed: Record "Install Seed";
        SeedDatabase: Record "Install Seed Database";
    begin
        Assert.AreEqual(2, Seed.Count(), 'OnInstallAppPerCompany must have seeded exactly 2 rows (COMPANY1 + COMPANY2)');
        Assert.AreEqual(1, SeedDatabase.Count(), 'OnInstallAppPerDatabase must have seeded exactly 1 row (DATABASE)');
    end;

    [Test]
    procedure TestInstall_NonInstallCodeunitDidNotAutoRun()
    var
        Seed: Record "Install Seed";
    begin
        // "Not An Installer" is Subtype=Normal but has a public procedure named
        // OnInstallAppPerCompany. If the runtime matched by method name instead
        // of Subtype=Install, a 'ROGUE' row would exist.
        Assert.IsFalse(Seed.Get('ROGUE'), 'the look-alike procedure on a NON-Install codeunit must not auto-run');
    end;

    [Test]
    procedure TestInstall_UnseededRowRaisesExpectedError()
    begin
        asserterror RequireRow('MISSING');
        Assert.ExpectedError('row MISSING was not seeded');
    end;

    local procedure RequireRow("Code": Code[20])
    var
        Seed: Record "Install Seed";
    begin
        if not Seed.Get("Code") then
            Error('row %1 was not seeded', "Code");
    end;
}
