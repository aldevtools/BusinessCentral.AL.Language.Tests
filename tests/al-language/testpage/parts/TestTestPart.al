// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-data-type
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT TestPart Row (60341), ALT TestPart Lines (60342), ALT TestPart Hidden
//   (60343), ALT TestPart Host (60344), ALT TestPart Caption Host (60345); shared Assert (60021)
// BC versions: 27.0+ (TestPart is runtime 1.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: TestPart is the TestPage-shaped handle a test gets when it reaches a `part()`
/// control through an open TestPage. Reading Ncl.dll, it looks like it should NOT be a thin
/// alias for TestPage -- NavTestPart overrides exactly two members, ALEnabled and ALVisible,
/// both reading the part CONTROL's own metadata, while everything else is inherited from the
/// base TestPage uses and reads the part PAGE.
///
/// A real service tier says that distinction is NOT OBSERVABLE FROM AL, and establishing
/// that is the main result of this file. The overrides exist, but every route to a control
/// whose Visible or Enabled would be false goes through a part that BC does not put in the
/// test page's control tree at all -- so AL cannot reach a handle on which either answers
/// false. Editable(), which is inherited rather than overridden, likewise does not follow the
/// host control's Editable property. All three were first written as PAIRS asserting the
/// opposite, and all 8 cloud legs falsified all three identically.
///
/// Nothing in this repository measured TestPart as a surface before this file. Searching the
/// suite for the type name -- with both `rg --hidden` and `command grep -rn`, which have
/// different silent-false-negative modes -- finds only the scraper scripts. Three of its 20
/// documented members (First, New, Next) are used INCIDENTALLY by other suites as a way to
/// reach rows while testing something else; the remaining 17 had no coverage at all, and
/// even those three were never asserted as claims about TestPart. docs/al-language-coverage-
/// gaps.md did not mention the type.
///
/// A note on the scraper: scripts/al-surface-inscope.json marks all 20 members "test-only".
/// That label is accurate here in a way it was NOT for SecretText, SessionSettings,
/// WebServiceActionContext or FilterPageBuilder -- TestPart genuinely only exists inside a
/// test. What it does not mean is "unreachable": a [Test] codeunit is exactly the context
/// this type is for, so the whole surface is measurable, and the label is not a reason to
/// skip it.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. A PART DECLARED Visible = false IS NOT IN THE TEST PAGE'S CONTROL TREE AT ALL.
///      Reaching it is a catchable error -- "The part with ID = <n> was not found on the
///      page." -- not a handle reporting false. Consequence: Visible() can never be observed
///      returning false from AL, and the same is true of Enabled() by the same route. Both
///      are pinned in the only two forms the tier permits: true for a reachable part, and
///      the error for an unreachable one. The error is asserted by SUBSTRING because the
///      message embeds a compiler-generated control id that differs per compilation.
///   2. Editable = false ON THE HOST'S PART CONTROL DOES NOT PROPAGATE TO Editable(). The
///      host hosts the SAME part page twice, once plainly and once with Editable = false, and
///      both report editable. The load-bearing assertion is the AreEqual stating the two
///      AGREE despite differing in the host property -- which is what an implementation
///      honoring that property would fail.
///   3. Caption() READS THE PART PAGE, NOT THE HOSTING CONTROL. Two hosts host one part page:
///      the default host's control carries no caption, the caption host's control overrides
///      it with a different string. Caption() answers the PART PAGE's caption from both. The
///      three strings involved -- host page caption, part page caption, control caption --
///      are deliberately all different, so the assertion cannot pass by two of them
///      coinciding. Ncl.dll settles the direction in advance (ALCaption is
///      `return TestPage.Caption`), and the pairing is what MEASURES it.
///   4. First()/Next()/Last()/Previous() WALK THE PART'S OWN ROWSET IN KEY ORDER. Asserted
///      over three seeded rows by reading a distinctive value at each stop, so an
///      implementation answering the first row for every position fails, and one answering
///      "there are rows" unconditionally fails the empty-part arm.
///   5. THE TWO ENDS ARE NOT SYMMETRIC, BECAUSE AN EDITABLE REPEATER CARRIES A TRAILING BLANK
///      NEW-ROW LINE. Previous() before the first row answers false and does not move. But
///      Next() past the last DATA row answers TRUE, stepping onto that blank line; only the
///      step after it answers false. So an editable part's rowset is one row longer than its
///      table. Read together with the empty-part arm -- where First() does NOT land on that
///      same blank line -- the trailing row is reachable by walking forward but is not a row
///      First() will find.
///   6. GoToKey() TAKES THE PRIMARY KEY FIELDS IN ORDER AND ITS ARITY IS CHECKED. The fixture
///      table's key is deliberately COMPOSITE (Grp + "Line No."), which is what makes the
///      negative case expressible at all: GoToKey with one value where two are required is a
///      catchable error, and the same call with the right arity lands on the row. Every other
///      part fixture in this repository keys on a single field, where a one-value GoToKey is
///      correct and the arity check is invisible.
///   7. GoToKey() RETURNS false FOR A KEY THAT DOES NOT EXIST WHEN THE RETURN VALUE IS
///      CAPTURED, AND ERRORS WHEN IT IS DISCARDED. The trappable-return convention, asserted
///      in both directions -- an implementation that always errors passes the discarded half,
///      one that never errors passes the captured half.
///   8. GoToRecord() POSITIONS FROM A Record RATHER THAN FROM KEY VALUES, AND AGREES WITH
///      GoToKey() ON THE SAME ROW. Asserted by landing on a row that is neither first nor
///      last, so an implementation ignoring its argument fails.
///   9. GetField(Id) TAKES A PAGE CONTROL ID, NOT A TABLE FIELD NUMBER. Passing a table field
///      number is refused with "The field with ID = <n> is not found on the page." Ncl.dll
///      shows this is by design and not a lookup that merely missed: GetField is
///      `fields.TryGetValue(id, ...)` over the page's own control dictionary, falling back to
///      the client control tree; table field numbers are keys in neither. Control ids are
///      compiler-generated per compilation, so no literal id is assertable here -- the test
///      pins the refusal, and asserts alongside it that the number passed IS a real table
///      field number, so it cannot pass merely because the number was meaningless.
///  10. FindFirstField()/FindNextField()/FindPreviousField() SEARCH THE ROWSET BY A CONTROL
///      VALUE. Two rows deliberately SHARE a Descr value while differing in key, so
///      FindFirstField lands on the earlier and FindNextField advances to the later; a third
///      row with a unique value is the negative case. An implementation that ignored the
///      value argument and simply moved would fail the row-identity assertions.
///  11. ValidationErrorCount() AND GetValidationError() REPORT ERRORS RAISED BY THE PART'S
///      OWN FIELD VALIDATION. The fixture table's Grade field refuses any value starting with
///      'BAD' with a Label the test asserts by substring, so the error counted is a REAL
///      validation error from the part's AL, not a platform type-conversion message whose
///      text is a localization detail. The clean-part arm asserts the count is 0, which is
///      what rules out an implementation that always reports one.
///  12. GetValidationError() IS 1-BASED AND RANGE-CHECKED. Index 1 is the first error and
///      index 0 errors. Ncl.dll shows why this is worth pinning rather than assuming:
///      ALGetValidationError(index) is literally
///      `TestPage.GetValidationError(checked(index - 1))` wrapped in a translation of
///      ArgumentOutOfRangeException, so the 1-based-ness is a deliberate offset applied at
///      the AL boundary and a 0-based implementation would be a silent off-by-one.
///
/// COMPILE-TIME REFUSALS, measured with the real alc against this app's Cloud target. These
/// are negative cases that CANNOT be written as [Test] procedures, because the compiler
/// rejects them before a service tier ever sees them. They are recorded here rather than
/// deleted, following the precedent of network/TestHttpClientBlockNoHandler.al:
///
///   Host.PartA = Host.PartB                     error AL0175: "Operator '=' cannot be applied
///                                               to operands of type 'Lines' and
///                                               'ReadOnlyLines'". Note WHAT that message
///                                               names: not "TestPart" but the two CONTROL
///                                               names. Each part control on a host is its
///                                               own generated type, which is the compiler's
///                                               view of the same fact the tests below rest
///                                               on -- a part handle is inseparable from the
///                                               control it was reached through.
///   TestPart.Prev()                             error AL0666 -- 'Prev' is not available in
///                                               runtime version '16.0'; the supported range
///                                               is '3.0' until, but not including, '13.0'.
///                                               THIS IS A DOCUMENTED MEMBER THAT NO LONGER
///                                               EXISTS. scripts/al-surface.json lists Prev
///                                               and Previous side by side as two of the
///                                               twenty members, and Microsoft Learn still
///                                               publishes testpart-prev-method, but this
///                                               app targets runtime 16.0 and the compiler
///                                               refuses the call outright. So one of the
///                                               twenty members is unreachable, and the
///                                               obvious claim about the pair -- that Prev
///                                               and Previous are two spellings of one
///                                               operation -- is not expressible here. Every
///                                               backward walk below uses Previous().
///   TestPart.GetField(Id)                       compiles, with warning AL0667: deprecated
///                                               in runtime '3.0' or greater. Still callable,
///                                               so it is covered; recorded because the
///                                               warning will become an error in a future
///                                               release and this file will then need the
///                                               same treatment Prev just got.
///   var P: TestPart                             error AL0134: "'TestPart' is not recognized
///                                               as a valid type." TestPart is NOT a declarable
///                                               variable type. Unlike TestPage, which is
///                                               declared as `TestPage "Some Page"`, a
///                                               TestPart handle exists ONLY as the member
///                                               access `Host.PartName`. Consequence for
///                                               every test below: the part cannot be held in
///                                               a local, so each assertion re-reaches it
///                                               through the host, and there is no test of
///                                               "assignment semantics" to write -- the
///                                               question FilterPageBuilder and
///                                               WebServiceActionContext both answered does
///                                               not arise for this type.
///
/// What DOES compile, probed rather than assumed: Format(Host.Lines), assignment of a part
/// handle into a Variant, and Expand()/IsExpanded() on a plain ListPart.
///
/// DELIBERATELY NOT COVERED: Expand() and IsExpanded(). Four revisions were spent finding out
/// why, each decided by a real service tier, and the reason is a fact about AL rather than a
/// gap in this file:
///
///   rev 1 asserted IsExpanded() tracks the last Expand() call. All 8 legs raised
///         System.InvalidOperationException, "Expanding and collapsing are not supported on
///         this rowEntry", from BindingManager.CollapseRow.
///   rev 2 read that as "a flat ListPart cannot expand" and asserted the refusal -- while
///         also adding a First() the previous revision did not have. All 8 legs then reported
///         "An error was expected inside an ASSERTERROR statement", so with the cursor on a
///         data row Expand(TRUE) succeeds; the rev-1 refusal had come from the Expand(FALSE)
///         call after it.
///   rev 3 asserted exactly that -- expand accepted, collapse refused -- and all 8 legs failed
///         again, with the SAME InvalidOperationException, now reported from INSIDE the
///         asserterror body (NavMethodScope.AssertErrorAsync in the callstack).
///
/// That third failure is the answer. `asserterror` traps AL errors; it does NOT trap a raw
/// CLR exception surfacing from the client proxy, and this one crosses the boundary
/// unconverted. So the refusal is real and reproducible on every version, and there is no AL
/// construct that can observe it: an assertion that it happens cannot be written, and one
/// that it does not happen would be false. Expand() is therefore reachable from AL only in
/// the direction that succeeds, which alone asserts nothing about the method.
///
/// IsExpanded() falls with it -- with collapsing unobservable, the only state it could be
/// read in is the expanded one. Both are named here rather than silently dropped, and a
/// tree-view fixture would not fix this: the obstacle is the exception boundary, not the
/// control shape. Nothing else on the type is withheld.
/// </summary>
codeunit 60346 "Test TestPart"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "ALT TestPart Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(Grp: Code[10]; LineNo: Integer; Descr: Text[50])
    var
        Row: Record "ALT TestPart Row";
    begin
        Row.Init();
        Row.Grp := Grp;
        Row."Line No." := LineNo;
        Row.Descr := Descr;
        Row.Insert();
    end;

    // Three rows in key order. Row 2 shares its Descr with row 3, which is what the
    // FindFirstField/FindNextField pair needs; row 1's Descr is unique, which is what the
    // not-found arm needs.
    local procedure SeedThreeRows()
    begin
        SeedRow('A', 10, 'Alpha');
        SeedRow('A', 20, 'Shared');
        SeedRow('A', 30, 'Shared');
    end;

    // ── Visible / Enabled / Editable: the three members TestPart overrides ──────────

    [Test]
    procedure TestPart_Visible_AnswersTrueForAReachablePart()
    // CLAIM, and it is a NARROWER claim than the one this test was first written to make:
    // Visible() answers true for a part that is reachable at all.
    //
    // The first revision asserted the pair -- a Visible = true part answering true and a
    // Visible = false part answering false on the same open host -- and all 8 cloud legs
    // falsified it identically, with "The part with ID = 1318487454 was not found on the
    // page." That is the finding, and it is a sharper fact than the assertion it replaced:
    // a part declared Visible = false is NOT RENDERED INTO THE TEST PAGE'S CONTROL TREE AT
    // ALL, so `Host.Hidden` does not resolve and there is no handle on which to call
    // Visible(). Visible() can therefore never be observed returning false from AL.
    //
    // The corollary is what the negative arm below pins instead: reaching an invisible part
    // is a catchable error naming it, not a handle that reports false.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Visible(),
            'a part that is reachable at all must report visible');
        Host.Close();
    end;

    [Test]
    procedure TestPart_InvisiblePart_IsNotInTheControlTreeAtAll()
    // CLAIM: a part declared Visible = false on the host is absent from the test page's
    // control tree, so REACHING it errors rather than yielding a handle that reports false.
    // This is the negative arm that the Visible() pair was originally meant to be, relocated
    // to where BC actually put the observable.
    //
    // The error text is asserted by substring on 'was not found on the page', not in full,
    // because the message embeds a generated numeric control id that differs per compilation.
    var
        Host: TestPage "ALT TestPart Host";
        Reached: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        asserterror Reached := Host.Hidden.Visible();

        Assert.IsTrue(StrPos(GetLastErrorText(), 'was not found on the page') > 0,
            'reaching a part declared Visible = false must error that the part is not on the page');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Enabled_AnswersTrueForAReachablePart()
    // CLAIM: the same narrowing applies to Enabled(). The fixture's disabled part is also
    // declared Visible = false, so it is unreachable for the reason above and the pair
    // cannot be formed through it either.
    //
    // Ncl.dll is worth stating here because it makes the limitation precise rather than
    // vague: NavTestPart DOES override ALEnabled as `return testPart.Enabled;`, reading the
    // part control's own metadata. The override exists and is real; what the tier
    // establishes is that AL cannot reach a control whose Enabled would be false, because
    // the routes to one go through a part that is not in the tree.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Enabled(),
            'a part that is reachable at all must report enabled');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Editable_IsNotDrivenByTheHostControlsEditableProperty()
    // CLAIM, and this one INVERTS what the test first asserted: Editable = false on the
    // HOST'S PART CONTROL does NOT make the part report non-editable.
    //
    // The first revision asserted the opposite -- that the same part page hosted with
    // Editable = false would answer false -- and all 8 cloud legs falsified it identically.
    // So the property does not propagate to what TestPart.Editable() reports; the two
    // controls over the same part page agree, and the surprising direction is the true one.
    //
    // Both halves are asserted together, and the AreEqual is the load-bearing one: it states
    // the two controls agree DESPITE differing in the host property, which is exactly the
    // claim an implementation honoring the host property would fail.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.Editable(),
            'a part hosted without an Editable property must report editable');
        Assert.IsTrue(Host.ReadOnlyLines.Editable(),
            'Editable = false on the HOST''s part control does not make the part report non-editable');
        Assert.AreEqual(Host.Lines.Editable(), Host.ReadOnlyLines.Editable(),
            'two controls over the same part page must agree, despite differing in the host''s Editable property');
        Host.Close();
    end;

    // ── Caption: inherited, and reads the part page ─────────────────────────────────

    [Test]
    procedure TestPart_Caption_ReadsThePartPageNotTheHost()
    // CLAIM: Caption() returns the PART PAGE's caption, not the host page's. All three
    // captions in play are spelled differently, so neither assertion can pass by coincidence.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.AreEqual('Part Lines Caption', Host.Lines.Caption(),
            'Caption() must return the part page''s own caption');
        Assert.AreNotEqual('Host Page Caption', Host.Lines.Caption(),
            'Caption() must not return the hosting page''s caption');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Caption_ReadsThePartPageNotTheControlOverride()
    // CLAIM: when the hosting CONTROL overrides the caption, Caption() still answers the part
    // page's own caption. This is the half the default host cannot decide -- there the control
    // has no caption and both readings agree. Ncl.dll predicts it (ALCaption returns
    // TestPage.Caption); this test is the measurement.
    var
        CaptionHost: TestPage "ALT TestPart Caption Host";
    begin
        Initialize();
        SeedThreeRows();

        CaptionHost.OpenEdit();

        Assert.AreEqual('Part Lines Caption', CaptionHost.Lines.Caption(),
            'Caption() must answer the part page''s caption even when the control overrides it');
        Assert.AreNotEqual('Control Level Caption', CaptionHost.Lines.Caption(),
            'Caption() must not answer the hosting control''s caption override');
        CaptionHost.Close();
    end;

    // ── Navigation: First / Next / Last / Prev / Previous ───────────────────────────

    [Test]
    procedure TestPart_First_LandsOnTheFirstRowInKeyOrder()
    // CLAIM: First() moves to the first row of the part's own rowset in key order and
    // answers true. The Descr asserted is unique to that row, so an implementation landing
    // anywhere else fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.First(), 'First() must answer true when the part has rows');
        Assert.AreEqual('Alpha', Host.Lines.Descr.Value(),
            'First() must land on the lowest-keyed row');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(),
            'First() must land on line 10, the lowest key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_First_AnswersFalseOnAnEmptyPart()
    // CLAIM: the negative of the above. With the part's table empty, First() answers false
    // rather than landing on the trailing blank new-row line an editable repeater carries.
    // This is the arm that refuses a "there are always rows" implementation.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();

        Host.OpenEdit();

        Assert.IsFalse(Host.Lines.First(),
            'First() must answer false when the part''s source table is empty');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Next_WalksForwardOneRowAtATime()
    // CLAIM: Next() advances exactly one row per call, in key order. Reading a distinctive
    // value at each stop is what separates this from an implementation that answers the first
    // row for every position.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.AreEqual('10', Host.Lines.LineNo.Value(), 'the walk must start on line 10');
        Assert.IsTrue(Host.Lines.Next(), 'Next() must answer true while rows remain');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(), 'one Next() must reach line 20');
        Assert.IsTrue(Host.Lines.Next(), 'Next() must answer true reaching the last row');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(), 'two Next() calls must reach line 30');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Last_LandsOnTheHighestKeyedRow()
    // CLAIM: Last() jumps to the final row regardless of the current position. Called from
    // the first row, so an implementation that no-ops fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.Last(), 'Last() must answer true when the part has rows');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'Last() must land on the highest-keyed row');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Previous_WalksBackwardOneRowAtATime()
    // CLAIM: Previous() is the mirror of Next(). Walked from the last row so the starting
    // position is not the answer.
    //
    // This test is spelled Previous() and not Prev() because Prev() DOES NOT COMPILE on this
    // app's runtime -- see the header: alc rejects it with AL0666, "not available in runtime
    // version 16.0, supported 3.0 until 13.0". The documented surface still lists both, so
    // one of the twenty members is unreachable and the claim that they are two spellings of
    // one operation is no longer expressible here.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.AreEqual('30', Host.Lines.LineNo.Value(), 'the backward walk must start on line 30');
        Assert.IsTrue(Host.Lines.Previous(), 'Previous() must answer true while earlier rows remain');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(), 'one Previous() must reach line 20');
        Assert.IsTrue(Host.Lines.Previous(), 'Previous() must answer true reaching the first row');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(), 'two Previous() calls must reach line 10');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Next_StepsOntoTheTrailingNewRowLineAtTheEnd()
    // CLAIM, and it INVERTS what this test first asserted: Next() past the last DATA row of
    // an editable repeater answers TRUE, stepping onto the trailing blank new-row line -- it
    // is only the row after THAT which answers false.
    //
    // The first revision asserted false at the end and all 8 cloud legs falsified it. The
    // corrected shape is worth more than the original: it pins that an editable part's
    // rowset is one row LONGER than its table, that the extra row is blank, and that the end
    // is still an end. Compare TestPart_First_AnswersFalseOnAnEmptyPart, which pins that
    // First() does NOT land on that same blank line -- together the two say the trailing row
    // is reachable by walking forward but is not a row First() will find.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'Last() must land on the last DATA row');
        Assert.IsTrue(Host.Lines.Next(),
            'Next() past the last data row must answer true, stepping onto the trailing new-row line');
        Assert.AreEqual('', Host.Lines.Descr.Value(),
            'the trailing new-row line must be blank, not a repeat of the last data row');
        Assert.IsFalse(Host.Lines.Next(),
            'Next() past the trailing new-row line must answer false -- the end is still an end');
        Host.Close();
    end;

    [Test]
    procedure TestPart_Previous_AnswersFalseAtTheStartAndDoesNotMove()
    // CLAIM: the mirror of the above at the other end.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsFalse(Host.Lines.Previous(), 'Previous() before the first row must answer false');
        Assert.AreEqual('10', Host.Lines.LineNo.Value(),
            'a failed Previous() must leave the cursor on the first row, not wrap to the last');
        Host.Close();
    end;

    // ── GoToKey: arity-checked, and the trappable-return convention ─────────────────

    [Test]
    procedure TestPart_GoToKey_PositionsOnTheKeyedRow()
    // CLAIM: GoToKey() takes the primary key fields IN ORDER and lands on that row. The
    // target is the MIDDLE row, so neither "did not move" nor "went to an end" passes.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.GoToKey('A', 20),
            'GoToKey() with both key fields must find the seeded row');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'GoToKey() must land on the row it was given');
        Assert.AreEqual('Shared', Host.Lines.Descr.Value(),
            'the landed row must carry that row''s own data');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ReturnsFalseForAKeyThatDoesNotExist()
    // CLAIM: with the return value CAPTURED, a missing key answers false rather than
    // erroring. Half of the trappable-return convention.
    var
        Host: TestPage "ALT TestPart Host";
        Found: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Found := Host.Lines.GoToKey('A', 999);

        Assert.IsFalse(Found, 'GoToKey() with a captured return must answer false for a missing key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ErrorsForAMissingKeyWhenTheReturnIsDiscarded()
    // CLAIM: the other half. The SAME call with the return value DISCARDED raises a catchable
    // error. Asserting both directions is what rules out an implementation that always errors
    // (which would pass this test and fail the one above) or never errors (vice versa).
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.GoToKey('A', 999);

        Assert.IsTrue(GetLastErrorText() <> '',
            'GoToKey() with a discarded return must raise a catchable error for a missing key');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GoToKey_ErrorsWhenTheKeyFieldCountIsWrong()
    // CLAIM: GoToKey() checks the number of values against the number of primary key fields
    // and errors when they disagree. The fixture's key is COMPOSITE precisely so this case
    // exists -- with a single-field key, GoToKey('A') would be correct and this check would
    // be unobservable. Ncl.dll raises NavTestInvalidNumberOfKeyFieldValuesException here,
    // before any row lookup happens, which is why the row does not need to exist.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.GoToKey('A');

        Assert.IsTrue(GetLastErrorText() <> '',
            'GoToKey() with fewer values than key fields must raise a catchable error');
        Host.Close();
    end;

    // ── GoToRecord ─────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPart_GoToRecord_PositionsFromARecordVariable()
    // CLAIM: GoToRecord() positions the part from a Record rather than from key values, and
    // agrees with GoToKey() on the same row. The target is again the middle row, so an
    // implementation ignoring its argument fails.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Initialize();
        SeedThreeRows();
        Row.Get('A', 20);

        Host.OpenEdit();
        Host.Lines.First();

        Assert.IsTrue(Host.Lines.GoToRecord(Row),
            'GoToRecord() must find the row the Record variable identifies');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'GoToRecord() must land on the row it was given');
        Host.Close();
    end;

    // ── GetField ───────────────────────────────────────────────────────────────────

    [Test]
    procedure TestPart_GetField_TakesAControlIdNotATableFieldNo()
    // CLAIM, and it corrects a wrong reading of the method's own documentation: GetField(Id)
    // resolves a control by the PAGE CONTROL's generated id, NOT by the underlying table's
    // field number.
    //
    // The first revision passed Row.FieldNo(Descr) -- table field 3 -- and all 8 cloud legs
    // answered "The field with ID = 3 is not found on the page." Ncl.dll shows why, and
    // shows it is by design rather than a lookup that merely failed: NavTestPageBase.GetField
    // is `fields.TryGetValue(id, ...)` over the page's own control dictionary, falling back
    // to testPage.GetField(id) against the client control tree. Table field numbers are not
    // keys in either.
    //
    // Control ids are compiler-generated per compilation, so no literal id can be asserted
    // here. What IS assertable, and is the whole content of the contract this test can reach,
    // is the negative: a table field number is refused, with an error naming the id. That is
    // asserted alongside the fact that the SAME number IS a valid table field number, so the
    // test cannot pass merely because the number was meaningless.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
        Fetched: Text;
    begin
        Initialize();
        SeedThreeRows();

        // The number GetField() is about to refuse IS a real table field number. Asserting
        // that first is what stops this test passing merely because the number was
        // meaningless -- the refusal below is about the ID SPACE, not about a bad id.
        // Spelled FieldNo(Descr) rather than the literal 3: AL0166 refuses a constant
        // argument to FieldName/FieldNo, so the field must be named.
        Assert.AreEqual(3, Row.FieldNo(Descr),
            'Descr must really be table field 3, so the refusal below is about the ID SPACE');

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Fetched := Host.Lines.GetField(Row.FieldNo(Descr)).Value();

        Assert.IsTrue(StrPos(GetLastErrorText(), 'is not found on the page') > 0,
            'GetField() must refuse a TABLE field number: its argument is a page control id');
        Host.Close();
    end;

    // ── FindFirstField / FindNextField / FindPreviousField ──────────────────────────

    [Test]
    procedure TestPart_FindFirstField_LandsOnTheEarliestMatchingRow()
    // CLAIM: FindFirstField() searches the rowset for a control VALUE and lands on the
    // earliest match. Two rows share 'Shared', so landing on line 20 rather than 30 is the
    // claim; an implementation returning the last match, or ignoring the value, fails.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Assert.IsTrue(Host.Lines.FindFirstField(Host.Lines.Descr, 'Shared'),
            'FindFirstField() must find a row carrying the value');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'FindFirstField() must land on the EARLIEST row carrying the value, not the last');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindNextField_AdvancesToTheNextMatchingRow()
    // CLAIM: FindNextField() continues the search from the current position, so the second
    // row sharing the value is reached. This is the test the duplicate Descr exists for.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.FindFirstField(Host.Lines.Descr, 'Shared');

        Assert.IsTrue(Host.Lines.FindNextField(Host.Lines.Descr, 'Shared'),
            'FindNextField() must find the second row carrying the value');
        Assert.AreEqual('30', Host.Lines.LineNo.Value(),
            'FindNextField() must advance past the row FindFirstField landed on');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindPreviousField_MovesBackToTheEarlierMatchingRow()
    // CLAIM: FindPreviousField() is the backward form. Driven from the later duplicate back
    // to the earlier one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.Last();

        Assert.IsTrue(Host.Lines.FindPreviousField(Host.Lines.Descr, 'Shared'),
            'FindPreviousField() must find an earlier row carrying the value');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'FindPreviousField() must land on the earlier of the two matching rows');
        Host.Close();
    end;

    [Test]
    procedure TestPart_FindFirstField_AnswersFalseForAValueNoRowCarries()
    // CLAIM: the negative case. A value present on no row answers false rather than landing
    // somewhere arbitrary. Without this, an implementation that ignored the value argument
    // and simply called First() would pass every test above.
    var
        Host: TestPage "ALT TestPart Host";
        Found: Boolean;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();

        Found := Host.Lines.FindFirstField(Host.Lines.Descr, 'NoSuchDescription');

        Assert.IsFalse(Found,
            'FindFirstField() must answer false for a value no row carries');
        Host.Close();
    end;

    // ── ValidationErrorCount / GetValidationError ──────────────────────────────────

    [Test]
    procedure TestPart_ValidationErrorCount_IsZeroOnACleanPart()
    // CLAIM: a part with no failed input reports zero validation errors. The arm that rules
    // out an implementation always reporting one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        Assert.AreEqual(0, Host.Lines.ValidationErrorCount(),
            'a part with no failed input must report zero validation errors');
        Host.Close();
    end;

    [Test]
    procedure TestPart_ValidationErrorCount_CountsARefusedFieldValidation()
    // CLAIM: a value the part's OWN field validation refuses is counted. The fixture table's
    // Grade trigger raises a Label for anything starting with 'BAD', so what is counted here
    // is a real AL validation error, not a platform type-conversion message.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        Assert.IsTrue(Host.Lines.ValidationErrorCount() > 0,
            'a refused field validation must be counted on the part');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GetValidationError_IsOneBasedAndCarriesTheMessage()
    // CLAIM: GetValidationError(1) is the FIRST error, and the text is the message the part's
    // own AL raised -- asserted by substring on the fixture's Label, so it cannot pass on an
    // arbitrary non-empty string. Ncl.dll shows the 1-based-ness is a deliberate offset
    // applied at the AL boundary (`GetValidationError(checked(index - 1))`), which is exactly
    // the kind of thing that would otherwise be a silent off-by-one.
    var
        Host: TestPage "ALT TestPart Host";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        Assert.IsTrue(StrPos(Host.Lines.GetValidationError(1), 'refuses the grade') > 0,
            'GetValidationError(1) must carry the message the part''s own validation raised');
        Host.Close();
    end;

    [Test]
    procedure TestPart_GetValidationError_ErrorsOnIndexZero()
    // CLAIM: the range check. Index 0 is below the 1-based range and raises a catchable
    // error rather than answering the first error or the empty string. This is the assertion
    // a 0-based implementation fails.
    var
        Host: TestPage "ALT TestPart Host";
        ErrText: Text;
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.First();

        asserterror Host.Lines.Grade.SetValue('BADGRADE');

        asserterror ErrText := Host.Lines.GetValidationError(0);

        Assert.IsTrue(GetLastErrorText() <> '',
            'GetValidationError(0) must raise a catchable error, because the index is 1-based');
        Host.Close();
    end;

    // ── New: the row-adding member ─────────────────────────────────────────────────

    [Test]
    procedure TestPart_New_AddsARowThePartCanThenWrite()
    // CLAIM: New() moves the part to a fresh row that accepts writes, and the write reaches
    // the part's own source table. Asserted durably through the table rather than through the
    // control, so a control tree that merely accepted the value without persisting fails.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Initialize();
        SeedThreeRows();

        Host.OpenEdit();
        Host.Lines.New();
        Host.Lines.Grp.SetValue('B');
        Host.Lines.LineNo.SetValue(40);
        Host.Lines.Descr.SetValue('AddedThroughPart');
        Host.Close();

        Assert.IsTrue(Row.Get('B', 40),
            'New() plus SetValue on the part must insert a row into the part''s own table');
        Assert.AreEqual('AddedThroughPart', Row.Descr,
            'the value written through the part must reach the table');
    end;
}
