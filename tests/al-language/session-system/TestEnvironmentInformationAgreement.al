// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/application/system-application/codeunit/system.environment.environment-information
// Scope: in-scope
// Fixtures used: Assert only. The subject is System Application codeunit 457 "Environment
//                Information" as the running tier answers it; nothing is set, created or written.
//
// CLAIM: the environment predicates agree with each other the way System Application defines
// them, whatever environment the tier is configured as:
//   - IsProduction() is the negation of IsSandbox() while no test has set a testability flag;
//   - a sandbox is SaaS (IsSaaS() = IsSandbox() or membership entitlement);
//   - SaaS infrastructure is SaaS (IsSaaSInfrastructure() = IsSaaS() and Azure);
//   - IsOnPrem() and IsFinancials() cannot both hold (ApplicationIdentifier() is 'NAV' or 'FIN').
//
// EVERY ASSERTION IS ABOUT AGREEMENT, NEVER ABOUT A LITERAL. Whether a tier is a sandbox is how
// that tier is configured (this repository's CI configures TenantEnvironmentType = Sandbox; an
// on-premises container answers Production), so no test here pins which answer it gives.
// Written for AL Runner issue #3514, where a runner answered IsSandbox() without a test asking.
codeunit 60984 "Test Env Info Agreement"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure EnvironmentInformation_IsProduction_IsTheNegationOfIsSandbox()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.AreEqual(not EnvironmentInformation.IsSandbox(), EnvironmentInformation.IsProduction(),
          'IsProduction() must be the negation of IsSandbox() when no testability flag is set');
    end;

    [Test]
    procedure EnvironmentInformation_ASandbox_IsSaaS()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.IsFalse(EnvironmentInformation.IsSandbox() and not EnvironmentInformation.IsSaaS(),
          'IsSandbox() must imply IsSaaS()');
    end;

    [Test]
    procedure EnvironmentInformation_SaaSInfrastructure_IsSaaS()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.IsFalse(EnvironmentInformation.IsSaaSInfrastructure() and not EnvironmentInformation.IsSaaS(),
          'IsSaaSInfrastructure() must imply IsSaaS()');
    end;

    [Test]
    procedure EnvironmentInformation_IsOnPremAndIsFinancials_AreNotBothTrue()
    var
        EnvironmentInformation: Codeunit "Environment Information";
    begin
        Assert.IsFalse(EnvironmentInformation.IsOnPrem() and EnvironmentInformation.IsFinancials(),
          'the application identifier is NAV or FIN, never both');
    end;
}
