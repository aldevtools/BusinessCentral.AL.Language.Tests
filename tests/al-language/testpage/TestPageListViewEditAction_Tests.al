// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-view-method
// Scope: in-scope
// Fixtures used: TPVE Row (60457), TPVE Card (60458), TPVE List (60459),
//                TPVE Open Probe (60460), Assert (60021)
//
// What a list page's BUILT-IN View and Edit actions do when a test invokes them.
//
// TestPage.View() and TestPage.Edit() return a TestAction the test then invokes, exactly like
// a named action -- but nothing in the application declares them. The list says only
// CardPageId; the platform supplies the actions, decides that they open that card, decides
// which row it opens on, and decides which mode it opens in. So this is a different question
// from every page-opening route the corpus already pins:
//
//   * TestPageActionInvoke_Tests   -- an action whose effect is an OnAction trigger.
//   * TestPageActionRunObject_Tests -- an action whose effect is a RunObject declaration.
//   * TestPageRunHandler_Tests / TestPageModalHandler_Tests -- AL calling Page.Run/RunModal.
//
// All four of those name the target somewhere in AL. This one does not: the only declaration
// is CardPageId, and the actions come from the client.
//
// This is not an exotic corner. Microsoft's own BaseApp tests drive it -- Tests-User's
// LocationTransPlanbasedE2E opens the "Posted Transfer Shipments" LIST, invokes View(), and
// answers it with a [PageHandler] for the "Posted Transfer Shipment" CARD; Tests-SCM's
// SCMWarehouseDocumentsUI traps the "Purchase Order" card and then invokes View() on the
// purchase order LIST. Both depend on the behaviour asserted below, and nothing in this
// corpus said what it is.
//
// The four claims, each with a negative that a plausible wrong implementation fails:
//   1. Invoking the list's View action OPENS the card. An implementation that quietly did
//      nothing fails on the unrun handler, and on an open count of 0.
//   2. It opens on the list's CURRENT row. Every arm parks the list on its SECOND row, so an
//      implementation that opened the card unpositioned reports 'Alpha' instead of 'Bravo'.
//   3. It opens ONCE. An implementation that re-opened, or that opened the list's own card
//      and then a second one, reports a count of 2.
//   4. The MODE follows which of the two actions was invoked: View gives the handler a page
//      that is not editable, Edit gives it one that is. Asserting only one of the two would
//      let "always editable" or "always read-only" pass, so both are asserted, and control
//      arm 3 proves this fixture's card can be both.
//
// Written by an agent (impl-10), while establishing for AL Runner issue 2986 which parts of
// the "a page opened through an action" family a service tier can still not be asked about.

codeunit 60461 "TPVE Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "TPVE Row";
        Probe: Codeunit "TPVE Open Probe";
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

    // Claim 1 + 2 + 3 + 4, for View. The list is parked on its second row before the invoke,
    // so 'Bravo' is what a card that carried the list's row reports and 'Alpha' is what one
    // that opened unpositioned reports.
    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure ListViewActionOpensTheCardOnTheListsCurrentRowReadOnly()
    var
        Probe: Codeunit "TPVE Open Probe";
        List: TestPage "TPVE List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();
        List.View().Invoke();

        Assert.AreEqual(1, Probe.GetOpenCount(),
            'invoking the list View action must open the CardPageId card exactly once');
        Assert.AreEqual('Bravo', Probe.GetLastDescr(),
            'the card must open on the list''s current row');
        Assert.AreEqual(1, Probe.GetHandlerRuns(),
            'the platform must look up and run the [PageHandler] declared for the card');
        Assert.AreEqual('Bravo', Probe.GetLastHandlerDescr(),
            'the handler must be handed the same row the card opened on');
        Assert.IsFalse(Probe.GetLastHandlerEditable(),
            'the View action must open the card read-only');

        List.Close();
    end;

    // The Edit twin. Same list, same row, same card, same handler -- the only difference is
    // which of the two built-in actions is invoked, so a difference in what the handler sees
    // has isolated the action.
    [Test]
    [HandlerFunctions('CardPageHandler')]
    procedure ListEditActionOpensTheCardOnTheListsCurrentRowEditable()
    var
        Probe: Codeunit "TPVE Open Probe";
        List: TestPage "TPVE List";
    begin
        Initialize();
        Commit();

        List.OpenEdit();
        List.First();
        List.Next();
        List.Edit().Invoke();

        Assert.AreEqual(1, Probe.GetOpenCount(),
            'invoking the list Edit action must open the CardPageId card exactly once');
        Assert.AreEqual('Bravo', Probe.GetLastDescr(),
            'the card must open on the list''s current row');
        Assert.AreEqual(1, Probe.GetHandlerRuns(),
            'the platform must look up and run the [PageHandler] declared for the card');
        Assert.AreEqual('Bravo', Probe.GetLastHandlerDescr(),
            'the handler must be handed the same row the card opened on');
        Assert.IsTrue(Probe.GetLastHandlerEditable(),
            'the Edit action must open the card editable');

        List.Close();
    end;

    // CONTROL, and what makes claim 4 falsifiable. The card is opened directly, with no list
    // and no action anywhere in the picture, once each way. It reports both editability
    // states, so neither half of the pair above can be passing because this card is always
    // one or the other. It also proves the card's OnOpenPage marks the probe once per open,
    // without which the counts asserted above would mean nothing.
    [Test]
    procedure ControlTheCardIsEditableOrNotDependingOnHowItIsOpenedDirectly()
    var
        Probe: Codeunit "TPVE Open Probe";
        ViewCard: TestPage "TPVE Card";
        EditCard: TestPage "TPVE Card";
    begin
        Initialize();
        Commit();

        ViewCard.OpenView();
        Assert.IsFalse(ViewCard.Editable(),
            'a card opened with OpenView must report itself as not editable');
        ViewCard.Close();

        EditCard.OpenEdit();
        Assert.IsTrue(EditCard.Editable(),
            'a card opened with OpenEdit must report itself as editable');
        EditCard.Close();

        Assert.AreEqual(2, Probe.GetOpenCount(),
            'the card''s OnOpenPage must mark the probe once per open, otherwise the counts the other arms assert prove nothing');
        Assert.AreEqual(0, Probe.GetHandlerRuns(),
            'no handler runs when the card is opened directly by the test, so a handler run in the other arms is the platform''s doing');
    end;

    // Records what the handler could see and closes the page. A handler is gone by the time
    // the test resumes, so anything it observed has to be written somewhere the test can read.
    [PageHandler]
    procedure CardPageHandler(var Target: TestPage "TPVE Card")
    var
        Probe: Codeunit "TPVE Open Probe";
    begin
        Probe.MarkHandled(Target.Editable(), Target.Descr.Value());
        Target.Close();
    end;
}
