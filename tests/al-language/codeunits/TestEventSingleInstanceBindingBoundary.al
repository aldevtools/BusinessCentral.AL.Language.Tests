// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT SI Bind Publisher (67690), ALT SI Bind Survivor (67691),
//   ALT Plain Bind Contrast (67692), ALT SI Held Binder (67695), ALT SI Held Subscriber (67696),
//   ALT SI Session Witness (67697)
// BC versions: 27.5+
//
// Does a manual binding survive a TEST-CODEUNIT boundary when a SingleInstance codeunit keeps
// the subscriber instance alive? (AL Runner issue #4799.)
//
// TestEventManualBindingCrossCodeunit (60244/60245) pins that an ordinary subscriber's
// binding does not reach the next test codeunit. TestManualBindByValue (67370) pins that a
// manual binding ends when the last reference to the instance goes away, and that a
// SingleInstance instance outlives the local that bound it. This pair asks the combination:
// the binding is session state (Session.EventBindings), removed by UnbindSubscription or by
// the subscriber instance being disposed; a SingleInstance instance, and whatever its globals
// hold, is kept by the company scope, which a test-codeunit boundary does not dispose (see
// TestCodeunitSICLeak, 60600).
//
// 67693 binds three subscribers and leaves them bound: a SingleInstance subscriber, an
// ordinary subscriber held in 67693's own global, and an ordinary subscriber held in a
// SingleInstance codeunit's global. 67694 raises the event. The one held by 67693 is the
// contrast: it must be gone, so a runtime that simply kept every binding cannot pass.
//
// Run order: 67693 before 67694, the ascending codeunit-id order 60244/60245 rely on.
// Runner: Test Runner - Isol. Codeunit (130450), TestIsolation = Codeunit, both codeunits in
// ONE session. A harness that opens a new session per test codeunit (`al runtests`, one
// TestRunnerHub connection each) carries nothing across: 67697, armed by 67693, tells 67694
// which case it is in, and 67694 asserts the matching outcome.
// Today the real claim (the SingleInstance and held-subscriber arms) is asserted only where both
// codeunits share a session: BC 27.x Linux legs and the Windows nightly. The 28.x Linux legs (one
// `al runtests` per codeunit, a fresh NavSession) assert only the new-session branch. If 27.x ever
// moves to a session per codeunit, no Linux leg asserts the claim, and every leg stays green.

codeunit 67693 "Test SI Bind Boundary Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        PlainSub: Codeunit "ALT Plain Bind Contrast";

    [Test]
    procedure BindsThreeSubscribersAndLeavesThemBound()
    var
        Publisher: Codeunit "ALT SI Bind Publisher";
        SingleInstanceSub: Codeunit "ALT SI Bind Survivor";
        HeldBinder: Codeunit "ALT SI Held Binder";
        Witness: Codeunit "ALT SI Session Witness";
        SingleInstanceHit: Boolean;
        PlainHit: Boolean;
        HeldHit: Boolean;
        SameSession: Boolean;
    begin
        Witness.Arm();
        Assert.IsTrue(BindSubscription(SingleInstanceSub), 'BindSubscription on the SingleInstance subscriber must return true');
        Assert.IsTrue(BindSubscription(PlainSub), 'BindSubscription on the plain subscriber must return true');
        Assert.IsTrue(HeldBinder.BindHeld(), 'BindSubscription on the subscriber held by a SingleInstance codeunit must return true');

        Publisher.Raise(SingleInstanceHit, PlainHit, HeldHit, SameSession);

        Assert.IsTrue(SameSession, 'The armed SingleInstance witness must answer in the codeunit that armed it');
        Assert.IsTrue(SingleInstanceHit, 'The bound SingleInstance subscriber must fire in the codeunit that bound it');
        Assert.IsTrue(PlainHit, 'The bound plain subscriber must fire in the codeunit that bound it');
        Assert.IsTrue(HeldHit, 'The subscriber bound through a SingleInstance codeunit must fire in the codeunit that bound it');
        // Deliberately no UnbindSubscription: 67694 reads what crossed the boundary.
    end;
}

codeunit 67694 "Test SI Bind Boundary Check"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure BindingsASingleInstanceKeepsAliveCrossTheCodeunitBoundary()
    var
        Publisher: Codeunit "ALT SI Bind Publisher";
        SingleInstanceHit: Boolean;
        PlainHit: Boolean;
        HeldHit: Boolean;
        SameSession: Boolean;
    begin
        Publisher.Raise(SingleInstanceHit, PlainHit, HeldHit, SameSession);

        Assert.IsFalse(PlainHit, 'An ordinary subscriber held by the previous test codeunit must not fire here');
        if not SameSession then begin
            // A new session: no SingleInstance instance and no binding from 67693 exists here.
            Assert.IsFalse(SingleInstanceHit, 'In a session 67693 did not run in, no SingleInstance subscriber is bound');
            Assert.IsFalse(HeldHit, 'In a session 67693 did not run in, no held subscriber is bound');
            exit;
        end;
        Assert.IsTrue(SingleInstanceHit, 'A SingleInstance subscriber bound by the previous test codeunit must still fire here: its instance is not released at the boundary, so neither is its binding');
        Assert.IsTrue(HeldHit, 'An ordinary subscriber held in a SingleInstance codeunit''s global must still fire here: the SingleInstance codeunit keeps it alive across the boundary');
    end;
}
