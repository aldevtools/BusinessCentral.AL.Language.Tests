// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIS Setup (60607), SIS Cache (60608), SIS Publisher (60610)
//
// SingleInstance codeunit lifetime.
//
// WHAT THIS TEST DOES AND DOES NOT PROVE — read before trusting it as a regression gate.
// It pins the SingleInstance CONTRACT: one instance per test, state kept across scope
// boundaries. It does NOT reproduce the specific defect that motivated it — that defect
// needs a scope to be genuinely disposed rather than merely detached, and none of the shapes
// reachable from a small AL test (a nested local procedure, event dispatch, Codeunit.Run, or
// a Codeunit.Run that errors) reliably reproduce it. It still pins the contract every runtime
// must satisfy regardless of internal caching mechanism.
//
// ONE TEST PER CODEUNIT: two tests in the same test codeunit would share one cached
// instance, because nothing resets a SingleInstance codeunit between them.
//
// AND ONE CACHE FIXTURE PER TEST CODEUNIT, for the same reason one level up. A
// SingleInstance instance is registered on the session's company and released only when
// that company scope is disposed — it is NOT reset between test codeunits. This test owns
// SIS Cache (60608); its two siblings own 60625 and 60626. Sharing one cache let whichever
// codeunit ran first decide the others' answers (corpus #261).
//
// SIS Cache is also the only subscriber to SIS Publisher.OnResolveCurrency, and must stay
// the only one: Resolve() returns whatever the last subscriber assigned, so a second
// subscriber would make the assertions below depend on subscriber dispatch order.

codeunit 60613 "Test SingleInstance Scope Exit"
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

    /// Constructs the SingleInstance codeunit from inside a nested scope that then returns,
    /// so the tree it was parented on is gone by the time the caller reads it again.
    /// Goes through event dispatch, which is how the real failure is reached.
    local procedure PrimeFromNestedScope(): Code[10]
    var
        Publisher: Codeunit "SIS Publisher";
    begin
        exit(Publisher.Resolve());
    end;

    [Test]
    procedure TestCodeunit_SingleInstance_SurvivesCreatingScopeExit()
    var
        Cache: Codeunit "SIS Cache";
        Publisher: Codeunit "SIS Publisher";
        Primed: Code[10];
    begin
        Initialize();
        SeedSetup('EUR');

        Primed := PrimeFromNestedScope();
        if Primed <> 'EUR' then
            Error('The nested scope itself read the wrong value: expected <EUR>, got <%1>.', Primed);

        // The scope that built the instance has now returned. Reading through it again is
        // what used to come back null and NRE.
        if Cache.GetCurrencyCode() <> 'EUR' then
            Error('After the creating scope exited, the cached value read back as <%1>, expected <EUR>.',
                Cache.GetCurrencyCode());

        // And again through dispatch, from this scope.
        if Publisher.Resolve() <> 'EUR' then
            Error('Re-dispatching after the creating scope exited read back <%1>, expected <EUR>.',
                Publisher.Resolve());

        // Proves it is the SAME instance and not a silently rebuilt one — a fresh instance
        // would have re-read the record and pushed this to 2. Without this the test would
        // still pass if the runtime just rebuilt the codeunit on every resolution, which is
        // not the SingleInstance contract.
        if Cache.GetReadCount() <> 1 then
            Error('Expected exactly 1 record read across both calls (one shared instance), got %1.',
                Cache.GetReadCount());
    end;
}
