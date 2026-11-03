// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/filterpagebuilder/filterpagebuilder-data-type
// Scope: in-scope (Cloud-compatible) except RunModal(), which needs a client attached
// Fixtures used: ALT Universal (60000), ALT Composite (60001); shared Assert (60021)
// BC versions: 27.0+ (FilterPageBuilder is runtime 1.0/2.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: FilterPageBuilder is a mutable in-memory builder that accumulates named filter
/// controls -- each one a table plus a set of fields and filters -- and only needs a client
/// when RunModal() is finally called to show them. Everything BEFORE that call is a plain
/// object-graph operation over an ordered dictionary of RecordRefs, so the whole surface
/// except RunModal() is observable from a [Test] with no client in flight.
///
/// Nothing in this repository measured any part of FilterPageBuilder before this file.
/// docs/al-language-coverage-gaps.md leaves it unmentioned, and searching the suite for the
/// type name (with both `rg --hidden` and `command grep -rn`, which have different
/// silent-false-negative modes) finds only the scraper scripts. Note that
/// scripts/al-surface-inscope.json labels all 12 members "out-of-scope" -- that label is
/// wrong here in the same way it was wrong for SecretText (now a merged suite),
/// SessionSettings (31 passing tests) and WebServiceActionContext (32 passing tests): it
/// classifies by the type's NAME, on the assumption that anything ending in "PageBuilder"
/// is UI. Exactly one of the twelve members actually is.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. THE ADD METHODS RETURN THE CONTROL NAME, NOT A BOOLEAN OR AN INDEX. AddTable(),
///      AddRecord() and AddRecordRef() each return the name that now identifies the control,
///      which is the name that was passed in. Every name asserted here is a distinctive
///      non-empty string, so an implementation returning '' -- or returning a stringified
///      index -- fails rather than passing by coincidence.
///   2. NAMES ARE THE IDENTITY, AND RE-ADDING ONE IS IDEMPOTENT RATHER THAN ADDITIVE.
///      AddTable('X', 60000) twice leaves Count() at 1, not 2, and returns 'X' both times.
///      This is the single most surprising thing about the type: a builder is a keyed
///      dictionary, not an append-only list. An implementation backing it with a list fails.
///   3. RE-ADDING A NAME AGAINST A DIFFERENT TABLE IS AN ERROR, NOT A SILENT REPLACE.
///      The idempotence in (2) is conditional on the table id matching. Asserting BOTH
///      directions is what rules out an implementation that simply ignores the second Add:
///      such an implementation passes (2) and fails (3).
///   4. THE TRAPPABLE-RETURN CONVENTION. AddTable/AddRecord/AddRecordRef return the empty
///      string, and SetView returns false, when the return value is CAPTURED and the call
///      would otherwise error; the same call with the return value DISCARDED raises a
///      catchable error instead. Both halves are asserted for both shapes, because an
///      implementation that always errors passes the discarded half, and one that never
///      errors passes the captured half.
///   5. GetView AND SetView ARE ASYMMETRIC ON AN UNKNOWN CONTROL NAME. GetView('nope')
///      returns the empty string with no error; SetView('nope', ...) errors. This asymmetry
///      is real BC behavior, it is not documented on either method's page, and an
///      implementation that made the two consistent in EITHER direction fails one of the two
///      tests that pin it.
///   6. GetView ROUND-TRIPS A FILTER THAT WAS SET, AND THE DEFAULT-FILTER ARGUMENT OF
///      AddField REACHES IT. A filter passed as AddField's third argument appears in the
///      view GetView() returns, so the argument is not discarded. The view is asserted by
///      substring on the filter VALUE, not by whole-string equality, because the exact
///      view syntax carries a SORTING clause and caption-vs-name spelling that differ
///      between the two GetView overloads.
///   7. GetView(name, false) AND GetView(name, true) RENDER AN OPTION FILTER DIFFERENTLY --
///      as the ordinal integer and as the member name respectively. This is the ONLY part of
///      the view the flag reaches for the fixtures available here: it also governs the
///      sorting-field spelling and the ORDER() clause, but ALT Universal's key field's
///      caption IS its name and the default sort is all-ascending, so a view without an
///      option filter renders identically either way. An implementation ignoring the
///      argument fails both substring assertions.
///   8. Name() IS 1-BASED AND RANGE-CHECKED. Name(1) is the first control added, Name(Count())
///      the last, and both Name(0) and Name(Count() + 1) error. A 0-based implementation
///      fails the first assertion; an unchecked one fails the last two.
///   9. PageCaption() ON A FRESH BUILDER IS A NON-EMPTY PLATFORM DEFAULT, NOT ''.
///      The getter substitutes a localized caption when nothing was assigned, so an
///      implementation returning '' fails. The literal text is NOT asserted -- it is a
///      localized resource and this matrix runs more than one BC version -- only that it is
///      non-empty, that an assigned caption replaces it, and that Clear() restores it.
///  10. ASSIGNMENT IS NEITHER A DEEP COPY NOR A SHARED REFERENCE -- IT IS SPLIT, AND THIS IS
///      THE MOST SURPRISING THING ABOUT THE TYPE. The CONTROL COLLECTION is copied, so adding
///      a control to the copy leaves the original's Count() alone; but the RECORD each
///      control wraps is SHARED, so a view written through either builder is visible from
///      both. Three tests pin the split, and the third of them (a view set on the copy
///      reaching the original) is there because an earlier revision of this file asserted the
///      OPPOSITE and all 8 cloud legs falsified it identically. The mechanism is
///      NavRecordRef.Clone in Ncl.dll: it builds a fresh wrapper and copies `Target` by
///      reference. Compare WebServiceActionContext, whose assignment shares outright --
///      together the two files establish that AL's `:=` on a complex type is per-type
///      behavior, and can even be per-FIELD within one type.
///  11. Clear() EMPTIES THE CONTROLS BUT KEEPS AN ASSIGNED CAPTION. Count() returns to 0 and
///      a previously-known name stops resolving -- so Clear() is not merely a filter reset --
///      but the page caption SURVIVES it. "Clear resets the whole object" is the obvious
///      reading and it is wrong; an implementation that reset everything fails exactly one
///      test here and passes the rest, which is why both halves are asserted together.
///
/// COMPILE-TIME REFUSALS, measured with alc 17.0.34.45391 against this app's Cloud target.
/// These are the negative cases that CANNOT be written as [Test] procedures, because the
/// compiler rejects them before a service tier ever sees them:
///
///   FilterPageBuilder = FilterPageBuilder            error AL0175 (operator '=' not applicable)
///   FilterPageBuilder.AddField(Name, FieldNo: Int)   error AL0133 (cannot convert Integer to
///                                                    FieldRef) -- the AddField(Name, FieldNo)
///                                                    overload documented on Microsoft Learn as
///                                                    "filterpagebuilder-addfieldno-method" is
///                                                    NOT exposed to AL. Only the FieldRef form
///                                                    is callable, so every AddField test here
///                                                    goes through a RecordRef/FieldRef pair.
///   FilterPageBuilder.GetView(Index: Integer)        error AL0133 -- there is no index overload
///                                                    of GetView; controls are addressed by name
///                                                    only, and Name(Index) is the bridge.
///   FilterPageBuilder.Name(Index) with the return    error AL0192 (the return value must be
///     value discarded                                used). Name() is the ONE method here whose
///                                                    return value is mandatory -- AddTable,
///                                                    AddField and SetView all compile with
///                                                    theirs discarded, which is exactly what
///                                                    makes their trappable-return behavior
///                                                    testable. Consequence: the two Name()
///                                                    range tests must assign into a variable
///                                                    inside `asserterror`, not call bare.
///
/// What DOES compile, and is used below: Format(FilterPageBuilder), assignment to a Variant
/// AND back out of one, and passing a builder to Assert.AreEqual's Variant parameters.
/// (The Variant path is worth stating explicitly because it is exactly where corpus PR #220
/// was bitten: a WebServiceActionResultCode passed to a Variant parameter compiled cleanly
/// and then failed the server's per-object C# codegen with CS1503, so none of that file's
/// tests ran. FilterPageBuilder is not exposed to that failure -- NavFilterPageBuilder
/// derives from NavComplexValue, which derives from NavValue, the runtime's boxed-value base
/// -- but the assertion below is what MEASURES that rather than assuming it.)
///
/// DELIBERATELY NOT COVERED: RunModal(). It is the one genuinely UI-level member -- it opens
/// a modal filter page and blocks on the user -- and a [Test] with no client attached cannot
/// provoke it without hanging or raising an unhandled-UI error that says nothing about the
/// builder. Covering it needs a TestPage-style handler fixture, which is a separate suite.
/// Nothing else on the type is withheld.
/// </summary>
codeunit 60279 "Test Filter Page Builder"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── The Add methods: return value, identity, idempotence ────────────────────────

    [Test]
    procedure FilterPageBuilder_AddTable_ReturnsTheControlName()
    // CLAIM: AddTable() returns the name that now identifies the control -- the name that
    // was passed in -- not a boolean, not an index, and not the empty string.
    var
        FPB: FilterPageBuilder;
        ReturnedName: Text;
    begin
        Initialize();

        ReturnedName := FPB.AddTable('Universal', Database::"ALT Universal");

        Assert.AreEqual('Universal', ReturnedName, 'AddTable must return the control name it was given');
        Assert.AreEqual(1, FPB.Count(), 'One AddTable must produce exactly one control');
    end;

    [Test]
    procedure FilterPageBuilder_AddRecord_ReturnsTheControlName()
    // CLAIM: AddRecord() takes a Record rather than a table id and returns the same kind of
    // control name AddTable() does.
    var
        FPB: FilterPageBuilder;
        Universal: Record "ALT Universal";
        ReturnedName: Text;
    begin
        Initialize();

        ReturnedName := FPB.AddRecord('FromRecord', Universal);

        Assert.AreEqual('FromRecord', ReturnedName, 'AddRecord must return the control name it was given');
        Assert.AreEqual(1, FPB.Count(), 'One AddRecord must produce exactly one control');
    end;

    [Test]
    procedure FilterPageBuilder_AddRecordRef_ReturnsTheControlName()
    // CLAIM: AddRecordRef() takes an open RecordRef and returns the same kind of control name.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        ReturnedName: Text;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        ReturnedName := FPB.AddRecordRef('FromRef', RecRef);

        Assert.AreEqual('FromRef', ReturnedName, 'AddRecordRef must return the control name it was given');
        Assert.AreEqual(1, FPB.Count(), 'One AddRecordRef must produce exactly one control');
    end;

    [Test]
    procedure FilterPageBuilder_AddTable_ThreeDistinctNames_CountIsThree()
    // CLAIM: distinct names accumulate. Three controls, and Count() reports 3 -- so the
    // builder is not a single-slot holder that the last Add overwrites.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.AddTable('One', Database::"ALT Universal");
        FPB.AddTable('Two', Database::"ALT Composite");
        FPB.AddTable('Three', Database::"ALT Universal");

        Assert.AreEqual(3, FPB.Count(), 'Three distinctly-named controls must give Count() = 3');
    end;

    [Test]
    procedure FilterPageBuilder_AddTable_SameNameSameTable_IsIdempotent()
    // CLAIM: re-adding a name that is already present, against the SAME table, returns the
    // existing control rather than adding a second one -- so the builder is keyed by name,
    // not an append-only list. This is the paired positive of the _Throws test below: an
    // implementation that silently ignored EVERY repeat Add would pass this and fail that.
    var
        FPB: FilterPageBuilder;
        FirstName: Text;
        SecondName: Text;
    begin
        Initialize();

        FirstName := FPB.AddTable('Same', Database::"ALT Universal");
        SecondName := FPB.AddTable('Same', Database::"ALT Universal");

        Assert.AreEqual('Same', FirstName, 'The first AddTable must return the control name');
        Assert.AreEqual('Same', SecondName, 'The second AddTable must return the same control name');
        Assert.AreEqual(1, FPB.Count(), 'Re-adding one name must NOT create a second control');
    end;

    [Test]
    procedure FilterPageBuilder_AddTable_SameNameDifferentTable_Throws()
    // CLAIM: the idempotence above is conditional on the table matching. Re-using a control
    // name for a DIFFERENT table is a redefinition and errors -- it does not silently replace
    // the control and does not silently keep the old one.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.AddTable('Clash', Database::"ALT Universal");

        asserterror FPB.AddTable('Clash', Database::"ALT Composite");

        Assert.ExpectedError('Clash');
    end;

    [Test]
    procedure FilterPageBuilder_AddTable_ZeroTableId_Throws()
    // CLAIM: a table id below 1 is rejected outright, so the builder validates its argument
    // rather than storing whatever it is handed.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        asserterror FPB.AddTable('Bad', 0);

        Assert.ExpectedError('The filter page table ID must be a positive number greater than zero.');
        Assert.AreEqual(0, FPB.Count(), 'A rejected AddTable must not leave a control behind');
    end;

    [Test]
    procedure FilterPageBuilder_AddTable_ReturnCaptured_BadTableId_ReturnsEmpty()
    // CLAIM: the trappable-return convention. The SAME call that errors above returns the
    // empty string instead when its return value is captured. Both halves are asserted --
    // this one and the _Throws one above -- because an implementation that always errors
    // passes only that one and an implementation that never errors passes only this one.
    var
        FPB: FilterPageBuilder;
        ReturnedName: Text;
        GoodName: Text;
    begin
        Initialize();

        ReturnedName := FPB.AddTable('Trapped', 0);

        Assert.AreEqual('', ReturnedName, 'A captured AddTable of an invalid table id must return empty');
        Assert.AreEqual(0, FPB.Count(), 'A trapped AddTable must not leave a control behind');

        // ...and the builder is still usable afterwards, so trapping is not a poison pill.
        GoodName := FPB.AddTable('Good', Database::"ALT Universal");
        Assert.AreEqual('Good', GoodName, 'The builder must still work after a trapped failure');
        Assert.AreEqual(1, FPB.Count(), 'The good control must be the only one present');
    end;

    // ── AddField: the FieldRef overload, and the default-filter argument ────────────

    [Test]
    procedure FilterPageBuilder_AddField_KnownControl_ReturnsTrue()
    // CLAIM: AddField() against a control that exists returns true. Only the FieldRef
    // overload is reachable from AL -- see the compile-refusal list in the file header.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Added: Boolean;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(3); // Integer Field

        Added := FPB.AddField('Ref', FldRef);

        Assert.IsTrue(Added, 'AddField on a known control must return true');
        Assert.AreEqual(1, FPB.Count(), 'AddField must not add a control of its own');
    end;

    [Test]
    procedure FilterPageBuilder_AddField_UnknownControl_ReturnsFalse()
    // CLAIM: AddField() against a name no control carries returns false when the return value
    // is captured -- the negative direction of the test above. Asserting the pair is what
    // rules out an implementation that returns a constant.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        Added: Boolean;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(3);

        Added := FPB.AddField('NoSuchControl', FldRef);

        Assert.IsFalse(Added, 'AddField on an unknown control must return false');
    end;

    [Test]
    procedure FilterPageBuilder_AddField_DefaultFilter_ReachesTheView()
    // CLAIM: AddField()'s optional third argument is a default filter on that field, and it
    // is not discarded -- it shows up in the view GetView() returns. The assertion is a
    // substring on the filter VALUE rather than whole-string equality, because the view
    // carries a SORTING clause whose exact spelling is not the subject of this test.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        View: Text;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(3); // Integer Field

        FPB.AddField('Ref', FldRef, '>41');
        View := FPB.GetView('Ref');

        Assert.AreNotEqual('', View, 'GetView on a control with a default filter must not be empty');
        Assert.IsSubstring(View, '>41');
    end;

    [Test]
    procedure FilterPageBuilder_AddField_NoDefaultFilter_ViewHasNoFilterValue()
    // CLAIM: the negative direction of the test above. The same field added WITHOUT a default
    // filter leaves that filter value out of the view, so the previous test is measuring the
    // argument rather than something the field's presence alone would produce.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        View: Text;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(3);

        FPB.AddField('Ref', FldRef);
        View := FPB.GetView('Ref');

        Assert.IsFalse(View.Contains('>41'), 'A field added without a default filter must not carry one');
    end;

    // ── GetView / SetView: the asymmetry, and the caption switch ───────────────────

    [Test]
    procedure FilterPageBuilder_SetView_ThenGetView_RoundTripsTheFilter()
    // CLAIM: a view assigned with SetView() is readable back through GetView(). The filter
    // value asserted is distinctive, so an implementation returning a default or an empty
    // view fails.
    var
        FPB: FilterPageBuilder;
        Assigned: Boolean;
        View: Text;
    begin
        Initialize();

        FPB.AddTable('Universal', Database::"ALT Universal");

        Assigned := FPB.SetView('Universal', 'WHERE("Integer Field"=FILTER(>4711))');
        View := FPB.GetView('Universal');

        Assert.IsTrue(Assigned, 'SetView on a known control must return true');
        Assert.IsSubstring(View, '4711');
    end;

    [Test]
    procedure FilterPageBuilder_GetView_UnknownControl_ReturnsEmpty()
    // CLAIM: GetView() on a name no control carries returns the empty string and does NOT
    // error. Half of the asymmetry described in the file header; the SetView half below is
    // the other. An implementation that made the two consistent fails one of them.
    var
        FPB: FilterPageBuilder;
        View: Text;
    begin
        Initialize();

        FPB.AddTable('Known', Database::"ALT Universal");

        View := FPB.GetView('Unknown');

        Assert.AreEqual('', View, 'GetView on an unknown control must return empty, not error');
    end;

    [Test]
    procedure FilterPageBuilder_SetView_UnknownControl_Throws()
    // CLAIM: SetView() on a name no control carries ERRORS -- unlike GetView(), which returns
    // empty for the very same name. This is the asymmetry the file header calls out.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.AddTable('Known', Database::"ALT Universal");

        asserterror FPB.SetView('Unknown', 'WHERE("Integer Field"=FILTER(>1))');

        Assert.ExpectedError('Unknown');
    end;

    [Test]
    procedure FilterPageBuilder_SetView_ReturnCaptured_UnknownControl_ReturnsFalse()
    // CLAIM: the trappable-return half of the test above -- the same call returns false
    // rather than erroring when its return value is captured.
    var
        FPB: FilterPageBuilder;
        Assigned: Boolean;
    begin
        Initialize();

        FPB.AddTable('Known', Database::"ALT Universal");

        Assigned := FPB.SetView('Unknown', 'WHERE("Integer Field"=FILTER(>1))');

        Assert.IsFalse(Assigned, 'A captured SetView on an unknown control must return false');
    end;

    [Test]
    procedure FilterPageBuilder_SetView_EmptyView_ReturnsFalse()
    // CLAIM: an empty view string is rejected even on a control that exists, so the refusal
    // above is about the view as well as the name. Paired with the round-trip test, this
    // rules out an implementation that accepts anything.
    var
        FPB: FilterPageBuilder;
        Assigned: Boolean;
    begin
        Initialize();

        FPB.AddTable('Known', Database::"ALT Universal");

        Assigned := FPB.SetView('Known', '');

        Assert.IsFalse(Assigned, 'A captured SetView with an empty view must return false');
    end;

    [Test]
    procedure FilterPageBuilder_GetView_CaptionsFlag_RendersAnOptionFilterDifferently()
    // CLAIM: GetView()'s optional second argument changes how an OPTION filter is rendered --
    // false spells the option as its ordinal INTEGER, true spells it as its member NAME. An
    // implementation ignoring the argument returns the same string twice and fails both
    // substring assertions at once.
    //
    // The option field is not incidental. BC builds the view string by concatenating a
    // SORTING clause (spelled from the KEY fields) and a WHERE clause, and the captions flag
    // reaches only three things: the sorting-field spelling, the ORDER() clause when the sort
    // is not all-ascending, and whether option values in the WHERE clause are written as
    // integers. ALT Universal's key is "Entry No.", whose caption IS its name, and the sort
    // here is the default all-ascending -- so a view with no option filter in it renders
    // IDENTICALLY either way and this test would be vacuous. Confirmed against
    // RecordImplementationHelper.GetTableViewString in Microsoft.Dynamics.Nav.Ncl.dll, which
    // is also why the earlier draft of this test -- a captioned TABLE with no filters -- was
    // discarded before it ever reached CI rather than being left in to pass for the wrong
    // reason.
    var
        FPB: FilterPageBuilder;
        RecRef: RecordRef;
        FldRef: FieldRef;
        WithCaptions: Text;
        WithNames: Text;
    begin
        Initialize();

        RecRef.Open(Database::"ALT Universal");
        FPB.AddRecordRef('Ref', RecRef);
        FldRef := RecRef.Field(14); // Option Field: " ",Draft,Active,Closed -- Active is ordinal 2

        FPB.AddField('Ref', FldRef, 'Active');

        WithCaptions := FPB.GetView('Ref', true);
        WithNames := FPB.GetView('Ref', false);

        Assert.AreNotEqual(WithCaptions, WithNames, 'The captions flag must change the spelling of an option filter');
        Assert.IsSubstring(WithCaptions, 'Active');
        Assert.IsFalse(WithNames.Contains('Active'), 'GetView(name, false) must spell the option as its ordinal, not its name');
        // The ordinal is asserted through the pair above rather than by searching for the bare
        // character '2', which VERSION(1)/field numbers could supply for the wrong reason.
    end;

    // ── Name(): 1-based, range-checked ─────────────────────────────────────────────

    [Test]
    procedure FilterPageBuilder_Name_IsOneBasedAndInInsertionOrder()
    // CLAIM: Name(1) is the FIRST control added and Name(Count()) the last, so the index is
    // 1-based and the controls are held in insertion order. A 0-based implementation, or one
    // holding them in an unordered map, fails.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");
        FPB.AddTable('Beta', Database::"ALT Composite");

        Assert.AreEqual(2, FPB.Count(), 'Two controls must have been added');
        Assert.AreEqual('Alpha', FPB.Name(1), 'Name(1) must be the first control added');
        Assert.AreEqual('Beta', FPB.Name(2), 'Name(2) must be the second control added');
    end;

    [Test]
    procedure FilterPageBuilder_Name_IndexZero_Throws()
    // CLAIM: index 0 is below the range, confirming the 1-based indexing above rather than
    // leaving it ambiguous with a 0-based implementation that happens to be off by one.
    // Name()'s return value is MANDATORY (omitting it is error AL0192, see the file header),
    // so the call is written into a variable even though the assertion is about the error.
    var
        FPB: FilterPageBuilder;
        Unused: Text;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");

        asserterror Unused := FPB.Name(0);

        // The message names BOTH bounds of the accepted range, so asserting it in full is a
        // second, independent statement that the range really is 1..Count() -- one control
        // was added, so the upper bound must read 1 and not 0.
        Assert.ExpectedError('The filter control index value 0 is out of range. The value must be greater than or equal to 1 and less than or equal to 1.');
    end;

    [Test]
    procedure FilterPageBuilder_Name_IndexPastEnd_Throws()
    // CLAIM: index Count() + 1 is above the range. With the two tests above, this pins both
    // ends of a checked 1..Count() range.
    var
        FPB: FilterPageBuilder;
        Unused: Text;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");

        asserterror Unused := FPB.Name(2);

        Assert.ExpectedError('The filter control index value 2 is out of range. The value must be greater than or equal to 1 and less than or equal to 1.');
    end;

    // ── PageCaption: a platform default, not empty ─────────────────────────────────

    [Test]
    procedure FilterPageBuilder_PageCaption_FreshBuilder_IsNonEmptyDefault()
    // CLAIM: PageCaption() on a builder nothing was assigned to returns a NON-EMPTY platform
    // default, not ''. An implementation returning the empty string for an unset caption --
    // the obvious-but-wrong reading -- fails here. The literal text is deliberately not
    // asserted: it is a localized resource and this matrix runs several BC versions.
    var
        FPB: FilterPageBuilder;
        Caption: Text;
    begin
        Initialize();

        Caption := FPB.PageCaption();

        Assert.AreNotEqual('', Caption, 'A fresh builder must report a non-empty default caption');
    end;

    [Test]
    procedure FilterPageBuilder_PageCaption_Assigned_ReplacesTheDefault()
    // CLAIM: an assigned caption reads back exactly, and it is not the default -- so the
    // setter is not ignored and the default is not sticky.
    var
        FPB: FilterPageBuilder;
        DefaultCaption: Text;
        Caption: Text;
    begin
        Initialize();

        DefaultCaption := FPB.PageCaption();
        FPB.PageCaption('Pick your rows');
        Caption := FPB.PageCaption();

        Assert.AreEqual('Pick your rows', Caption, 'An assigned caption must read back exactly');
        Assert.AreNotEqual(DefaultCaption, Caption, 'An assigned caption must replace the default');
    end;

    [Test]
    procedure FilterPageBuilder_PageCaption_LastWriteWins()
    // CLAIM: a second assignment replaces the first rather than being ignored or appended.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.PageCaption('First caption');
        FPB.PageCaption('Second caption');

        Assert.AreEqual('Second caption', FPB.PageCaption(), 'The last assigned caption must win');
    end;

    // ── Assignment is a deep copy ──────────────────────────────────────────────────

    [Test]
    procedure FilterPageBuilder_Assignment_CopiesTheControlCollection()
    // CLAIM: assigning one builder to another COPIES the control collection; adding a control
    // to the copy leaves the original's Count() alone. This is the half of the assignment
    // semantics that IS a copy -- the record behind each control is not, see
    // FilterPageBuilder_Assignment_ViewOnCopyDoesReachOriginal below.
    var
        Original: FilterPageBuilder;
        CopyBuilder: FilterPageBuilder;
    begin
        Initialize();

        Original.AddTable('Shared', Database::"ALT Universal");

        CopyBuilder := Original;
        CopyBuilder.AddTable('OnlyOnCopy', Database::"ALT Composite");

        Assert.AreEqual(2, CopyBuilder.Count(), 'The copy must carry both controls');
        Assert.AreEqual(1, Original.Count(), 'The original must be untouched by writes to the copy');
        Assert.AreEqual('Shared', Original.Name(1), 'The original must still carry its own control');
    end;

    [Test]
    procedure FilterPageBuilder_Assignment_CopiesTheExistingViews()
    // CLAIM: the copy is not merely structural -- a filter set on the original before the
    // assignment survives into the copy. An implementation copying only the control names
    // fails here while passing the Count() test above.
    var
        Original: FilterPageBuilder;
        CopyBuilder: FilterPageBuilder;
        CopiedView: Text;
    begin
        Initialize();

        Original.AddTable('Universal', Database::"ALT Universal");
        Original.SetView('Universal', 'WHERE("Integer Field"=FILTER(>4711))');

        CopyBuilder := Original;
        CopiedView := CopyBuilder.GetView('Universal');

        Assert.IsSubstring(CopiedView, '4711');
    end;

    [Test]
    procedure FilterPageBuilder_Assignment_ViewOnCopyDoesReachOriginal()
    // CLAIM: the copy is SHALLOW where it matters most, and this is the single most
    // surprising thing about the type. A filter set on the COPY after the assignment DOES
    // appear in the original's view -- even though adding a whole new control to the copy
    // does not (the test above). The two together are the real semantics:
    //
    //     the CONTROL COLLECTION is copied  -- Count() is independent
    //     the RECORD each control wraps is SHARED -- views written through either builder
    //                                               are visible from both
    //
    // MEASURED, not assumed. An earlier revision of this file asserted the opposite -- that
    // a view set on the copy stays on the copy -- and all 8 cloud legs of the corpus CI
    // falsified it identically on BC 27.0, 27.3, 27.5, 28.0, 28.1, 28.2, 28.3 and 28.4. The
    // mechanism is visible in Microsoft.Dynamics.Nav.Ncl.dll:
    // FilterControlInformation's copy constructor calls RecordReference.Clone(parent), and
    // NavRecordRef.Clone builds a fresh wrapper that copies `Target` BY REFERENCE. The
    // wrapper is new; the NavRecord holding the filters behind it is the same object.
    //
    // So "FilterPageBuilder assignment is a deep copy" is wrong, and so is "it is a shared
    // reference". Neither summary survives contact with the tier; only the split above does,
    // which is why both directions are pinned rather than one.
    var
        Original: FilterPageBuilder;
        CopyBuilder: FilterPageBuilder;
        OriginalView: Text;
    begin
        Initialize();

        Original.AddTable('Universal', Database::"ALT Universal");
        CopyBuilder := Original;

        CopyBuilder.SetView('Universal', 'WHERE("Integer Field"=FILTER(>4711))');
        OriginalView := Original.GetView('Universal');

        Assert.IsSubstring(OriginalView, '4711');
    end;

    // ── Clear() ────────────────────────────────────────────────────────────────────

    [Test]
    procedure FilterPageBuilder_Clear_EmptiesTheControls()
    // CLAIM: Clear() removes the controls outright -- Count() returns to 0 and a name that
    // resolved before stops resolving. An implementation that only reset the FILTERS would
    // leave Count() at 2 and fail.
    var
        FPB: FilterPageBuilder;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");
        FPB.AddTable('Beta', Database::"ALT Composite");
        Assert.AreEqual(2, FPB.Count(), 'Two controls must be present before Clear');

        Clear(FPB);

        Assert.AreEqual(0, FPB.Count(), 'Clear must empty the controls');
        Assert.AreEqual('', FPB.GetView('Alpha'), 'A cleared control name must stop resolving');
    end;

    [Test]
    procedure FilterPageBuilder_Clear_KeepsTheAssignedCaption()
    // CLAIM: Clear() empties the CONTROLS but LEAVES an assigned page caption in place. This
    // is the counter-intuitive half and the reason the test is here: "Clear resets the whole
    // object" is the obvious reading, and it is wrong. The caption is not part of the control
    // collection Clear() walks, so a builder that has been cleared still reports the caption
    // it was given while reporting Count() = 0.
    //
    // An implementation that reset everything -- the natural thing to write -- fails this
    // test while passing every other Clear test in this file. That asymmetry is the whole
    // point of asserting both halves in one procedure.
    var
        FPB: FilterPageBuilder;
        DefaultCaption: Text;
    begin
        Initialize();

        DefaultCaption := FPB.PageCaption();
        FPB.AddTable('Alpha', Database::"ALT Universal");
        FPB.PageCaption('Pick your rows');
        Assert.AreEqual('Pick your rows', FPB.PageCaption(), 'The caption must be assigned before Clear');

        Clear(FPB);

        Assert.AreEqual(0, FPB.Count(), 'Clear must still empty the controls');
        Assert.AreEqual('Pick your rows', FPB.PageCaption(), 'Clear must NOT discard an assigned caption');
        Assert.AreNotEqual(DefaultCaption, FPB.PageCaption(), 'The caption must not have fallen back to the default');
    end;

    [Test]
    procedure FilterPageBuilder_Clear_ThenReuse_Works()
    // CLAIM: a cleared builder is reusable -- the name that was just removed can be added
    // again without the redefinition error, proving Clear() dropped the entry rather than
    // tombstoning it.
    var
        FPB: FilterPageBuilder;
        ReturnedName: Text;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");
        Clear(FPB);

        ReturnedName := FPB.AddTable('Alpha', Database::"ALT Composite");

        Assert.AreEqual('Alpha', ReturnedName, 'A cleared name must be reusable for another table');
        Assert.AreEqual(1, FPB.Count(), 'The reused control must be the only one present');
    end;

    // ── Format() and Variant ───────────────────────────────────────────────────────

    [Test]
    procedure FilterPageBuilder_Variant_RoundTripsThroughAVariant()
    // CLAIM: a builder converts to a Variant and back, and the recovered builder carries the
    // controls the original had. This also MEASURES that a FilterPageBuilder in a Variant
    // parameter survives the server's per-object C# codegen -- the failure that stopped every
    // test in corpus PR #220's first revision from running at all.
    var
        FPB: FilterPageBuilder;
        Recovered: FilterPageBuilder;
        AsVariant: Variant;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");
        FPB.AddTable('Beta', Database::"ALT Composite");

        AsVariant := FPB;
        Recovered := AsVariant;

        Assert.AreEqual(2, Recovered.Count(), 'A builder recovered from a Variant must carry its controls');
        Assert.AreEqual('Alpha', Recovered.Name(1), 'The recovered builder must preserve insertion order');
    end;

    [Test]
    procedure FilterPageBuilder_Format_ReturnsANonEmptyRendering()
    // CLAIM: Format() on a builder produces a non-empty string. The exact rendering is not
    // asserted -- it is not documented and would be brittle across versions -- only that the
    // type is formattable at all, which is the property AL code relies on when it puts a
    // builder into a message or an Assert argument.
    var
        FPB: FilterPageBuilder;
        Rendered: Text;
    begin
        Initialize();

        FPB.AddTable('Alpha', Database::"ALT Universal");
        Rendered := Format(FPB);

        Assert.AreNotEqual('', Rendered, 'Format() on a builder must produce a non-empty rendering');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
