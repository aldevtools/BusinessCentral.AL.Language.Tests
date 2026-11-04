// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testisolation-property
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Event Publisher (60014), ALT Manual Event Sub (60033)
// BC versions: 27.5+
//
// Companion to TestEventManualBinding's Contract 9 (codeunit 60240): that contract pins
// that a BindSubscription left open by one [Test] survives into the NEXT [Test] on the
// SAME codeunit instance, under TestIsolation = Codeunit — real BC does not release a
// manual binding just because a test procedure returned.
//
// This file pins the OTHER half of that boundary: a binding left open by one test
// CODEUNIT does NOT survive into the NEXT test codeunit's run. TestIsolation = Codeunit
// (BC's "Test Runner - Isol. Codeunit", 130450) wraps each codeunit's tests in one
// transaction and starts the next codeunit fresh (see TestIsolationRollbackScope, 60897,
// for the database half of that same boundary) — Session.EventBindings is part of what
// "fresh" resets, not just table data.
//
// Two codeunits, run in codeunit-ID order (60244 before 60245, matching the ascending
// order BC's own test tool runs a codeunit range in — the same ordering assumption
// TestIsolationRollbackScope/TestIsolationGlobalVariableScope already rely on, just
// across a codeunit boundary instead of within one).

codeunit 60244 "Test Manual Bind Leak Setup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure BindsAManualSubscriberAndDeliberatelyNeverUnbinds()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Assert.IsTrue(
            BindSubscription(ManualSub),
            'The first bind on a fresh instance must succeed.');
        // No UnbindSubscription call here, and ManualSub is a LOCAL variable that goes
        // out of scope the moment this procedure returns — proving the leak does not
        // depend on the binder being a global variable (Contract 9 already covers the
        // global-variable shape).
    end;
}

codeunit 60245 "Test Manual Bind No Cross CU"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure PriorCodeunitsLeakedBindingDoesNotFireHere()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Handled: Boolean;
    begin
        Handled := Publisher.TriggerBeforeAndReturnHandled(60245001);

        Assert.IsFalse(
            Handled,
            'A manual subscriber bound (and never unbound) by an earlier test CODEUNIT ' +
            'must not still be bound here: TestIsolation = Codeunit starts each new test ' +
            'codeunit with no manual event bindings left over from the previous one, even ' +
            'though bindings persist across [Test] procedures within the SAME codeunit ' +
            '(see TestEventManualBinding Contract 9). If this fails, either the previous ' +
            'codeunit''s binding leaked across the codeunit boundary, or these two ' +
            'codeunits ran out of ID order.');
    end;
}
