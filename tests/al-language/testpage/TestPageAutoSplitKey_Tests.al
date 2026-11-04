// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpageactiontestpage-invoke-method
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Line (60916), ASK Probe (60917), ASK Lines (60918),
//   ASK Lines No Split (60919), ASK Card (60920), ASK Card No Split (60921); shared Assert (60021)
// BC versions: 27.5+
//
// Two platform behaviours that only show up together, and are easy to mistake for one:
//
//   1. Invoking a page ACTION saves the row the page is on first. A client sends the row it
//      is sitting on to the server before it runs an action, so by the time OnAction executes
//      the row is in the table and any other code can find it.
//   2. AutoSplitKey assigns the LAST field of the primary key on the way in. That is what
//      makes an editable line grid — every document subform in BC — able to take a second
//      line at all: without it every new line would carry the same key.
//
// Why both are needed to pin either. A page that saved on action but never numbered writes
// its first line at "Line No." 0 and cannot write a second one; a page that numbered but
// never saved leaves OnAction reading a buffer that no lookup can see. Both failures surface
// far from their cause — as a duplicate-key error on the SECOND line, or as an action that
// "did nothing" — so the tests below assert the intermediate state directly, from inside
// OnAction, via an independent Record lookup rather than the action's own Rec.
//
// THE FIRST LINE IS 20000, NOT 10000, and that is not a typo. Measured on both BC 27.5 and
// BC 28.3, identically:
//
//   empty grid, three lines            -> 20000, 30000, 40000
//   empty grid, one line               -> 20000
//   grid already holding a line at 50000, one new line -> 60000
//   no AutoSplitKey                    -> 0
//
// So the increment is a flat 10000 and an append is "last + 10000" — but a grid that starts
// EMPTY burns one interval before the first line the test can see. An insertable repeater
// carries a blank placeholder row past its real data, and on an empty grid that placeholder
// is what the first interval goes to; it is never persisted, because nothing edited it. The
// arithmetic is consistent with that on all four cases above. Whatever a runtime's internal
// story, 20000 is the number BC actually assigns, so 20000 is what this pins.
//
// The load-bearing negatives:
//   * a plain SetValue must NOT save the row — nothing has left it yet, and a runtime that
//     saved eagerly would satisfy every positive here while changing when OnInsertRecord and
//     the table's OnInsert fire;
//   * the identical page WITHOUT AutoSplitKey must still be saved by the action but must
//     leave "Line No." at 0 — otherwise "the platform numbers new rows" and "this page asked
//     for numbering" are indistinguishable.

codeunit 60922 "ASK Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        AskProbe: Codeunit "ASK Probe";

    local procedure Initialize()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        AskProbe.Reset();
    end;

    local procedure GivenHeader(HeaderNo: Code[20]) Header: Record "ASK Header"
    begin
        Header.Init();
        Header."No." := HeaderNo;
        Header.Insert();
    end;

    // Positive: the row exists, found by a Record variable that has nothing to do with the
    // page, at the moment OnAction runs. Descr is asserted alongside it so a runtime that
    // wrote SOME row cannot pass — it has to be the row the test was editing.
    [Test]
    procedure TestPage_ActionInvoke_OnANewSubpageRow_SavesTheRowBeforeOnActionRuns()
    var
        Header: Record "ASK Header";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('first');
        Card.Lines.Probe.Invoke();
        Card.Close();

        Assert.IsTrue(AskProbe.GetRan(), 'the action''s OnAction must have run');
        Assert.AreEqual('first', AskProbe.GetDescrSeen(),
            'OnAction must see the value the test set on the current row');
        Assert.IsTrue(AskProbe.GetRowExisted(),
            'the new row must already be in the table when OnAction runs — an independent '
            + 'Record lookup for its key must find it');
    end;

    // Positive: and the key it was saved under is the one AutoSplitKey assigned, already in
    // place before OnAction runs. See the header comment for why an empty grid starts at
    // 20000; asserting the exact number is what stops "some non-zero value" passing.
    [Test]
    procedure TestPage_ActionInvoke_OnANewSubpageRow_AutoSplitKeyHasAssignedTheLineNo()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('first');
        Card.Lines.Probe.Invoke();
        Card.Close();

        Assert.AreEqual(20000, AskProbe.GetLineNoSeen(),
            'AutoSplitKey must have assigned the first line''s "Line No." before OnAction ran');
        Assert.IsTrue(Line.Get('H1', 20000), 'the row must be retrievable at the assigned key');
        Assert.AreEqual('first', Line.Descr, 'and it must be the row the test edited');
    end;

    // Positive: consecutive lines land in consecutive intervals, which is the property that
    // makes the grid usable at all. A runtime that assigned a constant passes the two tests
    // above and fails here on a duplicate key.
    [Test]
    procedure TestPage_New_ThreeConsecutiveLines_AutoSplitKeyNumbersThemInTenThousands()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('one');
        Card.Lines.New();
        Card.Lines.Descr.SetValue('two');
        Card.Lines.New();
        Card.Lines.Descr.SetValue('three');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(3, Line.Count(), 'all three lines must have been saved');

        Assert.IsTrue(Line.Get('H1', 20000), 'the first line must be numbered 20000');
        Assert.AreEqual('one', Line.Descr, 'line 20000 must be the first one entered');
        Assert.IsTrue(Line.Get('H1', 30000), 'the second line must be numbered 30000');
        Assert.AreEqual('two', Line.Descr, 'line 30000 must be the second one entered');
        Assert.IsTrue(Line.Get('H1', 40000), 'the third line must be numbered 40000');
        Assert.AreEqual('three', Line.Descr, 'line 40000 must be the third one entered');
    end;

    // Positive: appending to a grid that already holds a line is "last + 10000", from the
    // line that is actually there — not from a counter, and not from the empty-grid start.
    // The seed is at 50000 precisely so a runtime that numbered from its own sequence
    // (10000, 20000, …) instead of from the data lands somewhere else and fails.
    [Test]
    procedure TestPage_New_OnAGridThatAlreadyHasALine_ContinuesFromTheLastLine()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        Line.Init();
        Line."No." := 'H1';
        Line."Line No." := 50000;
        Line.Descr := 'seeded';
        Line.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('appended');
        Card.Close();

        Line.Reset();
        Line.SetRange("No.", 'H1');
        Assert.AreEqual(2, Line.Count(), 'the seeded line and the appended one');
        Assert.IsTrue(Line.Get('H1', 60000), 'the appended line must be numbered 50000 + 10000');
        Assert.AreEqual('appended', Line.Descr, 'and it must be the line the test entered');
    end;

    // Negative: editing a field does not save the row. Nothing has left it yet, so the row is
    // still only the page's buffer. A runtime that saved on every SetValue would pass every
    // positive above while moving OnInsertRecord and the table's OnInsert to the wrong moment.
    [Test]
    procedure TestPage_New_WithoutLeavingTheRow_DoesNotSaveIt()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('not yet');

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(0, Line.Count(),
            'a row that has only been started and typed into must not be in the table yet');

        Card.Close();

        // And it IS saved once the page closes, so the assertion above is about TIMING and
        // not about the row being lost.
        Assert.AreEqual(1, Line.Count(), 'closing the page must save the row it was editing');
    end;

    // Negative: the SAME flow on a part that does not declare AutoSplitKey. The action still
    // saves the row — that behaviour belongs to the action, not to the property — but nothing
    // numbers it, so "Line No." stays at its Init() default. Without this, a runtime that
    // numbered every new row regardless of the page would pass the whole suite.
    [Test]
    procedure TestPage_ActionInvoke_WithoutAutoSplitKey_SavesTheRowButLeavesTheLineNoAtZero()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card No Split";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('unnumbered');
        Card.Lines.Probe.Invoke();
        Card.Close();

        Assert.IsTrue(AskProbe.GetRan(), 'the action''s OnAction must have run');
        Assert.IsTrue(AskProbe.GetRowExisted(),
            'invoking an action must save the current row whether or not the page auto-numbers it');
        Assert.AreEqual(0, AskProbe.GetLineNoSeen(),
            'a page that does not declare AutoSplitKey must not have its "Line No." assigned');
        Assert.IsTrue(Line.Get('H1', 0), 'the row must have been saved under the unassigned key');
        Assert.AreEqual('unnumbered', Line.Descr, 'and it must be the row the test edited');
    end;
}
