// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607), SIS Failed Scope Cache (60626), SIS Failing Runner (60612)
//
// ONE CACHE FIXTURE PER TEST CODEUNIT. A SingleInstance instance is registered on the
// session's company and released only when that company scope is disposed, so it is shared
// across every test codeunit in the run. Three test codeunits sharing one cache therefore
// let whichever ran first decide the other two's answers (corpus #261). Each of the three
// now has its own cache fixture; this one owns SIS Failed Scope Cache (60626). That makes
// execution order irrelevant by construction, rather than by a reset call that a future
// reordering could outrun.

codeunit 60615 "Test SingleInstance Failed Scp"
{
    Subtype = Test;
    TestPermissions = Disabled;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    var
        Setup: Record "SIS Setup";
    begin
        Setup.DeleteAll();
    end;

    local procedure SeedSetup(CurrencyCode: Code[10])
    var
        Setup: Record "SIS Setup";
    begin
        Setup.Init();
        Setup."Primary Key" := 'MAIN';
        Setup."Currency Code" := CurrencyCode;
        Setup.Insert();
    end;

    [Test]
    procedure TestCodeunit_SingleInstance_SurvivesAScopeThatErrored()
    var
        Cache: Codeunit "SIS Failed Scope Cache";
    begin
        Initialize();
        SeedSetup('CHF');
        // Must commit before Codeunit.Run for the same reason as the success-path
        // sibling test — but here it also matters for a second reason: Codeunit.Run's
        // error handling rolls the transaction back to the last commit. Without this
        // Commit, the SeedSetup insert above would itself be undone by the rollback,
        // so GetCurrencyCode()'s Setup.Get('MAIN') below would find no row at all
        // instead of the CHF row this test is actually about.
        Commit();

        // The priming scope errors, so it is torn down through the rollback path.
        if Codeunit.Run(Codeunit::"SIS Failing Runner") then
            Error('The priming codeunit was supposed to fail.');

        if Cache.GetCurrencyCode() <> 'CHF' then
            Error('After a failed scope was torn down, the cached value read back as <%1>, expected <CHF>.',
                Cache.GetCurrencyCode());
    end;
}
