// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-subpages-overview
// Scope: in-scope
// Fixtures used: TPMF Line (60415), TPMF Head (60416), TPMF Part (60417), TPMF Card (60418),
//                Assert (60021)
//
// WHAT THIS SUITE MEASURES, AND WHY IT EXISTS
//
// A test client can close a page two ways: the test calls TestPage.Close() itself, or the
// test calls RunModal() on a page variable and the platform closes the page on the
// [ModalPageHandler]'s behalf when the handler returns. Whether those two routes agree about
// an UNCOMMITTED SUBPAGE-PART ROW is not pinned anywhere in this corpus.
//
// The corpus already pins one half: "ALT TestPart Tests" (60341) asserts that a part row
// started with Lines.New() and written with SetValue reaches the part's own table after
// TestPage.Close(). Nothing asserts what the RunModal route does with the same buffer.
//
// So the suite drives ONE host page (TPMF Card, 60418) through BOTH routes and asserts they
// answer the same. Everything else is held constant deliberately — same host page, same
// part page, same tables, same New()+SetValue sequence, no Commit anywhere — so the only
// difference between the two arms is how the page was closed. An arm failing therefore
// localizes to the close route and to nothing else.
//
// WHAT DISTINGUISHES THE TWO CANDIDATE ANSWERS
//
// The observable is the part's own table after the page is gone:
//   * the part row EXISTS  => that close route wrote the part buffer back
//   * the part row ABSENT  => that close route discarded it
//
// The host row is read separately in the same arms, and that separation is load-bearing: a
// close route could write the HOST record back while discarding the PART buffer, and a suite
// that only looked at one table could not tell that apart from "nothing was written".
//
// THE CONFOUND THE SUITE HAS TO AVOID, AND HOW IT DOES
//
// Invoking a page ACTION is itself a moment at which a client sends the edited row to the
// server. So a handler that ends with OK().Invoke() can persist its part row through the
// ACTION and tell you nothing about the CLOSE. Arms F, G and H therefore invoke nothing at
// all: the handler writes and returns, and the platform closes the page on its behalf. Those
// three are the arms that measure the close itself, and a reader comparing the two routes
// should read F against G first.
//
// The arms that do invoke OK (B, C, E) are kept because they pin the ordinary confirming
// shape, which is what most AL actually writes.
//
// The negative arms are the ones that stop this suite passing vacuously. A part that never
// accepted the write at all, and a table that already contained the row, would both make the
// positive assertions true for the wrong reason — so each arm starts from an empty table
// (asserted) and the write uses values no fixture seeds.

codeunit 60420 "TPMF Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Line: Record "TPMF Line";
        Head: Record "TPMF Head";
    begin
        Line.DeleteAll();
        Head.DeleteAll();
    end;

    local procedure SeedHead(): Code[20]
    var
        Head: Record "TPMF Head";
    begin
        Head.Init();
        Head."No." := 'H1';
        Head.Descr := 'SeededHead';
        Head.Insert();
        exit(Head."No.");
    end;

    // ── Arm A: the route the test client drives itself ────────────────────────────
    //
    // The control arm. TestPage.Close() on a host whose part carries an uncommitted New()
    // row. Restates on this fixture what codeunit 60341 already pins on its own, so the two
    // arms below are compared against a result measured on THIS host page rather than
    // against a claim carried over from a different one.
    [Test]
    procedure ModalPartFlush_TestPageClose_PersistsThePartRow()
    var
        Line: Record "TPMF Line";
        Card: TestPage "TPMF Card";
    begin
        Initialize();
        SeedHead();

        Assert.RecordIsEmpty(Line);

        Card.OpenEdit();
        Card.Lines.New();
        Card.Lines.HeadNo.SetValue('H1');
        Card.Lines.LineNo.SetValue(10000);
        Card.Lines.Descr.SetValue('ClosedByTest');
        Card.Close();

        Assert.IsTrue(Line.Get('H1', 10000),
            'TestPage.Close() must write the part''s uncommitted New() row back to the part''s own table');
        Assert.AreEqual('ClosedByTest', Line.Descr,
            'the value written through the part must reach the table, not just the control buffer');
    end;

    // ── Arm B: the route the platform drives on the handler's behalf ──────────────
    //
    // The same page, the same part, the same New()+SetValue sequence, closed by the platform
    // when the [ModalPageHandler] returns instead of by an explicit Close(). If this arm
    // disagrees with arm A, the two close routes do not answer the same about an uncommitted
    // part buffer, and that difference is the finding.
    [Test]
    [HandlerFunctions('WritePartThenOkHandler')]
    procedure ModalPartFlush_RunModalHandlerOk_PersistsThePartRow()
    var
        Line: Record "TPMF Line";
        Card: Page "TPMF Card";
        Result: Action;
    begin
        Initialize();
        SeedHead();

        Assert.RecordIsEmpty(Line);

        Result := Card.RunModal();

        Assert.AreEqual(Format(Action::OK), Format(Result),
            'the handler invoked OK, so RunModal must report OK — otherwise the arm did not measure a confirming close');
        Assert.IsTrue(Line.Get('H1', 20000),
            'closing a modal through its [ModalPageHandler] must write the part''s uncommitted New() row back, exactly as TestPage.Close() does');
        Assert.AreEqual('ClosedByHandler', Line.Descr,
            'the value written through the part inside the handler must reach the table');
    end;

    // ── Arm C: the two routes side by side, in one test ───────────────────────────
    //
    // Arms A and B can each fail for their own reasons; this one fails only if they DISAGREE.
    // It is the arm that states the claim the suite exists to make — the close route must not
    // be observable in the part's table — and it is stated as a count so that "both persisted"
    // and "neither persisted" are distinguishable from "exactly one did".
    [Test]
    [HandlerFunctions('WritePartThenOkHandler')]
    procedure ModalPartFlush_BothCloseRoutes_AgreeAboutTheUncommittedPartRow()
    var
        Line: Record "TPMF Line";
        CardPage: Page "TPMF Card";
        CardTest: TestPage "TPMF Card";
        ClosedByTestPersisted: Boolean;
        ClosedByHandlerPersisted: Boolean;
    begin
        Initialize();
        SeedHead();

        CardTest.OpenEdit();
        CardTest.Lines.New();
        CardTest.Lines.HeadNo.SetValue('H1');
        CardTest.Lines.LineNo.SetValue(10000);
        CardTest.Lines.Descr.SetValue('ClosedByTest');
        CardTest.Close();
        ClosedByTestPersisted := Line.Get('H1', 10000);

        CardPage.RunModal();
        ClosedByHandlerPersisted := Line.Get('H1', 20000);

        Assert.AreEqual(ClosedByTestPersisted, ClosedByHandlerPersisted,
            'TestPage.Close() and the [ModalPageHandler] close route must agree about whether an uncommitted part row is written back — a difference here is observable to AL and belongs in neither route by accident');
    end;

    // ── Arm D: the negative that keeps the positives honest ───────────────────────
    //
    // Same host, same part, but the handler writes NOTHING. The part's table must stay empty.
    // Without this arm, an implementation that inserted a row on every modal close — or a
    // fixture table that some other test had already seeded — would satisfy arms A, B and C.
    [Test]
    [HandlerFunctions('WriteNothingThenOkHandler')]
    procedure ModalPartFlush_HandlerWritesNothing_LeavesThePartTableEmpty()
    var
        Line: Record "TPMF Line";
        Card: Page "TPMF Card";
    begin
        Initialize();
        SeedHead();

        Card.RunModal();

        Assert.RecordIsEmpty(Line);
    end;

    // ── Arm E: the host record's own fate, read separately ───────────────────────
    //
    // The part buffer and the host record are two different buffers, and a close route could
    // write one back while discarding the other. Reading the host's field through the same
    // modal close is what makes "the part row is missing" a statement about the PART rather
    // than about the close having done nothing at all.
    [Test]
    [HandlerFunctions('WriteHostThenOkHandler')]
    procedure ModalPartFlush_RunModalHandlerOk_PersistsTheHostRow()
    var
        Head: Record "TPMF Head";
        Card: Page "TPMF Card";
    begin
        Initialize();
        SeedHead();

        Card.RunModal();

        Assert.IsTrue(Head.Get('H1'), 'the seeded host row must still exist after the modal closed');
        Assert.AreEqual('ChangedByHandler', Head.Descr,
            'closing a modal through its [ModalPageHandler] must write the HOST record''s edited field back');
    end;

    // ── Arm F: the handler that invokes NOTHING — the arm that reaches the close itself ──
    //
    // Arms B, C and E all end with OK().Invoke(). Invoking a page ACTION is itself a moment
    // at which a client sends the edited row to the server, so those arms can be satisfied by
    // the ACTION write-back without the CLOSE ever writing anything. This arm removes that
    // confound: the handler writes the part row and returns, and the platform closes the page
    // on its behalf. Nothing but the close can persist the row here.
    //
    // This is the arm that answers the question the suite was written for. Its verdict, and
    // arm G's, are what a reader should look at first.
    [Test]
    [HandlerFunctions('WritePartNoInvokeHandler')]
    procedure ModalPartFlush_HandlerWritesPartAndInvokesNothing_PersistsThePartRow()
    var
        Line: Record "TPMF Line";
        Card: Page "TPMF Card";
    begin
        Initialize();
        SeedHead();

        Assert.RecordIsEmpty(Line);

        Card.RunModal();

        Assert.IsTrue(Line.Get('H1', 30000),
            'a modal closed by the platform when its [ModalPageHandler] returned — with no action invoked — must still write the part''s uncommitted New() row back');
        Assert.AreEqual('NoInvokePart', Line.Descr,
            'the value written through the part must reach the table on the platform-driven close');
    end;

    // ── Arm G: the same no-invoke shape driven through TestPage.Close() ───────────
    //
    // The counterpart to arm F, and the pair is the comparison the suite exists to make: the
    // same page, the same part write, no action invoked in either, differing only in whether
    // the test closed the page or the platform did. If F and G disagree, the close route is
    // observable to AL.
    [Test]
    procedure ModalPartFlush_TestPageCloseWithoutInvoke_PersistsThePartRow()
    var
        Line: Record "TPMF Line";
        Card: TestPage "TPMF Card";
    begin
        Initialize();
        SeedHead();

        Assert.RecordIsEmpty(Line);

        Card.OpenEdit();
        Card.Lines.New();
        Card.Lines.HeadNo.SetValue('H1');
        Card.Lines.LineNo.SetValue(30000);
        Card.Lines.Descr.SetValue('NoInvokePart');
        Card.Close();

        Assert.IsTrue(Line.Get('H1', 30000),
            'TestPage.Close() with no action invoked must write the part''s uncommitted New() row back');
        Assert.AreEqual('NoInvokePart', Line.Descr,
            'the value written through the part must reach the table on the test-driven close');
    end;

    // ── Arm H: F and G side by side, so the DIFFERENCE is what is asserted ────────
    //
    // Arms F and G can each fail on their own; this one fails only if they disagree. Stated
    // as an equality between two booleans so that "both persisted" and "neither persisted"
    // both pass and only "exactly one did" fails — the suite is measuring whether the close
    // route is observable, not asserting in advance which way it lands.
    [Test]
    [HandlerFunctions('WritePartNoInvokeHandler')]
    procedure ModalPartFlush_NeitherRouteInvokesAnAction_BothRoutesAgree()
    var
        Line: Record "TPMF Line";
        CardPage: Page "TPMF Card";
        CardTest: TestPage "TPMF Card";
        ClosedByTestPersisted: Boolean;
        ClosedByPlatformPersisted: Boolean;
    begin
        Initialize();
        SeedHead();

        CardTest.OpenEdit();
        CardTest.Lines.New();
        CardTest.Lines.HeadNo.SetValue('H1');
        CardTest.Lines.LineNo.SetValue(40000);
        CardTest.Lines.Descr.SetValue('NoInvokeByTest');
        CardTest.Close();
        ClosedByTestPersisted := Line.Get('H1', 40000);

        CardPage.RunModal();
        ClosedByPlatformPersisted := Line.Get('H1', 30000);

        Assert.AreEqual(ClosedByTestPersisted, ClosedByPlatformPersisted,
            'with no action invoked on either route, TestPage.Close() and the platform-driven modal close must agree about whether an uncommitted part row is written back');
    end;

    [ModalPageHandler]
    procedure WritePartThenOkHandler(var Card: TestPage "TPMF Card")
    begin
        Card.Lines.New();
        Card.Lines.HeadNo.SetValue('H1');
        Card.Lines.LineNo.SetValue(20000);
        Card.Lines.Descr.SetValue('ClosedByHandler');
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WriteNothingThenOkHandler(var Card: TestPage "TPMF Card")
    begin
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WriteHostThenOkHandler(var Card: TestPage "TPMF Card")
    begin
        Card.Descr.SetValue('ChangedByHandler');
        Card.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure WritePartNoInvokeHandler(var Card: TestPage "TPMF Card")
    begin
        Card.Lines.New();
        Card.Lines.HeadNo.SetValue('H1');
        Card.Lines.LineNo.SetValue(30000);
        Card.Lines.Descr.SetValue('NoInvokePart');
    end;
}
