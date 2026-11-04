// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope (Cloud-compatible) -- every member is driven from a [Test] with no client
// Fixtures used: ALT TestFilter Row (60347), ALT TestFilter List (60348); ALT TestPart Row
//   (60341), ALT TestPart Lines (60342), ALT TestPart Host (60344) for the part arm;
//   shared Assert (60021)
// BC versions: 27.0+ (TestFilter is runtime 1.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: TestFilter is the handle a test gets from `SomeTestPage.Filter`. It carries five
/// documented members -- Ascending, CurrentKey, GetFilter, SetCurrentKey, SetFilter -- and
/// it is the only route by which an AL test can change WHICH ROWS an open page has and in
/// WHAT ORDER it walks them.
///
/// Nothing in this repository measured it as a surface. Four of the five members --
/// Ascending(), CurrentKey(), GetFilter(), SetCurrentKey() -- have ZERO occurrences anywhere
/// in the suite. The fifth, SetFilter(), has nine, and every one of them is INCIDENTAL: it
/// is used to arrange a rowset while some other claim is tested (page cursor position,
/// new-row defaults, SourceTableView interaction), never asserted as a claim about
/// TestFilter itself. Not one of the nine reads a filter back.
///
/// THE CENTRAL FINDING, established with the real alc and not by reading documentation:
/// TESTFILTER'S FIELD ARGUMENT RESOLVES AGAINST THE SOURCE TABLE, NOT AGAINST THE PAGE'S
/// CONTROLS. This is the exact opposite of TestPart/TestPage.GetField(Id), whose argument is
/// a page CONTROL id and which refuses a table field number (see testpart/TestTestPart.al,
/// claim 9). The fixture page names its control over "Entry No." as EntryNo, so the two
/// namespaces are distinguishable, and the compiler picks the table one:
///
///     L.Filter.GetFilter(EntryNo)        error AL0118: 'EntryNo' does not exist
///     L.Filter.GetFilter("Entry No.")    compiles
///
/// The sharp end of the same fact is the fixture's OffPage field, which has NO CONTROL ON
/// THE PAGE AT ALL and is still accepted as a filter target. Ncl.dll agrees and explains
/// why: NavTestFilter.ALGetFilter/ALSetFilter take a plain `int fieldNo`, and NavTestFilter
/// even carries `GetFieldName(int) => fieldNo.ToString()`, i.e. the runtime type never had a
/// control name to work with. The AL compiler is what binds a field name to that number, and
/// it binds it in the table's namespace.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. SetFilter/GetFilter ROUND-TRIP A FILTER, AND GetFilter ANSWERS EMPTY FOR A FIELD
///      NOBODY FILTERED. Asserted as a pair on ONE open page, so an implementation returning
///      the same string for every field fails the second half, and one returning empty
///      always fails the first. The round-tripped value is a RANGE expression ('10..20'),
///      not a single token, so an implementation storing only an equality value fails.
///   2. THE FILTER ACTUALLY RESTRICTS THE ROWSET, not merely what GetFilter reports. The
///      test walks the page and asserts BOTH which rows are present AND that the excluded
///      one is absent -- an implementation that recorded the filter string without applying
///      it passes claim 1 and fails this one.
///   3. A FIELD WITH NO CONTROL ON THE PAGE IS STILL FILTERABLE. OffPage carries no control;
///      filtering it changes which rows the page has. This is the runtime half of the
///      compile-time finding above, and it is the one thing in this file a service tier
///      could plausibly have decided either way.
///   4. SetFilter REPLACES, IT DOES NOT ACCUMULATE. Two SetFilter calls on the SAME field
///      leave only the second in force. Asserted through the rowset and not only through
///      GetFilter, and the two filters are chosen so that an implementation ANDing them
///      together yields an EMPTY page while the correct answer yields one specific row --
///      so the wrong behavior cannot look like the right one.
///   5. FILTERS ON DIFFERENT FIELDS COMBINE. The complement of claim 4: two SetFilter calls
///      on DIFFERENT fields both stay in force and intersect. Claims 4 and 5 together are
///      what make either of them meaningful -- an implementation that always replaced would
///      fail 5, one that always accumulated would fail 4.
///   6. CurrentKey() ANSWERS THE PAGE'S CURRENT KEY, AND SetCurrentKey() CHANGES IT. The
///      fixture table has three keys whose orders DISAGREE on the seeded rows, so the answer
///      is asserted BOTH as the string CurrentKey() returns AND as the order the page walks.
///      Asserting only the string would pass for an implementation that stored it and never
///      applied it; asserting only the order would pass for one that reordered without
///      reporting. The string is asserted by SUBSTRING on the field name, because the exact
///      rendering of a key is a platform detail this file does not intend to pin.
///   7. SetCurrentKey ACCEPTS A COMPOSITE KEY. Grp+Rank is a real key on the table, and
///      setting it produces the order that key implies -- different from both the primary
///      key's order and the single-field Rank key's order.
///   8. Ascending(false) REVERSES THE WALK, AND Ascending() REPORTS IT. Pinned in both
///      directions on one open page: the default is true, setting false reverses the rowset
///      AND is reported back, and setting true again restores both. An implementation whose
///      Ascending() getter was hardcoded true fails the middle step; one that reported the
///      flag without applying it fails the order assertions.
///   9. A PART HAS ITS OWN Filter, INDEPENDENT OF ITS HOST'S. TestPart exposes Filter, and
///      filtering the part does not filter the host -- asserted by leaving the host's own
///      rowset observable. This is the member of the pairing docs/al-language-coverage-
///      gaps.md predicted when it recommended TestFilter as the follow-on to TestPart.
///
/// COMPILE-TIME REFUSALS, measured with the real alc against this app's Cloud target
/// (runtime 16.0). These are negative cases that CANNOT be written as [Test] procedures,
/// because the compiler rejects them before a service tier ever sees them. They are recorded
/// here rather than deleted, following the precedent of testpart/TestTestPart.al and
/// network/TestHttpClientBlockNoHandler.al:
///
///   var F: TestFilter                    error AL0134: 'TestFilter' is not recognized as a
///                                        valid type. Like TestPart, a filter handle exists
///                                        ONLY as the member access `Page.Filter`. So there
///                                        is no assignment-semantics question to ask about
///                                        it -- the split-copy finding that FilterPageBuilder
///                                        needed, and the shared-reference finding
///                                        WebServiceActionContext needed, are both
///                                        inexpressible here.
///   L.Filter.GetFilter(EntryNo)          error AL0118: the name does not exist. EntryNo is
///                                        the page CONTROL name. This is the compile-time
///                                        half of the central finding above.
///   L.Filter.GetFilter(NoSuchField)      error AL0118, identically -- so the AL0118 above
///                                        is genuinely "not a table field", not a special
///                                        rejection of control names.
///   B := L.Filter.SetFilter(Grp, 'A')    error AL0122: cannot convert 'None' to 'Boolean'.
///                                        SetFilter has NO return value, so unlike
///                                        FilterPageBuilder.SetView and TestPart.GoToKey
///                                        there is no trappable-return convention to test on
///                                        it. Ncl.dll agrees: ALSetFilter returns void.
///   L.Filter.CurrentKey()                error AL0192: the return value must be used. So
///                                        CurrentKey cannot be called for effect, and its
///                                        two tests below assign into a variable.
///   L.Filter.SetCurrentKey()             error AL0135: no argument for the required formal
///                                        parameter 'Field1'. At least one field is
///                                        mandatory.
///
/// A NOTE ON SetCurrentKey'S ARITY, because the compiler's own error message is misleading.
/// The AL0135 text renders the signature as `SetCurrentKey(TestFilterField,
/// [TestFilterField])`, which reads as "at most two fields". It is not: passing THREE fields
/// compiles. The message renders only the first optional parameter of a variadic list, and
/// Ncl.dll confirms the runtime shape is `ALSetCurrentKey(params int[] fields)`. This file
/// asserts one- and two-field forms because those are the keys the fixture table declares;
/// the three-field form is noted as compiling and not asserted, since there is no such key
/// to observe.
///
/// A NOTE ON WHAT Ncl.dll COULD NOT SETTLE. NavTestFilter is a thin wrapper over an
/// ITestFilter, and that interface is NOT in Ncl.dll -- it lives client-side. So the runtime
/// assembly fixes the AL BOUNDARY (the argument is a field number; SetFilter is void;
/// SetCurrentKey's trapping overload catches NavClientPageAbortException) and settles NONE of
/// the semantics: whether a filter replaces or accumulates, what CurrentKey's string looks
/// like, whether Ascending reorders an already-open page. Every one of those is decided below
/// by a service tier, which is the reason this file exists rather than a documentation note.
/// </summary>
codeunit 60350 "Test TestFilter"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "ALT TestFilter Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRow(EntryNo: Integer; Grp: Code[10]; Rank: Integer; Descr: Text[50]; OffPage: Code[10])
    var
        Row: Record "ALT TestFilter Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Grp := Grp;
        Row.Rank := Rank;
        Row.Descr := Descr;
        Row.OffPage := OffPage;
        Row.Insert();
    end;

    // Three rows whose PRIMARY-KEY order and RANK order DISAGREE, which is what makes every
    // SetCurrentKey and Ascending assertion below discriminating:
    //
    //   Entry No.  Grp  Rank  Descr    OffPage
    //       1      'B'   30   'One'    'KEEP'
    //       2      'A'   10   'Two'    'DROP'
    //       3      'A'   20   'Three'  'KEEP'
    //
    //   by "Entry No." (PK) : 1, 2, 3
    //   by Rank            : 2, 3, 1     -- reversed relative to the PK at both ends
    //   by Grp, Rank       : 2, 3, 1     -- same as Rank here, but reached via a composite key
    //
    // Grp is chosen so that the composite key's leading field does NOT already order the
    // rows the way the PK does: 'B' sorts after 'A', so entry 1 lands last under ByGrpRank.
    local procedure SeedThreeRows()
    begin
        SeedRow(1, 'B', 30, 'One', 'KEEP');
        SeedRow(2, 'A', 10, 'Two', 'DROP');
        SeedRow(3, 'A', 20, 'Three', 'KEEP');
    end;

    // Reads the "Entry No." column at each position of the open page, walking forward from
    // the first row, and returns them joined -- e.g. '2|3|1'. Every order assertion in this
    // file goes through this, so a failure message shows the whole observed order rather than
    // just the first row that differed.
    //
    // EVERY TEST HERE OPENS THE LIST WITH OpenView(), NOT OpenEdit(), AND THAT CHOICE IS
    // LOAD-BEARING FOR THIS HELPER. testpart/TestTestPart.al establishes on 8 cloud legs that
    // an EDITABLE repeater carries a trailing blank new-row line, and that Next() past the
    // last data row steps ONTO it and answers true. Walking such a page would append an empty
    // entry to every sequence this helper builds -- '1|2|3|' rather than '1|2|3' -- and every
    // order assertion in this file would be measuring that artifact instead of the filter or
    // the key it means to measure. A read-only page has no such line, and nothing in this
    // file needs the page to be editable: TestFilter changes which rows a page HAS and in
    // what ORDER, never their contents.
    local procedure WalkEntryNos(var L: TestPage "ALT TestFilter List") Seq: Text
    begin
        if not L.First() then
            exit('');
        repeat
            if Seq <> '' then
                Seq += '|';
            Seq += L.EntryNo.Value();
        until not L.Next();
    end;

    // ── SetFilter / GetFilter: the round trip, and that it is a real filter ─────────

    [Test]
    procedure TestFilter_SetFilter_And_GetFilter_RoundTripAFilterExpression()
    // CLAIM: a filter set through SetFilter is readable back through GetFilter on the same
    // field, and a field nobody filtered reads back EMPTY.
    //
    // Both halves are asserted on ONE open page, which is what makes the pair
    // discriminating: an implementation returning the stored string for every field passes
    // the first assertion and fails the second, and one returning '' always fails the first.
    //
    // The value round-tripped is a RANGE ('10..20'), not a single token, so an
    // implementation that only kept an equality value would fail here too.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetFilter(Rank, '10..20');

        Assert.AreEqual('10..20', L.Filter.GetFilter(Rank),
            'GetFilter must return the filter expression SetFilter was given, unchanged');
        Assert.AreEqual('', L.Filter.GetFilter(Descr),
            'GetFilter must return empty for a field no filter was set on');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetFilter_RestrictsTheRowsetAndNotJustTheReportedFilter()
    // CLAIM: SetFilter changes WHICH ROWS the page has, not merely what GetFilter reports.
    //
    // This is the assertion that an implementation recording the filter string without
    // applying it would fail while still passing the round-trip test above. Both the
    // included rows AND the excluded one are asserted -- the included-only half would pass
    // for an implementation that filtered nothing at all, since rows 2 and 3 are present
    // either way.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        // Rank 10..20 is rows 2 and 3; row 1 (Rank 30) is excluded.
        L.Filter.SetFilter(Rank, '10..20');

        Assert.AreEqual('2|3', WalkEntryNos(L),
            'the page must walk exactly the rows the filter admits, in key order');

        // And the excluded row must be unreachable, not merely absent from the walk.
        Assert.IsFalse(L.GoToKey(1),
            'a row the filter excludes must not be reachable by key');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetFilter_AppliesToAFieldWithNoControlOnThePage()
    // CLAIM: TestFilter's field argument resolves against the SOURCE TABLE, so a field the
    // page does not display at all is still filterable -- and filtering it really does
    // restrict the rowset.
    //
    // This is the runtime half of this file's central compile-time finding, and it is the
    // one claim here a service tier could plausibly have decided the other way: a
    // page-oriented implementation could reasonably have refused a field with no control.
    //
    // OffPage has no control on ALT TestFilter List. Rows 1 and 3 carry 'KEEP', row 2
    // carries 'DROP', so the expected rowset is a strict subset that is NOT the whole table
    // and NOT a single row -- an implementation ignoring the filter yields '1|2|3' and one
    // that emptied the page yields ''.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetFilter(OffPage, 'KEEP');

        Assert.AreEqual('1|3', WalkEntryNos(L),
            'a filter on a table field with no control on the page must still restrict the rowset');
        Assert.AreEqual('KEEP', L.Filter.GetFilter(OffPage),
            'and it must read back like any other filter');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetFilter_OnOneFieldReplacesRatherThanAccumulates()
    // CLAIM: two SetFilter calls on the SAME field leave only the second in force.
    //
    // The two filters are chosen so the wrong answer cannot resemble the right one. Rank
    // '10' then Rank '30' selects row 1 if the second REPLACES the first, and selects
    // NOTHING if the two are ANDed together, because no row has Rank both 10 and 30. So a
    // conjunction implementation produces an empty page, which is distinguishable from every
    // other outcome.
    //
    // Read together with the next test -- filters on DIFFERENT fields DO combine -- this
    // pins the scope of the replacement as per-field. Either test alone would be passed by a
    // wrong implementation: one that always replaced passes this and fails that, and one
    // that always accumulated does the reverse.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetFilter(Rank, '10');
        L.Filter.SetFilter(Rank, '30');

        Assert.AreEqual('30', L.Filter.GetFilter(Rank),
            'the second filter on a field must replace the first, not be appended to it');
        Assert.AreEqual('1', WalkEntryNos(L),
            'and the rowset must reflect only the second filter -- an implementation ANDing ' +
            'the two would show no rows at all');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetFilter_OnDifferentFieldsCombines()
    // CLAIM: filters on DIFFERENT fields both stay in force and intersect. The complement of
    // the previous test; see its comment for why the pair is what makes either meaningful.
    //
    // Grp 'A' is rows 2 and 3; Rank '20..30' is rows 1 and 3. The intersection is row 3
    // alone -- a row that NEITHER filter selects on its own, so an implementation that kept
    // only one of the two filters yields a two-row page and fails.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetFilter(Grp, 'A');
        L.Filter.SetFilter(Rank, '20..30');

        Assert.AreEqual('3', WalkEntryNos(L),
            'filters on different fields must intersect, leaving the one row both admit');
        Assert.AreEqual('A', L.Filter.GetFilter(Grp),
            'the earlier filter must still be reported after a filter on another field');
        Assert.AreEqual('20..30', L.Filter.GetFilter(Rank),
            'and so must the later one');

        L.Close();
    end;

    // ── CurrentKey / SetCurrentKey: the key, reported and applied ───────────────────

    [Test]
    procedure TestFilter_CurrentKey_NamesTheKeyThePageIsWalking()
    // CLAIM: CurrentKey() answers the key the page is currently walking, and on a page with
    // no SourceTableView that is the table's primary key.
    //
    // Asserted BY SUBSTRING on the key's field name rather than against a whole literal
    // string: the exact rendering of a key (bracketing, separators, whether it is quoted) is
    // a platform detail this file does not intend to pin, and pinning it would make the test
    // fail on a cosmetic change that breaks nothing.
    //
    // The second assertion is what stops the first from being vacuous. A field name that
    // belongs to a DIFFERENT key must NOT appear -- otherwise an implementation returning
    // every field of the table, or the whole table name, would pass.
    var
        L: TestPage "ALT TestFilter List";
        KeyText: Text;
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        KeyText := L.Filter.CurrentKey();

        // CurrentKey must name the primary key field on a page with no SourceTableView.
        // Assert.IsSubstring's own failure message names both strings, so it needs no
        // message argument -- it does not take one.
        Assert.IsSubstring(KeyText, 'Entry No.');
        Assert.IsFalse(KeyText.Contains('Rank'),
            'and it must not name a field belonging to a key the page is not walking');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetCurrentKey_ChangesBothTheReportedKeyAndTheWalkOrder()
    // CLAIM: SetCurrentKey() changes the key, observable in TWO independent ways -- what
    // CurrentKey() reports, and the order the page walks its rows.
    //
    // Both are asserted because either alone admits a wrong implementation: one that stored
    // the key without applying it passes the CurrentKey assertion, and one that reordered
    // without reporting passes the order assertion.
    //
    // The order is the load-bearing half, and it is only discriminating because the fixture
    // rows are seeded so the two keys DISAGREE at both ends -- PK order is 1|2|3 and Rank
    // order is 2|3|1. An implementation ignoring SetCurrentKey answers 1|2|3, which is not a
    // rotation or a reversal of the expected answer but a genuinely different sequence.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        Assert.AreEqual('1|2|3', WalkEntryNos(L),
            'precondition: the page opens walking the primary key');

        L.Filter.SetCurrentKey(Rank);

        // CurrentKey must report the key SetCurrentKey installed.
        Assert.IsSubstring(L.Filter.CurrentKey(), 'Rank');
        Assert.AreEqual('2|3|1', WalkEntryNos(L),
            'and the page must walk the rows in that key''s order, not the primary key''s');

        L.Close();
    end;

    [Test]
    procedure TestFilter_SetCurrentKey_AcceptsACompositeKey()
    // CLAIM: SetCurrentKey takes more than one field, selecting a composite key.
    //
    // ByGrpRank is Grp then Rank. Grp is seeded so its leading field does NOT already
    // reproduce the primary-key order -- entry 1 is group 'B' and sorts last -- so the
    // resulting order 2|3|1 differs from the page's opening order and an implementation
    // that ignored the second field, or the call entirely, is caught.
    //
    // The reported key is asserted to name BOTH fields, which is what distinguishes this
    // from the single-field Rank key that happens to produce the same row order on this
    // data. Without that assertion this test would not be able to tell the composite key
    // from the single one.
    var
        L: TestPage "ALT TestFilter List";
        KeyText: Text;
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetCurrentKey(Grp, Rank);
        KeyText := L.Filter.CurrentKey();

        // A composite key must report BOTH its fields. Naming only one would not
        // distinguish it from the single-field Rank key, which orders this data identically.
        Assert.IsSubstring(KeyText, 'Grp');
        Assert.IsSubstring(KeyText, 'Rank');
        Assert.AreEqual('2|3|1', WalkEntryNos(L),
            'and the rows must walk in the composite key''s order');

        L.Close();
    end;

    // ── Ascending: the direction, reported and applied ──────────────────────────────

    [Test]
    procedure TestFilter_Ascending_DefaultsToTrue()
    // CLAIM: a page opens walking its key ASCENDING, and Ascending() reports that.
    //
    // Paired with the walk order so the assertion is not merely about a flag: an
    // implementation whose getter returned true while the page walked backwards would fail
    // the second assertion. This is the baseline the reversal test below is measured against.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();

        Assert.IsTrue(L.Filter.Ascending(),
            'a freshly opened page must report an ascending walk');
        Assert.AreEqual('1|2|3', WalkEntryNos(L),
            'and must actually walk its key in ascending order');

        L.Close();
    end;

    [Test]
    procedure TestFilter_Ascending_False_ReversesTheWalkAndIsReportedBack()
    // CLAIM: Ascending(false) reverses the order the page walks, AND is reported back by
    // Ascending(); setting it true again restores both.
    //
    // All three steps are asserted on ONE open page, in both dimensions each time. That is
    // what makes this discriminating in every direction that matters:
    //
    //   - an implementation whose getter is hardcoded true fails at the middle step;
    //   - one that reports the flag but never reorders fails the order assertions;
    //   - one that reverses but cannot reverse BACK fails the final step, which is the
    //     failure mode a single set-and-check test would miss entirely.
    //
    // The expected reversed order 3|2|1 is the exact mirror of the ascending order, and the
    // fixture has three rows rather than two so a mirror is distinguishable from a rotation.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();

        L.Filter.Ascending(false);
        Assert.IsFalse(L.Filter.Ascending(),
            'Ascending() must report the descending direction just set');
        Assert.AreEqual('3|2|1', WalkEntryNos(L),
            'and the page must walk its key in reverse');

        L.Filter.Ascending(true);
        Assert.IsTrue(L.Filter.Ascending(),
            'setting ascending again must be reported');
        Assert.AreEqual('1|2|3', WalkEntryNos(L),
            'and must restore the forward walk -- a one-way implementation fails here');

        L.Close();
    end;

    [Test]
    procedure TestFilter_Ascending_AppliesToTheKeySetBySetCurrentKey()
    // CLAIM: the direction applies to whatever key is current, not to the primary key.
    //
    // Rank order ascending is 2|3|1, so descending must be 1|3|2. Note what that value rules
    // out: it is neither the primary key reversed (3|2|1) nor the Rank order unchanged
    // (2|3|1), so an implementation that applied the direction to the wrong key, or the key
    // to the wrong direction, produces a sequence this test does not accept.
    //
    // This is the interaction test the two features need -- SetCurrentKey and Ascending are
    // each pinned alone above, and neither of those tests would catch a composition that
    // dropped one of them.
    var
        L: TestPage "ALT TestFilter List";
    begin
        Initialize();
        SeedThreeRows();

        L.OpenView();
        L.Filter.SetCurrentKey(Rank);
        L.Filter.Ascending(false);

        Assert.AreEqual('1|3|2', WalkEntryNos(L),
            'descending must reverse the CURRENT key''s order, not the primary key''s');
        // ...and the key must still be the one SetCurrentKey installed.
        Assert.IsSubstring(L.Filter.CurrentKey(), 'Rank');

        L.Close();
    end;

    // ── A part carries its own Filter ───────────────────────────────────────────────

    [Test]
    procedure TestFilter_APartHasItsOwnFilterIndependentOfItsHost()
    // CLAIM: TestPart exposes Filter, and it is the PART's filter -- filtering the part does
    // not filter anything else.
    //
    // This is the pairing docs/al-language-coverage-gaps.md predicted when it recommended
    // TestFilter as the follow-on to the TestPart suite, and it reuses that suite's fixtures
    // rather than adding more.
    //
    // ALT TestPart Host has NO SourceTable and its part has no SubPageLink, so the part's
    // rowset stands entirely on its own table -- nothing here depends on link resolution.
    // The host hosts the SAME part page TWICE (Lines and ReadOnlyLines), which is what makes
    // the independence assertion possible at all: filtering Lines must leave ReadOnlyLines,
    // a sibling view of the very same table, unfiltered. An implementation that pushed the
    // filter down to the shared source table rather than holding it on the part would show
    // the restriction in both and fail.
    var
        Host: TestPage "ALT TestPart Host";
        Row: Record "ALT TestPart Row";
    begin
        Row.DeleteAll();
        Row.Init();
        Row.Grp := 'A';
        Row."Line No." := 10;
        Row.Descr := 'Alpha';
        Row.Insert();
        Row.Init();
        Row.Grp := 'A';
        Row."Line No." := 20;
        Row.Descr := 'Bravo';
        Row.Insert();

        Host.OpenEdit();
        Host.Lines.Filter.SetFilter("Line No.", '20');

        Assert.AreEqual('20', Host.Lines.Filter.GetFilter("Line No."),
            'a part must report the filter set on it');
        Assert.IsTrue(Host.Lines.First(),
            'the filtered part must still have its admitted row');
        Assert.AreEqual('Bravo', Host.Lines.Descr.Value(),
            'and must be positioned on it rather than on the excluded row');
        // The excluded row must be GONE, not merely behind the cursor. Asserted with
        // GoToKey rather than by walking to the end, because ALT TestPart Lines is an
        // EDITABLE repeater: testpart/TestTestPart.al establishes on 8 cloud legs that
        // Next() past the last data row of one answers TRUE, stepping onto a trailing blank
        // new-row line. So `IsFalse(Next())` would be wrong here for a reason that has
        // nothing to do with filtering, and asserting it would measure the new-row line
        // instead of the filter. GoToKey is unambiguous: it either finds the row or does not.
        Assert.IsFalse(Host.Lines.GoToKey('A', 10),
            'the row the part''s filter excludes must not be reachable in the part');

        // The sibling part over the SAME table must be untouched.
        Assert.AreEqual('', Host.ReadOnlyLines.Filter.GetFilter("Line No."),
            'filtering one part must not filter a sibling part over the same table');
        Assert.IsTrue(Host.ReadOnlyLines.First(),
            'and the sibling must still see its own first row');
        Assert.AreEqual('Alpha', Host.ReadOnlyLines.Descr.Value(),
            'which is the row the other part''s filter excluded');

        Host.Close();
    end;
}
