// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: Install Env Observation (60588), Install Seeder (60618), Install Seed Database (60621), Assert (60021)
//
// An app's Subtype=Install codeunit runs INSIDE an existing company, under a session whose
// permissions are already in place. Both facts are invisible from the install trigger's own
// return value, so the trigger records what it could see and these tests read it back.
//
// What is proved, per test:
//   * Company.Get(CompanyName()) answers TRUE from inside OnInstallAppPerCompany, and the row
//     it finds carries the company the trigger was running for - the company row is database
//     state that predates the app being installed.
//   * The same Get answers FALSE for a company that does not exist, so the assertion above is
//     about the key and not about Get answering true for anything.
//   * UserPermissions.IsSuper(UserSecurityId()) answers TRUE from inside the trigger - permission
//     assignments predate the install too.
//   * Session.GetExecutionContext() and Session.GetCurrentModuleExecutionContext() answer
//     Install from inside OnInstallAppPerCompany, and GetExecutionContext() answers Install from
//     inside OnInstallAppPerDatabase - while the same calls answer Normal from the test itself,
//     so the recorded values depend on where they were read.
//
// NOTE: deliberately no Initialize()/DeleteAll() - like the sibling install-trigger tests, these
// observe a row written before any test code ran, and clearing it would defeat the purpose.

codeunit 60589 "Test Install Env Visible"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        EnvCodeTok: Label 'ENV', Locked = true;

    trigger OnRun()
    begin
    end;

    [Test]
    procedure TestInstall_TriggerRecordedWhatItCouldSee()
    var
        Observation: Record "Install Env Observation";
    begin
        // PRECONDITION for the three tests below: without it they would all pass on a run whose
        // install trigger never fired.
        Assert.IsTrue(Observation.Get(EnvCodeTok),
          'OnInstallAppPerCompany must have written the ENV observation row');
        Assert.AreEqual(CompanyName(), Observation."Observed Company Name",
          'the install trigger ran for a different company than the one the tests run in');
    end;

    [Test]
    procedure TestInstall_CompanyRowExistsDuringInstall()
    var
        Observation: Record "Install Env Observation";
    begin
        Observation.Get(EnvCodeTok);
        Assert.IsTrue(Observation."Company Row Existed",
          'Company.Get(CompanyName()) must answer true from inside OnInstallAppPerCompany');
        Assert.AreEqual(CompanyName(), Observation."Company Row Name",
          'the Company row the install trigger found must be the company it was installing into');
    end;

    [Test]
    procedure TestInstall_CompanyGetConsultsTheKeyDuringInstall()
    var
        Observation: Record "Install Env Observation";
    begin
        // NEGATIVE CONTROL for the test above, recorded inside the same trigger.
        Observation.Get(EnvCodeTok);
        Assert.IsFalse(Observation."Other Company Row Existed",
          'Company.Get on a company that does not exist must answer false, even during install');
    end;

    [Test]
    procedure TestInstall_SessionUserIsSuperDuringInstall()
    var
        Observation: Record "Install Env Observation";
        UserPermissions: Codeunit "User Permissions";
    begin
        Observation.Get(EnvCodeTok);
        Assert.IsTrue(Observation."Session User Was Super",
          'UserPermissions.IsSuper(UserSecurityId()) must answer true from inside OnInstallAppPerCompany');
        // ...and the same answer still holds at test time, so the assertion above is about when
        // the grant existed and not about the session having changed since.
        Assert.IsTrue(UserPermissions.IsSuper(UserSecurityId()),
          'the session user must still be SUPER at test time');
    end;

    [Test]
    procedure TestInstallExecCtx_SessionContextIsInstallPerCompany()
    var
        Observation: Record "Install Env Observation";
    begin
        Assert.IsTrue(Observation.Get(EnvCodeTok), 'OnInstallAppPerCompany must have written the ENV observation row');
        Assert.IsTrue(Observation."Exec Ctx Was Install",
          StrSubstNo('Session.GetExecutionContext() inside OnInstallAppPerCompany must be Install; it answered "%1"', Observation."Exec Ctx Text"));
    end;

    [Test]
    procedure TestInstallExecCtx_ModuleContextIsInstallPerCompany()
    var
        Observation: Record "Install Env Observation";
    begin
        Assert.IsTrue(Observation.Get(EnvCodeTok), 'OnInstallAppPerCompany must have written the ENV observation row');
        Assert.IsTrue(Observation."Module Exec Ctx Was Install",
          StrSubstNo('Session.GetCurrentModuleExecutionContext() inside OnInstallAppPerCompany must be Install; it answered "%1"', Observation."Module Exec Ctx Text"));
    end;

    [Test]
    procedure TestInstallExecCtx_SessionContextIsInstallPerDatabase()
    var
        Seed: Record "Install Seed Database";
    begin
        Assert.IsTrue(Seed.Get('DATABASE'), 'OnInstallAppPerDatabase must have written the DATABASE row');
        Assert.IsTrue(Seed."Exec Ctx Was Install",
          StrSubstNo('Session.GetExecutionContext() inside OnInstallAppPerDatabase must be Install; it answered "%1"', Seed."Exec Ctx Text"));
    end;

    [Test]
    procedure TestInstallExecCtx_ContextIsNormalAtTestTime()
    begin
        // NEGATIVE CONTROL: the same calls made from test code answer Normal, so the three tests
        // above are about the install trigger and not about what these calls always return.
        Assert.IsTrue(Session.GetExecutionContext() = ExecutionContext::Normal,
          StrSubstNo('Session.GetExecutionContext() at test time must be Normal; it answered "%1"', Format(Session.GetExecutionContext())));
        Assert.IsTrue(Session.GetCurrentModuleExecutionContext() = ExecutionContext::Normal,
          StrSubstNo('Session.GetCurrentModuleExecutionContext() at test time must be Normal; it answered "%1"', Format(Session.GetCurrentModuleExecutionContext())));
    end;
}
