// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
//   and https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-bindsubscription-method
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Event Publisher (60014), ALT Event Subscriber (60015), ALT Manual Event Sub (60033)
// BC versions: 27.5+
//
// Contract tests for EventSubscriberInstance = Manual: a manual subscriber codeunit
// receives events ONLY while an instance is bound via BindSubscription, the event is
// dispatched to the BOUND INSTANCE (its instance state is visible to the binder), and
// UnbindSubscription stops delivery. All assertions verified against a real BC 28.3
// service tier before submission.
//
// Contracts 8-9 pin the STATEMENT form of BindSubscription (result discarded, not
// consumed as a Boolean) — see AL Runner issue #2393 — and the declaration-order
// leak-across-tests shape that issue was filed against.

codeunit 60240 "Test Event Manual Binding"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;
        LeakedManualSub: Codeunit "ALT Manual Event Sub";

    // ── Contract 1: Unbound Manual Subscriber Never Fires ──────────────────────────────

    [Test]
    procedure ManualSubscriber_NotBound_DoesNotFire()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        Handled := Publisher.TriggerBeforeAndReturnHandled(1);
        Assert.IsFalse(Handled, 'Unbound manual subscriber must not receive the event: Handled must stay false');
        Assert.AreEqual(0, ManualSub.GetFireCount(), 'Unbound manual subscriber instance must never have fired');
    end;

    // ── Contract 2: Bound Instance Receives The Event, With Instance State ─────────────

    [Test]
    procedure ManualSubscriber_Bound_FiresOnBoundInstance()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        Assert.IsTrue(BindSubscription(ManualSub), 'BindSubscription on an unbound manual subscriber must return true');
        Handled := Publisher.TriggerBeforeAndReturnHandled(2);
        Assert.IsTrue(Handled, 'Bound manual subscriber must receive the event and set Handled');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'The bound instance itself must have received exactly one fire');
        Assert.AreEqual(2, ManualSub.GetLastEntryNo(), 'The bound instance must have seen the published EntryNo');
        UnbindSubscription(ManualSub);
    end;

    // ── Contract 3: Unbind Stops Delivery, Instance State Freezes ──────────────────────

    [Test]
    procedure ManualSubscriber_Unbind_StopsFiring()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub: Codeunit "ALT Manual Event Sub";
        Handled: Boolean;
    begin
        Initialize();
        BindSubscription(ManualSub);
        Publisher.TriggerBeforeAndReturnHandled(3);
        Assert.IsTrue(UnbindSubscription(ManualSub), 'UnbindSubscription on a bound instance must return true');
        Handled := Publisher.TriggerBeforeAndReturnHandled(4);
        Assert.IsFalse(Handled, 'After unbind the manual subscriber must no longer receive events');
        Assert.AreEqual(1, ManualSub.GetFireCount(), 'Fire count must stay at 1 after unbind');
        Assert.AreEqual(3, ManualSub.GetLastEntryNo(), 'Last seen EntryNo must still be the pre-unbind value');
    end;

    // ── Contract 4: Binding The Same Instance Twice Returns False ──────────────────────

    [Test]
    procedure BindSubscription_AlreadyBoundInstance_ReturnsFalse()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
        SecondBind: Boolean;
    begin
        Initialize();
        BindSubscription(ManualSub);
        SecondBind := BindSubscription(ManualSub);
        Assert.AreEqual(false, SecondBind, 'Second BindSubscription on the same already-bound instance must return false, not raise an error');
        UnbindSubscription(ManualSub);
    end;

    // ── Contract 5: BindSubscription On A Static Subscriber Returns False ──────────────

    [Test]
    procedure BindSubscription_StaticSubscriber_ReturnsFalse()
    var
        StaticSub: Codeunit "ALT Event Subscriber";
        BindResult: Boolean;
    begin
        Initialize();
        BindResult := BindSubscription(StaticSub);
        Assert.AreEqual(false, BindResult, 'BindSubscription on a codeunit without EventSubscriberInstance = Manual must return false, not raise an error');
    end;

    // ── Contract 6: UnbindSubscription On A Never-Bound Manual Instance Returns True ───

    [Test]
    procedure UnbindSubscription_NeverBoundManualInstance_ReturnsTrue()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
        UnbindResult: Boolean;
    begin
        Initialize();
        UnbindResult := UnbindSubscription(ManualSub);
        Assert.AreEqual(true, UnbindResult, 'UnbindSubscription on a never-bound MANUAL instance returns true (container-verified BC behavior)');
    end;

    // ── Contract 7: Each Bound Instance Of The Same Codeunit Fires Once ────────────────

    [Test]
    procedure ManualSubscriber_TwoBoundInstances_EachFiresOnce()
    var
        Publisher: Codeunit "ALT Event Publisher";
        ManualSub1: Codeunit "ALT Manual Event Sub";
        ManualSub2: Codeunit "ALT Manual Event Sub";
    begin
        Initialize();
        Assert.IsTrue(BindSubscription(ManualSub1), 'Bind of first instance must succeed');
        Assert.IsTrue(BindSubscription(ManualSub2), 'Bind of second instance must succeed');
        Publisher.TriggerBeforeAndReturnHandled(5);
        Assert.AreEqual(1, ManualSub1.GetFireCount(), 'First bound instance must fire exactly once');
        Assert.AreEqual(1, ManualSub2.GetFireCount(), 'Second bound instance must fire exactly once');
        UnbindSubscription(ManualSub1);
        UnbindSubscription(ManualSub2);
    end;

    // ── Contract 8: Statement-Form Rebind Of An Already-Bound Instance Raises ──────────
    //
    // Contract 4 covers the EXPRESSION form (assigned to / consumed as a Boolean), where
    // BindSubscription returns false on an already-bound instance instead of raising.
    // AL compiles BindSubscription differently when its result is discarded as a plain
    // STATEMENT: the failure is raised, not swallowed into a false return. This is the
    // form Microsoft's own Tests-SINGLESERVER corpus uses (Codeunit 134614
    // "Test App Permissions": `BindSubscription(AzureADGraphTestLibrary);`), and AL
    // Runner issue #2393 was opened against exactly this call shape.

    [Test]
    procedure BindSubscription_StatementForm_AlreadyBoundInstance_Raises()
    var
        ManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Initialize();
        BindSubscription(ManualSub);
        asserterror BindSubscription(ManualSub);
        Assert.ExpectedError('already been bound');
        UnbindSubscription(ManualSub);
    end;

    // ── Contract 9: A Binding Left Open By One [Test] Survives Into The Next [Test] On
    //    The Same Codeunit Instance ─────────────────────────────────────────────────────
    //
    // TestIsolation = Codeunit (the default) shares one codeunit instance across every
    // [Test] in the codeunit - see TestIsolationGlobalVariableScope (60898). A GLOBAL
    // codeunit-typed variable bound via BindSubscription, where UnbindSubscription is
    // never reached before the test ends, leaves that binding in place for the next
    // [Test] in declaration order on the SAME instance - BC does not release it as part
    // of moving on to the next test.
    //
    // This is the exact shape behind AL Runner issue #2393: Microsoft's
    // TestAppPermissions codeunit binds a global "AzureADGraphTestLibrary" once per test
    // and unbinds it at the end of each test. When an EARLIER, unrelated assertion in one
    // test fails, that test's own UnbindSubscription call is skipped entirely (the failure
    // aborts the rest of the test body), and every subsequent test's BindSubscription on
    // the same still-bound global then raises "already bound" - a real, faithful BC
    // outcome cascading from the earlier test's own defect, not a binding-mechanism defect
    // in its own right. Test09a below reproduces only the "Unbind never reached" half
    // (without also asserting on an unrelated failure, to keep this suite's own pass/fail
    // signal clean); Test09b proves what the next test then observes. These two tests are
    // declaration-ordered on purpose, the same convention TestIsolationGlobalVariableScope
    // uses, and must not be reordered.

    [Test]
    procedure ManualSubscriber_Test09a_BindsAndDeliberatelyNeverUnbinds()
    begin
        Initialize();
        Assert.IsTrue(BindSubscription(LeakedManualSub), 'The first bind on a fresh instance must succeed');
        // No UnbindSubscription call here - proving the binding survives into the next
        // [Test] procedure below when Unbind is skipped, for any reason.
    end;

    [Test]
    procedure ManualSubscriber_Test09b_RebindOnSameInstanceAfterPriorTestNeverUnbound()
    begin
        asserterror BindSubscription(LeakedManualSub);
        Assert.ExpectedError('already been bound');
        UnbindSubscription(LeakedManualSub);
    end;

    // ── Contract 10: A LOCAL Variable's Binding Does NOT Outlive Its Own Procedure ──
    //
    // Contract 9 proved a GLOBAL codeunit-typed variable's binding survives into the next
    // [Test] on the same codeunit, because the codeunit instance holding that global field
    // is itself kept alive for every [Test] under TestIsolation = Codeunit. This pins the
    // other half: a LOCAL variable, declared inside the [Test] procedure itself, has
    // nothing left referencing it the instant that procedure returns. BC's own
    // NavCodeunit.Dispose(bool) removes a disposed instance's binding from
    // Session.EventBindings when it was still bound (IsSubscriptionBound), and a local
    // variable's underlying object IS disposed at that point, unlike a global one.
    //
    // Measured against real BC (this test's first version asserted the opposite — that a
    // local variable's binding survives exactly like Contract 9's global one — and BC's own
    // CI failed it on all 8 legs, 27.0 through 28.4: the leaked local-variable subscriber
    // did NOT fire in Test10b. That is not a violation of "never invert a green upstream
    // assertion" — the original Test10b had never merged, so there was nothing green to
    // invert; this is the normal write-test/let-CI-adjudicate/correct-the-expectation loop).
    //
    // The distinction that matters is variable LIFETIME, not the BindSubscription
    // mechanism itself: a codeunit variable that outlives its declaring procedure (global)
    // keeps its binding: one that doesn't (local) loses it when disposed. A future reader
    // hitting "already been bound" from a leaked binding needs to know which of these two
    // shapes they are looking at before assuming the fix is "just unbind" — for a global
    // variable, TestIsolation = Codeunit's per-codeunit boundary is the only thing that
    // will ever clear it; for a local one, ordinary procedure-scope disposal already does.
    //
    // Filed against AL Runner issue #2466, where a LOCAL-variable BindSubscription left
    // open by one [Test] procedure in Microsoft's own Tests-SINGLESERVER corpus
    // (Codeunit 139004 "Test ApplicationArea Setup") was initially read as possibly
    // faithful within-codeunit persistence like Contract 9's. It is not: real BC releases
    // that binding, so a runner that keeps it bound diverges from BC and is a genuine gap.

    [Test]
    procedure ManualSubscriber_Test10a_LocalVariableBindsAndDeliberatelyNeverUnbinds()
    var
        LocalManualSub: Codeunit "ALT Manual Event Sub";
    begin
        Initialize();
        Assert.IsTrue(
            BindSubscription(LocalManualSub),
            'The first bind of a fresh LOCAL-variable instance must succeed');
        // No UnbindSubscription call here, and LocalManualSub is a LOCAL variable that
        // goes out of scope the moment this procedure returns.
    end;

    [Test]
    procedure ManualSubscriber_Test10b_PriorTestsLocalVariableBindingDoesNotFireHere()
    var
        Publisher: Codeunit "ALT Event Publisher";
        Handled: Boolean;
    begin
        Handled := Publisher.TriggerBeforeAndReturnHandled(10);
        Assert.IsFalse(
            Handled,
            'A manual subscriber bound via a LOCAL variable in the PREVIOUS [Test] ' +
            'procedure, on this same codeunit, and never explicitly unbound, must NOT ' +
            'fire here: the local variable went out of scope when that procedure ' +
            'returned, and BC disposes the underlying instance at that point (unlike a ' +
            'GLOBAL codeunit variable, whose binding DOES survive - see Contract 9).');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
