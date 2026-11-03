// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: ALT Internal Codeunit (61000), IALTCrossCompute / ALT Cross Compute (61004)
// BC versions: 27.5+
//
// CLAIM: method dispatch works correctly across three call paths:
//   (a) a method on the calling codeunit itself
//   (b) a method on a codeunit in a dependency app, called directly
//   (c) a method called through an interface whose definition and
//       implementation both live in a dependency app
// This targets NavNCLCompilationException: Function ID <hash> does not have
// a member with that ID — the numeric function-ID dispatch bug in the runner.

codeunit 60204 "Test Cross App Dispatch"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── (a) Self-dispatch ────────────────────────────────────────────────────

    [Test]
    procedure CrossApp_SelfMethod_DirectCall_ReturnsConcreteValue()
    // CLAIM: calling a private method defined on this codeunit returns the
    // correct value — baseline that self-dispatch works before testing cross-app.
    begin
        Initialize();
        Assert.AreEqual(14, Double(7), 'Self-dispatch: Double(7) must return 14');
    end;

    // ── (b) Dependency codeunit dispatch ─────────────────────────────────────

    [Test]
    procedure CrossApp_DepCU_Compute_ReturnsConcreteValue()
    // CLAIM: calling a method on ALT Internal Codeunit (defined in the fixture
    // dependency app) returns the correct computed value.
    // This exercises direct call dispatch to a compiled dependency codeunit.
    var
        InternalCU: Codeunit "ALT Internal Codeunit";
    begin
        Initialize();
        Assert.AreEqual(42, InternalCU.Compute(21), 'DepCU dispatch: Compute(21) must return 42');
    end;

    // ── (c) Cross-app interface dispatch ─────────────────────────────────────

    [Test]
    procedure CrossApp_Interface_CrossAppDispatch_ReturnsConcreteValue()
    // CLAIM: calling a method through an interface where both the interface
    // definition (IALTCrossCompute) and the implementing codeunit (ALT Cross Compute)
    // live in the dependency app returns the correct computed value.
    // This exercises interface-table-driven dispatch across the app boundary.
    var
        C: Interface IALTCrossCompute;
        Impl: Codeunit "ALT Cross Compute";
    begin
        Initialize();
        C := Impl;
        Assert.AreEqual(15, C.Evaluate(5), 'Cross-app interface dispatch: Evaluate(5) must return 15');
    end;

    local procedure Double(X: Integer): Integer
    begin
        exit(X * 2);
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
