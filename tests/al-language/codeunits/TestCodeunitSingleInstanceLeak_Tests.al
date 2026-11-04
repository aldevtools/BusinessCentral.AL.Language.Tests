// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: SIC Session Scoped (60627), SIC Session Scoped Primer (60628),
//                SIC Per Call Probe (60629), SIC Per Call Primer (60630), Assert (60021)
//
// SingleInstance codeunit lifetime ACROSS a codeunit boundary.
//
// WHAT THIS FILE USED TO CLAIM, AND WHY IT WAS WRONG. It asserted the opposite — that
// SingleInstance state must NOT leak from a previous test codeunit, reading an untouched
// default of 0 out of "Test SIC Single" (60597) after codeunit 60599 had set it to 99. BC
// makes no such promise. A SingleInstance instance is registered on the session's company
// (NCLMetaCodeunit.InternalCreateInstance adds it to NavCompany.SingleInstanceCodeunits,
// keyed by CLR type) and is released only when that company scope is disposed
// (NavCompany.Dispose is the only thing that clears the dictionary). The test-execution path
// does not touch it: NavTestExecution.LeaveTestCodeunit clears executingTestCodeUnit and
// nothing else. Verified identical on BC 27.5 and 28.4.
//
// So the old assertion only ever passed because the Linux tier reset session state at batch
// boundaries, which gave each test codeunit a fresh company. Once the tier ran the suite in
// one session (MsDyn365Bc.On.Linux #77) it began to fail, and it was failing for the right
// reason — the corpus was asserting something BC does not do, and had been contradicting its
// own SingleInstance scope-survival tests while doing it.
//
// WHAT IT CLAIMS NOW. The genuine, BC-guaranteed statement that this codeunit's separate
// position is uniquely able to make: SingleInstance state SURVIVES a codeunit boundary, and
// an ordinary codeunit's state does not. The contrast case is what keeps the first half from
// being satisfiable by a runtime that simply shared every codeunit.
//
// ORDER-INDEPENDENT BY CONSTRUCTION. The boundary is crossed by this test itself, through
// Codeunit.Run on a plain helper codeunit, rather than by relying on some other TEST codeunit
// having run first. The fixtures it bumps (60627/60629) are owned by this file alone, so no
// other codeunit can pre-fill them and no run order changes the answer. That is the same
// discipline corpus #261 applies to the SIS cache fixtures.

codeunit 60600 "Test Codeunit SIC Leak"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    begin
    end;

    [Test]
    procedure TestCodeunit_SingleInstance_SurvivesACodeunitBoundary()
    // CLAIM: a SingleInstance codeunit's state set inside another codeunit's scope is
    // visible through this scope's own variable, because the instance is company-scoped.
    var
        Single: Codeunit "SIC Session Scoped";
    begin
        Initialize();

        // Nothing has bumped it yet in this test codeunit, and nothing else owns it.
        Assert.AreEqual(0, Single.GetBumps(),
            'The fixture must start at 0 — no other codeunit may own SIC Session Scoped.');

        Assert.IsTrue(Codeunit.Run(Codeunit::"SIC Session Scoped Primer"),
            'Priming through Codeunit.Run must succeed.');

        // The primer's scope is gone. The instance it bumped is the session's, so this
        // variable must resolve to the same one and read 1, not the default 0.
        Assert.AreEqual(1, Single.GetBumps(),
            'SingleInstance state must survive the codeunit boundary — the primer''s bump must be visible here.');

        // Bump from this scope too: 2 proves both scopes reached ONE instance, where a
        // fresh-instance-per-scope runtime would answer 1.
        Single.Bump();
        Assert.AreEqual(2, Single.GetBumps(),
            'Both scopes must have bumped the same instance, so the count must be 2, not 1.');
    end;

    [Test]
    procedure TestCodeunit_NonSingleInstance_DoesNotSurviveACodeunitBoundary()
    // CLAIM (contrast): the same boundary crossing must NOT carry an ordinary codeunit's
    // state, which is what pins the behavior above to SingleInstance codeunits alone.
    var
        PerCall: Codeunit "SIC Per Call Probe";
    begin
        Initialize();

        Assert.IsTrue(Codeunit.Run(Codeunit::"SIC Per Call Primer"),
            'Priming through Codeunit.Run must succeed.');

        // The primer bumped its OWN instance of SIC Per Call Probe. This variable is a
        // different instance and must still read the default.
        Assert.AreEqual(0, PerCall.GetBumps(),
            'A non-SingleInstance codeunit must not carry state across a codeunit boundary — expected the untouched default.');

        // And it must still keep its own state, so the 0 above is isolation rather than a
        // fixture that never records anything.
        PerCall.Bump();
        Assert.AreEqual(1, PerCall.GetBumps(),
            'A non-SingleInstance codeunit must still keep its OWN state: expected 1.');
    end;
}
