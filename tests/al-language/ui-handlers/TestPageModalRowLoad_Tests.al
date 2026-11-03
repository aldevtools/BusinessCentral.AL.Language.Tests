// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-triggers-auto-page-onaftergetrecord
// Scope: in-scope
// Fixtures used: MRL Row (60400), MRL Probe (60401), MRL Modal Card (60402), Assert
//
// Pins that a page opened modally ON A ROW THE CALLER ALREADY POSITIONED — the
// `PAGE.RunModal(id, Rec)` shape — still raises its OnAfterGetRecord for that row before the
// [ModalPageHandler] gets to read anything.
//
// The two halves are one claim and have to be asserted together, because a plausible
// implementation gets each one right on its own and both wrong together:
//
//   * the trigger must FIRE (a page whose per-row state is derived in OnAfterGetRecord shows
//     nothing at all otherwise), and
//   * it must fire for the CALLER'S row, not for whatever sorts first (re-querying the table
//     to get a row to load is not the same thing, and would silently move the page off the
//     row the caller opened it on).
//
// The fixture is built so those two cannot both pass by accident: two rows exist, and the
// caller deliberately opens the page on the SECOND one. A page that never load-triggers
// writes no probe row; a page that re-queries writes the first row's; only loading the
// caller's row writes 'B'.
//
// Deliberately NOT in OnOpenPage: when a page is opened modally and handed to a handler,
// OnOpenPage and OnAfterGetRecord are reached by different mechanisms, and this suite is
// about the row-load one. Prompted by AlRunner#2797, where Base Application page 403
// "Purchase Order Statistics" — which computes every total it shows in OnAfterGetRecord and
// nothing in OnOpenPage — displayed zeros for exactly this reason.
codeunit 60403 "Test Modal Row Load"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "MRL Row";
        Probe: Record "MRL Probe";
    begin
        Probe.DeleteAll();
        Row.DeleteAll();

        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'beta';
        Row.Insert();
    end;

    [Test]
    [HandlerFunctions('MrlModalHandler')]
    procedure ModalPageOnACallerPositionedRow_RaisesOnAfterGetRecordForThatRow()
    var
        Row: Record "MRL Row";
        Probe: Record "MRL Probe";
    begin
        Initialize();

        // The caller positions on 'B' — deliberately not the row that sorts first.
        Row.Get('B');
        PAGE.RunModal(PAGE::"MRL Modal Card", Row);

        Assert.IsTrue(Probe.Get('B'),
            'The modal page''s OnAfterGetRecord must have run for the row the caller opened it on.');
        Assert.AreEqual('beta', Probe.Seen,
            'OnAfterGetRecord must have seen that row''s own field values.');
        Assert.IsFalse(Probe.Get('A'),
            'The page must not have loaded the table''s first row: RunModal was given a specific row.');
        Assert.AreEqual(1, Probe.Count(),
            'Exactly one row may have been loaded — the caller''s.');
    end;

    [ModalPageHandler]
    procedure MrlModalHandler(var ModalCard: TestPage "MRL Modal Card")
    begin
        // Deliberately does nothing, and in particular does NOT close the page.
        //
        // The claim is about what the page did BEFORE the handler ran, so the handler needs no
        // interaction at all — and it has no way to close cleanly anyway: a plain Card-type
        // modal has no client OK/Cancel affordance (only PageType = StandardDialog gets that
        // chrome, as TestPageModalHandler_ModalPage.al records), and calling Close() here makes
        // RunModal raise 'The RunModal procedure could not close the page ... as it has already
        // been closed.' on real BC. Letting RunModal close it is the correct shape.
    end;
}
