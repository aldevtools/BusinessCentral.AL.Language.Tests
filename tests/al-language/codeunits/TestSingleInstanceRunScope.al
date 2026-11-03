// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607), SIS Run Scope Cache (60625), SIS Runner (60611)
//
// ONE CACHE FIXTURE PER TEST CODEUNIT. A SingleInstance instance is registered on the
// session's company and released only when that company scope is disposed, so it is shared
// across every test codeunit in the run. Three test codeunits sharing one cache therefore
// let whichever ran first decide the other two's answers (corpus #261). Each of the three
// now has its own cache fixture; this one owns SIS Run Scope Cache (60625). That makes
// execution order irrelevant by construction, rather than by a reset call that a future
// reordering could outrun.

codeunit 60614 "Test SingleInstance Run Scope"
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
    procedure TestCodeunit_SingleInstance_SurvivesACodeunitRunScope()
    var
        Cache: Codeunit "SIS Run Scope Cache";
    begin
        Initialize();
        SeedSetup('GBP');
        // Real BC refuses to open the write scope Codeunit.Run needs while this
        // transaction still has an uncommitted database write pending (the SeedSetup
        // Insert above) — commit first, exactly like Base App code does before calling
        // into another codeunit that manages its own transaction.
        Commit();

        // Codeunit.Run gives the resolution its own scope, which is then torn down. The
        // instance cached from inside it must still be usable afterwards.
        if not Codeunit.Run(Codeunit::"SIS Runner") then
            Error('Priming through Codeunit.Run failed: %1', GetLastErrorText());

        if Cache.GetCurrencyCode() <> 'GBP' then
            Error('After the Codeunit.Run scope was torn down, the cached value read back as <%1>, expected <GBP>.',
                Cache.GetCurrencyCode());
        if Cache.GetReadCount() <> 1 then
            Error('Expected exactly 1 record read across the Run and the later call (one shared instance), got %1.',
                Cache.GetReadCount());
    end;
}
