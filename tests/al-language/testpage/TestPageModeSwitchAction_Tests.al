// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-edit-method
// Scope: in-scope
// Fixtures used: TPMS Row (60472), TPMS Open Probe (60473), TPMS Card (60474),
//                TPMS RO Card (60475), TPMS Plain List (60476), TPMS RO List (60477),
//                TPMS List (60478), Assert (60021)
//
// What a page's built-in View and Edit actions do when they do NOT open a card, and what
// Visible() and Enabled() answer on them.
//
// TPVE Tests (60461) pins the half where a card opens: a List with a CardPageId, View() or
// Edit() invoked, the card opens once, on the list's row, in the requested mode. Everything
// here is the other half, and none of it was pinned anywhere:
//
//   1. On a page that is NOT a list -- a Card opened read-only -- Edit().Invoke() does not open
//      anything. The page already on screen becomes editable. The card's OnOpenPage counter
//      staying at 1 is what says that: an implementation that answered the same AL by opening a
//      second copy of the card would report 2, and would still pass an Editable() assertion.
//      The row is asserted before and after for the same reason, and the switched page is then
//      written to, because "reports itself editable" and "accepts a value" are different claims.
//   2. Invoked when the page is ALREADY in the requested mode, both actions are still Visible
//      but are NOT Enabled, and invoking one does nothing at all -- it does not raise, and it
//      does not change the mode back. Enabled() is where that shows up, which is the finding:
//      Visible() is true in every shape below, so a test that read only Visible() would see no
//      difference between an action that applies and one that does not.
//   3. On a List with no CardPageId both actions still exist and are Visible; only View is
//      Enabled; and invoking either opens nothing.
//   4. On a List whose CardPageId card declares Editable = false, the Edit action is Visible
//      and NOT Enabled, and invoking it opens nothing -- while the View action is Enabled and
//      opens that card read-only.
//
// NOT ASSERTED HERE, and deliberately: a Card whose own Editable = false has NO built-in Edit
// action, and BC does not report that as an AL error. TestPage.Edit() hands back a NavTestAction
// wrapping a null client action, so `Card.Edit().Invoke()` and `Card.Edit().Visible()` each
// raise a bare System.NullReferenceException from NavTestAction.ALInvoke()/ALVisible(). That is
// a CLR exception, not an AL error: it is caught neither by asserterror nor by a [TryFunction],
// so there is no way to write it as an arm that passes. Measured on BC 28.4.53241.0 rather than
// reasoned about; recorded here so the next reader does not have to re-measure it.
//
// Written by an agent (fbk-2), for AL Runner issue 3258.

codeunit 60479 "TPMS Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPMS Row";
        Probe: Codeunit "TPMS Open Probe";
    begin
        Row.DeleteAll();
        Probe.Reset();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();
    end;

    // Claim 1. A read-only card, made editable by its own Edit action, without opening anything.
    [Test]
    procedure CardOpenedReadOnlyIsMadeEditableInPlaceByItsEditAction()
    var
        Probe: Codeunit "TPMS Open Probe";
        Card: TestPage "TPMS Card";
    begin
        Initialize();
        Commit();

        Card.OpenView();
        Assert.IsFalse(Card.Editable(), 'a card opened with OpenView starts out not editable');
        Assert.IsTrue(Card.Edit().Visible(), 'the built-in Edit action is visible on a read-only card');
        Assert.IsTrue(Card.Edit().Enabled(),
            'the built-in Edit action is enabled on a card that is currently read-only');

        Card.Edit().Invoke();

        Assert.IsTrue(Card.Editable(), 'invoking the built-in Edit action makes the open page editable');
        Assert.AreEqual(1, Probe.GetCardOpens(),
            'the mode changes on the page already open: the card''s OnOpenPage must NOT run a second time');
        Assert.AreEqual('Alpha', Card.Descr.Value(),
            'the switched page must still be on the row it was showing');

        // "Reports itself editable" and "accepts a value" are separate claims; assert both.
        Card.Descr.SetValue('Changed');
        Assert.AreEqual('Changed', Card.Descr.Value(),
            'the page really is editable after the switch, not merely reporting that it is');

        Card.Close();
    end;

    // Claim 1, mirrored. The mirror is what rules out "Editable() always answers true after any
    // built-in action is invoked".
    [Test]
    procedure CardOpenedEditableIsMadeReadOnlyInPlaceByItsViewAction()
    var
        Probe: Codeunit "TPMS Open Probe";
        Card: TestPage "TPMS Card";
    begin
        Initialize();
        Commit();

        Card.OpenEdit();
        Assert.IsTrue(Card.Editable(), 'a card opened with OpenEdit starts out editable');
        Assert.IsTrue(Card.View().Visible(), 'the built-in View action is visible on an editable card');
        Assert.IsTrue(Card.View().Enabled(),
            'the built-in View action is enabled on a card that is currently editable');

        Card.View().Invoke();

        Assert.IsFalse(Card.Editable(), 'invoking the built-in View action makes the open page read-only');
        Assert.AreEqual(1, Probe.GetCardOpens(),
            'the mode changes on the page already open: the card''s OnOpenPage must NOT run a second time');
        Assert.AreEqual('Alpha', Card.Descr.Value(),
            'the switched page must still be on the row it was showing');

        Card.Close();
    end;

    // Claim 2. The action the page's current mode does not apply to.
    [Test]
    procedure EditActionOnAnAlreadyEditableCardIsVisibleButNotEnabledAndDoesNothing()
    var
        Probe: Codeunit "TPMS Open Probe";
        Card: TestPage "TPMS Card";
    begin
        Initialize();
        Commit();

        Card.OpenEdit();
        Assert.IsTrue(Card.Edit().Visible(),
            'the built-in Edit action stays visible on a card that is already editable');
        Assert.IsFalse(Card.Edit().Enabled(),
            'the built-in Edit action is NOT enabled on a card that is already editable');

        // Not an error, and not a mode change: invoking it is a no-op.
        Card.Edit().Invoke();

        Assert.IsTrue(Card.Editable(), 'invoking the disabled Edit action leaves the page editable');
        Assert.AreEqual(1, Probe.GetCardOpens(), 'invoking the disabled Edit action opens nothing');

        Card.Close();
    end;

    // Claim 2, mirrored.
    [Test]
    procedure ViewActionOnAnAlreadyReadOnlyCardIsVisibleButNotEnabledAndDoesNothing()
    var
        Probe: Codeunit "TPMS Open Probe";
        Card: TestPage "TPMS Card";
    begin
        Initialize();
        Commit();

        Card.OpenView();
        Assert.IsTrue(Card.View().Visible(),
            'the built-in View action stays visible on a card that is already read-only');
        Assert.IsFalse(Card.View().Enabled(),
            'the built-in View action is NOT enabled on a card that is already read-only');

        Card.View().Invoke();

        Assert.IsFalse(Card.Editable(), 'invoking the disabled View action leaves the page read-only');
        Assert.AreEqual(1, Probe.GetCardOpens(), 'invoking the disabled View action opens nothing');

        Card.Close();
    end;

    // Claim 3. A list with nothing to open. No [HandlerFunctions] on purpose: a page opened here
    // would fail the test on the unhandled open, which is a second, independent way of asserting
    // that neither invoke opens anything.
    [Test]
    procedure PlainListWithoutCardPageIdOffersBothActionsAndEnablesOnlyView()
    var
        Probe: Codeunit "TPMS Open Probe";
        List: TestPage "TPMS Plain List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();

        Assert.IsTrue(List.View().Visible(), 'a list without a CardPageId still has a built-in View action');
        Assert.IsTrue(List.View().Enabled(), 'that View action is enabled');
        Assert.IsTrue(List.Edit().Visible(), 'a list without a CardPageId still has a built-in Edit action');
        Assert.IsFalse(List.Edit().Enabled(),
            'that Edit action is NOT enabled: the list has no card to open editable');

        List.View().Invoke();
        List.Edit().Invoke();

        Assert.AreEqual(0, Probe.GetCardOpens(), 'neither invoke opens the editable card');
        Assert.AreEqual(0, Probe.GetRoCardOpens(), 'neither invoke opens the read-only card');

        List.Close();
    end;

    // Claim 4. The Edit half: a card that cannot be edited leaves the action visible and
    // disabled, and invoking it opens nothing.
    [Test]
    procedure ListWhoseCardIsReadOnlyLeavesTheEditActionVisibleButNotEnabled()
    var
        Probe: Codeunit "TPMS Open Probe";
        List: TestPage "TPMS RO List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();

        Assert.IsTrue(List.Edit().Visible(),
            'a list whose CardPageId card is read-only still has a built-in Edit action');
        Assert.IsFalse(List.Edit().Enabled(), 'that Edit action is NOT enabled');

        List.Edit().Invoke();

        Assert.AreEqual(0, Probe.GetRoCardOpens(), 'invoking it does not open the read-only card');
        Assert.AreEqual(0, Probe.GetCardOpens(), 'invoking it does not open any other card either');

        List.Close();
    end;

    // Claim 4. The View half of the same list: enabled, and it does open that card, read-only.
    [Test]
    [HandlerFunctions('RoCardPageHandler')]
    procedure ListWhoseCardIsReadOnlyStillOpensItThroughTheViewAction()
    var
        Probe: Codeunit "TPMS Open Probe";
        List: TestPage "TPMS RO List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();

        Assert.IsTrue(List.View().Visible(), 'the built-in View action is visible');
        Assert.IsTrue(List.View().Enabled(), 'the built-in View action is enabled even though the card is read-only');

        List.View().Invoke();

        Assert.AreEqual(1, Probe.GetRoCardOpens(), 'the View action opens the read-only card exactly once');
        Assert.AreEqual(1, Probe.GetHandlerRuns(), 'the platform looks up and runs the card''s [PageHandler]');
        Assert.IsFalse(Probe.GetLastHandlerEditable(), 'the handler is handed a card that is not editable');

        List.Close();
    end;

    // Control for claims 3 and 4: on the TPVE shape -- a list whose card IS editable -- both
    // actions are visible AND both are enabled. Without this arm, "Edit is not enabled" above
    // could be true of every list rather than of those two shapes.
    [Test]
    procedure ListWithAnEditableCardPageIdEnablesBothActions()
    var
        List: TestPage "TPMS List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();

        Assert.IsTrue(List.View().Visible(), 'the built-in View action is visible');
        Assert.IsTrue(List.View().Enabled(), 'the built-in View action is enabled');
        Assert.IsTrue(List.Edit().Visible(), 'the built-in Edit action is visible');
        Assert.IsTrue(List.Edit().Enabled(),
            'the built-in Edit action is enabled when the CardPageId card allows modification');

        List.Close();
    end;

    // The shape the switch exists for. Microsoft's own tests do it inside a handler --
    // SubscriptionBilling's ContractRenewalTest is `if not Page.Editable then Page.Edit().Invoke()`
    // in a [ModalPageHandler] -- and a page a handler is handed was never opened by the test, so
    // it reaches its editability by a different route than the arms above.
    [Test]
    [HandlerFunctions('CardModalHandler')]
    procedure ACardHandedToAModalPageHandlerSwitchesModeInPlaceToo()
    var
        Probe: Codeunit "TPMS Open Probe";
        Row: Record "TPMS Row";
    begin
        Initialize();
        Commit();

        Row.FindFirst();
        Page.RunModal(Page::"TPMS Card", Row);

        Assert.AreEqual('Yes;No;Yes', Probe.GetSteps(),
            'the handler reads Editable(), invokes View(), reads it again, invokes Edit(), and reads it a third time');
        Assert.AreEqual(1, Probe.GetCardOpens(),
            'both switches happen on the page the handler was handed: OnOpenPage must run once');
    end;

    [PageHandler]
    procedure RoCardPageHandler(var Target: TestPage "TPMS RO Card")
    var
        Probe: Codeunit "TPMS Open Probe";
    begin
        Probe.MarkHandled(Target.Editable());
        // The card declares Editable = false, so it is already in the mode the View action
        // would put it in. Enabled is the channel that says so.
        Assert.IsFalse(Target.View().Enabled(),
            'the built-in View action is not enabled on a card that is already read-only');
        Target.Close();
    end;

    [ModalPageHandler]
    procedure CardModalHandler(var Target: TestPage "TPMS Card")
    var
        Probe: Codeunit "TPMS Open Probe";
    begin
        Probe.AddStep(Format(Target.Editable()));
        Target.View().Invoke();
        Probe.AddStep(Format(Target.Editable()));
        Target.Edit().Invoke();
        Probe.AddStep(Format(Target.Editable()));
    end;
}
