// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/errorinfo/errorinfo-data-type
// Scope: in-scope (Cloud-compatible) -- measured with the real alc against this app's
//   Cloud target, runtime 16.0. See the CORRECTED SCOPE NOTE below.
// Fixtures used: ALT ErrorInfo Row (60351), ALT ErrorInfo Action Sink (60352);
//   shared Assert (60021)
// BC versions: 27.0+ (ErrorInfo members are runtime 3.0-12.0; every version in this matrix
//   has all of them)
//
/// <summary>
/// CLAIM: ErrorInfo is a 21-member AL data type, and it is REACHABLE FROM A CLOUD [Test].
///
/// CORRECTED SCOPE NOTE. error-handling/TestErrorInfo.al carries the header note
/// "ErrorInfo type is OnPrem-only; testing error text patterns available in Cloud". THAT
/// NOTE IS FALSE, and it is the reason this surface sat unmeasured behind a file named
/// after it. That file uses the ErrorInfo TYPE zero times -- a search for `: ErrorInfo`
/// or `ErrorInfo.` in it returns nothing; its six tests exercise plain Error() text
/// formatting and GetLastErrorText/GetLastErrorCode. Before this file, the string
/// "ErrorInfo" appeared exactly ONCE in the whole corpus: as that codeunit's own name.
///
/// The note was falsified with the real alc, not by reading documentation. Compiled
/// against this app's Cloud target, ALL 21 member groups bind: Create (all three
/// overloads), Message, Title, DetailedMessage, Collectible, Callstack, ControlName,
/// FieldNo, TableId, PageNo, RecordId, SystemId, CustomDimensions, Verbosity,
/// DataClassification, ErrorType, AddAction and AddNavigationAction. So does the
/// error-collection surface this file's runtime claims rest on -- GetCollectedErrors(),
/// HasCollectedErrors(), ClearCollectedErrors(), the [ErrorBehavior(ErrorBehavior::Collect)]
/// attribute, and Error(ErrorInfo).
///
/// THE QUESTION THIS FILE WAS OPENED TO SETTLE: is a collectible error's RUNTIME behavior
/// -- collection into an error set -- observable from a [Test] without a client? The
/// previous agent declined to answer it by reasoning. Ncl.dll answers it structurally:
/// ErrorCollection.ALGetCollectedErrors reads NavCurrentThread.Session.ErrorCollection,
/// which is SERVER-SIDE SESSION STATE, with no client proxy anywhere on the path. That is
/// the opposite of TestPart.Expand/IsExpanded (testpart/TestTestPart.al), which is
/// unreachable precisely BECAUSE the refusal crosses up from the client proxy as a raw CLR
/// exception. Collection is therefore expected to be observable, and claims 8-12 below are
/// what actually put that to the tier. THE TIER CONFIRMED IT, but only after correcting
/// HOW the scope is opened -- see "what the tier falsified" below.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. THE TWO Create() OVERLOADS DISAGREE ABOUT COLLECTIBILITY, and this is the sharpest
///      thing in the file. The ZERO-ARGUMENT ErrorInfo.Create() produces a COLLECTIBLE
///      ErrorInfo; ErrorInfo.Create(Message) produces a NON-collectible one. Both halves are
///      asserted, in adjacent tests, so the asymmetry is pinned rather than incidental.
///      Everything else a fresh instance reports is also pinned: Verbosity::Error,
///      DataClassification::CustomerContent, and empty Message/Title/DetailedMessage. An
///      implementation defaulting everything to the zero value of its type fails, because
///      Verbosity::Error is NOT Verbosity's first member -- Verbosity::Normal sorts before
///      it -- so "returns the zero enum member" is a DIFFERENT and failing answer.
///   2. EVERY SCALAR ACCESSOR ROUND-TRIPS, AND THEY ARE MUTUALLY INDEPENDENT. Each setter
///      is written with a distinct value and every OTHER accessor is then re-read, so an
///      implementation backing two properties with one field fails. The independence half
///      is what makes this more than six copies of one trivial assertion.
///   3. Collectible() ROUND-TRIPS IN BOTH DIRECTIONS. Set true then false and assert both,
///      so an implementation that latches on first write, or that ignores its argument and
///      returns a constant, fails one of the two halves.
///   4. Create(Message, Collectible) SETS COLLECTIBILITY FROM ITS ARGUMENT, asserted as a
///      PAIR -- create one collectible and one not, from the same call shape, and assert
///      they DISAGREE. A constant-returning implementation passes either half alone and
///      fails the pair.
///   5. THE var Record OVERLOAD POPULATES TableId AND RecordId FROM THE RECORD. Asserted
///      against a real seeded row: TableId is the fixture table's own id, and the RecordId
///      formats as the one belonging to THAT row and NOT to a second, different row. Two
///      distinct rows are used precisely so the comparison cannot succeed by both sides
///      being the same thing (the trap this series has hit before).
///   6. FieldNo AND PageNo ROUND-TRIP INDEPENDENTLY OF THE RECORD. The fixture's Payload is
///      FIELD 2, not field 1, so an implementation answering a hardcoded 1 fails.
///   7. CustomDimensions ROUND-TRIPS A DICTIONARY, and a fresh ErrorInfo's is EMPTY. Both
///      halves, so "always returns the dictionary you last passed anyone" and "always
///      returns empty" both fail.
///   8. A COLLECTIBLE ERROR DOES NOT ABORT THE COLLECTING SCOPE. Execution continues past
///      the failed call: the helper sets a flag AFTER the raiser returns and asserts it,
///      which an implementation that let the error unwind could never reach. The scope then
///      rethrows on exit, and the caller traps that -- so the test also pins that the
///      rethrown text is the collected message.
///   9. THE COLLECTED ERROR CARRIES THE MESSAGE IT WAS RAISED WITH, and the count is
///      exactly 1 -- not merely non-empty. Read INSIDE the scope, which is the only place
///      the set still exists.
///  10. A NON-COLLECTIBLE ErrorInfo IS NOT COLLECTED EVEN INSIDE A COLLECTING SCOPE. It
///      unwinds immediately -- an Assert.Fail() after the call is never reached -- and
///      nothing is left collected. This is the discriminating half of the pair: Ncl.dll's
///      ErrorCollection.Collect returns false unless error.ALCollectible, so an
///      implementation that collected everything passes claims 8-9 and fails this one. The
///      message trapped here is the RAISER's, not a scope-exit rethrow, which is itself the
///      observable difference between the two paths.
///  11. TWO COLLECTED ERRORS ACCUMULATE IN RAISE ORDER, asserted by position with different
///      messages, so keeping only the first, only the last, or reversing all fail. Two
///      collected errors also make the scope exit with the MULTIPLE-errors summary rather
///      than the verbatim message -- a difference from claim 8 that the test pins.
///  12. ClearCollectedErrors() EMPTIES THE SET, asserted in both directions inside the
///      scope, AND DISARMS THE SCOPE-EXIT RETHROW: with the set cleared the helper returns
///      normally and needs no asserterror, which is the sharpest available proof that the
///      clear really emptied it rather than merely hiding it from the getter. Returning
///      normally is itself the assertion -- had the clear not worked, the scope would have
///      rethrown and the call would have raised.
///  13. AddAction() AND AddNavigationAction() BIND AND DO NOT THROW against a real target
///      codeunit and method, and adding actions LEAVES THE REST OF THE OBJECT INTACT. This
///      is a deliberately LIMITED claim -- the callback cannot fire without a client, so the
///      test names say NoThrow. The intact-state half is what keeps it from being vacuous:
///      an implementation whose AddAction corrupted or reset the message would fail it.
///
/// WHAT THE TIER FALSIFIED, on all 8 cloud legs identically, and what each correction
/// teaches. Both were wrong readings of Ncl.dll, not wrong guesses about AL:
///
///   A. THE ZERO-ARGUMENT Create() IS COLLECTIBLE. The first revision asserted
///      Collectible = false for a fresh instance, on the strength of NavALErrorInfo.ALCreate
///      whose signature reads `bool collectible = false`. There are TWO ALCreate overloads,
///      and the zero-argument one is a different method that sets `ALCollectible = true`
///      outright. Reading one overload and generalising to "the type's default" is what went
///      wrong; the parameterised overload's default applies only when you call it. Identical
///      from 27.0 through 28.4 (compare_symbols: body unchanged), which matches all 8 legs
///      failing the same way. This is now claim 1, asserted in BOTH directions.
///
///   B. [ErrorBehavior(ErrorBehavior::Collect)] MUST WRAP THE RAISER, NOT BE IT. The first
///      revision put the attribute on the method containing Error(), and every collectible
///      error propagated out and failed its test -- the collection scope does not swallow an
///      Error() raised in the attributed method's OWN body. The attribute makes errors from
///      the methods it CALLS collectable. Each collecting helper now calls a separate,
///      unattributed raiser. Ncl.dll shows ALMethodScope.ALStart calling StartCollecting()
///      for the scope, and says nothing about which frame the Error() has to be in -- a
///      question about AL's execution model that only the tier could answer.
///
///   C. A COLLECTING SCOPE RETHROWS WHAT IT COLLECTED WHEN IT EXITS, so GetCollectedErrors()
///      must be read INSIDE the scope. Revision 2 called the collecting helper and then
///      asserted in the caller; all 8 legs failed with the collected message surfacing as an
///      error out of the call. Ncl.dll's ErrorCollection.StopCollecting is explicit once you
///      look at it: on closing the outermost scope it throws NavNCLDialogException with the
///      single collected message, or a "Multiple errors occurred..." summary carrying the
///      first one, and nulls the list on the way out. So by the time a caller regains
///      control the set is gone AND an exception is in flight. Every collection assertion
///      now lives inside the scope, and the callers trap the rethrow -- which turned the
///      rethrow itself into two extra pinned claims (the singular message is verbatim, the
///      plural one is the summary).
///
///      Note what this means about revision 2's correction B: it was necessary but not
///      sufficient. Both facts had to hold at once before any collection test could pass,
///      which is why one round of the tier could not separate them.
///
///   D. HasCollectedErrors() IS ONLY MEANINGFUL INSIDE A COLLECTING SCOPE, and outside one
///      it answers TRUE. Revision 3 asserted it was false at test level once the scope had
///      exited, and that failed on all 8 legs. Ncl.dll's ALHasCollectedErrors computes
///      `0 < (collectedErrors?.Count ?? 0) - currentCollectionScopeStart`, and
///      StopCollecting resets currentCollectionScopeStart to the NoActiveCollectionScope
///      sentinel, -1, on the way out. With no list and no scope that is 0 - (-1) = 1, i.e.
///      TRUE -- an artifact of the arithmetic, not a report that anything is held. So the
///      global is a within-scope predicate, and asking it from outside is a question the
///      API does not define. Both caller-side assertions were removed rather than inverted:
///      pinning "it answers true when nothing is collected" would enshrine the artifact.
///
/// COMPILE-TIME REFUSALS, measured with alc and recorded here because asserterror cannot
/// catch a compile error (so these are NOT tests):
///
///     EI1 = EI2                          error AL0175  (no equality on the type)
///     SomeVariant := EI                  COMPILES, but EI := SomeVariant is AL0122
///     B := EI.AddAction('c', 60352, 'HandleErrorAction')
///                                        error AL0122  (AddAction returns nothing in AL,
///                                        though Ncl.dll's ALAddAction returns Boolean)
///     ErrorInfo.Create('m');             error AL0192  (the return value is mandatory)
///     EI.Callstack('x')                  error AL0126  (Callstack is READ-ONLY)
///     EI.Verbosity().AsInteger()         error AL0132  (no AsInteger on Verbosity)
///     ErrorInfo.Create(..., 'title')     error AL0126  (see below)
///
/// TWO PLACES WHERE Ncl.dll IS AHEAD OF THE AL SURFACE, and the limit of what IL can prove:
///
///   - NavALErrorInfo.ALCreate takes a TENTH parameter, `string title`, and AL does not
///     expose it: the 10-argument call is AL0126, while the 9-argument one compiles. Title
///     is reachable only through the Title() setter.
///   - NavALErrorInfo.AddActionInternal refuses a FOURTH action (`if (actions.Count >= 3)`)
///     and returns false. AL cannot observe that: AddAction's return is not capturable
///     (AL0122 above), and a 4th AddAction call compiles. So the limit is real in the
///     runtime and INVISIBLE from AL -- recorded, deliberately not asserted.
///
/// DELIBERATELY NOT COVERED, and why:
///
///   - AddAction/AddNavigationAction CALLBACK FIRING. The actions are rendered as buttons in
///     the error UI and invoked by a user clicking one; Ncl.dll stores them in a
///     CodeunitFunctionAction list that only the client dispatches. A [Test] has no client,
///     so the callback cannot fire. That the calls BIND and do not throw is covered; that a
///     user pressing them runs the named method is not observable here.
///   - ASSIGNMENT SEMANTICS (EI2 := EI1). FilterPageBuilder answered "split copy" and
///     WebServiceActionContext "shared reference", so the question is a real one, and
///     NavALErrorInfo.Clone() is a genuine deep copy. But Clone() being a deep copy does not
///     establish that AL's := calls Clone at all -- the exact inference that was made from
///     IL and falsified by the tier on TestPart. Left for a follow-up that can put it to a
///     service tier as its own claim rather than smuggling it in here.
/// </summary>

codeunit 60351 "Test ErrorInfo Type"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // ---------------------------------------------------------------- claim 1

    [Test]
    procedure Create_FreshInstance_HasDocumentedDefaults()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create();

        // Verbosity::Error is deliberately asserted: it is NOT the first-declared member of
        // Verbosity, so "the implementation returns the zero enum value" is a different and
        // failing answer.
        Assert.AreEqual('Error', Format(EI.Verbosity()), 'a fresh ErrorInfo must default to Verbosity::Error');
        Assert.AreEqual('CustomerContent', Format(EI.DataClassification()), 'a fresh ErrorInfo must default to DataClassification::CustomerContent');
        // COLLECTIBLE, not false. The zero-argument ErrorInfo.Create() sets collectibility
        // TRUE, the opposite of every other way of making one. See claim 1 in the header.
        Assert.IsTrue(EI.Collectible(), 'the zero-argument ErrorInfo.Create() must produce a COLLECTIBLE ErrorInfo');
        Assert.AreEqual('', EI.Message(), 'a fresh ErrorInfo must have an empty Message');
        Assert.AreEqual('', EI.Title(), 'a fresh ErrorInfo must have an empty Title');
        Assert.AreEqual('', EI.DetailedMessage(), 'a fresh ErrorInfo must have an empty DetailedMessage');
    end;

    [Test]
    procedure Create_WithMessage_SetsMessageAndLeavesOtherDefaults()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('the message');

        Assert.AreEqual('the message', EI.Message(), 'Create(Message) must set the message');
        // The complement: setting the message must not disturb the other defaults.
        Assert.AreEqual('', EI.Title(), 'Create(Message) must leave Title empty');
        // FALSE here, while the ZERO-ARGUMENT Create() above answers TRUE. Asserting both
        // in one file is what makes the asymmetry a pinned claim rather than an accident.
        Assert.IsFalse(EI.Collectible(), 'Create(Message) must leave Collectible false, unlike the zero-argument Create()');
        Assert.AreEqual('Error', Format(EI.Verbosity()), 'Create(Message) must leave Verbosity::Error');
    end;

    // ---------------------------------------------------------------- claim 2

    [Test]
    procedure TextAccessors_RoundTrip_AndAreMutuallyIndependent()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create();

        // Three distinct values, so an implementation backing two of these with one field
        // fails: the last write would be visible through the others.
        EI.Message('MSG-1');
        EI.Title('TITLE-2');
        EI.DetailedMessage('DETAIL-3');
        EI.ControlName('CTRL-4');

        Assert.AreEqual('MSG-1', EI.Message(), 'Message must round-trip');
        Assert.AreEqual('TITLE-2', EI.Title(), 'Title must round-trip and must not be the message');
        Assert.AreEqual('DETAIL-3', EI.DetailedMessage(), 'DetailedMessage must round-trip and must not be the message');
        Assert.AreEqual('CTRL-4', EI.ControlName(), 'ControlName must round-trip and must not be the message');
    end;

    [Test]
    procedure TextAccessors_LastWriteWins()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('first');
        Assert.AreEqual('first', EI.Message(), 'the message must start as the created one');

        EI.Message('second');
        Assert.AreEqual('second', EI.Message(), 'a later Message() write must replace the earlier one');
        Assert.AreNotEqual('first', EI.Message(), 'the replaced message must not survive');
    end;

    [Test]
    procedure EnumAccessors_RoundTrip_AndAreMutuallyIndependent()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create();

        // Every value chosen to DIFFER from the default asserted in claim 1, so an
        // implementation ignoring its argument and answering the default fails.
        EI.Verbosity(Verbosity::Warning);
        EI.DataClassification(DataClassification::SystemMetadata);

        Assert.AreEqual('Warning', Format(EI.Verbosity()), 'Verbosity must round-trip a non-default value');
        Assert.AreEqual('SystemMetadata', Format(EI.DataClassification()), 'DataClassification must round-trip a non-default value');
        // Independence: neither write disturbed the other.
        Assert.AreNotEqual('Error', Format(EI.Verbosity()), 'Verbosity must no longer report the default');
        Assert.AreNotEqual('CustomerContent', Format(EI.DataClassification()), 'DataClassification must no longer report the default');
    end;

    [Test]
    procedure Verbosity_EachMemberRoundTrips()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create();

        // All five members, each asserted by name. An implementation collapsing any two of
        // them onto one stored value fails here and passes every single-value test.
        EI.Verbosity(Verbosity::Critical);
        Assert.AreEqual('Critical', Format(EI.Verbosity()), 'Verbosity::Critical must round-trip');
        EI.Verbosity(Verbosity::Warning);
        Assert.AreEqual('Warning', Format(EI.Verbosity()), 'Verbosity::Warning must round-trip');
        EI.Verbosity(Verbosity::Normal);
        Assert.AreEqual('Normal', Format(EI.Verbosity()), 'Verbosity::Normal must round-trip');
        EI.Verbosity(Verbosity::Verbose);
        Assert.AreEqual('Verbose', Format(EI.Verbosity()), 'Verbosity::Verbose must round-trip');
        EI.Verbosity(Verbosity::Error);
        Assert.AreEqual('Error', Format(EI.Verbosity()), 'Verbosity::Error must round-trip');
    end;

    // ---------------------------------------------------------------- claim 3

    [Test]
    procedure Collectible_RoundTripsInBothDirections()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        // Create(Message) -- NOT the zero-argument Create(), which starts collectible.
        EI := ErrorInfo.Create('m');
        Assert.IsFalse(EI.Collectible(), 'Create(Message) must start non-collectible');

        EI.Collectible(true);
        Assert.IsTrue(EI.Collectible(), 'Collectible(true) must be readable back as true');

        // The half that catches a latch-on-first-write implementation.
        EI.Collectible(false);
        Assert.IsFalse(EI.Collectible(), 'Collectible(false) must clear a previously-set flag');
    end;

    // ---------------------------------------------------------------- claim 4

    [Test]
    procedure Create_CollectibleArgument_DecidesCollectibility()
    var
        Collectible: ErrorInfo;
        NotCollectible: ErrorInfo;
    begin
        Initialize();

        // Same call shape, different argument -- asserted as a PAIR so that an
        // implementation returning a constant fails whichever constant it picks.
        Collectible := ErrorInfo.Create('m', true);
        NotCollectible := ErrorInfo.Create('m', false);

        Assert.IsTrue(Collectible.Collectible(), 'Create(m, true) must produce a collectible ErrorInfo');
        Assert.IsFalse(NotCollectible.Collectible(), 'Create(m, false) must produce a non-collectible ErrorInfo');
        // Both carry the same message, so collectibility is the only thing that differs.
        Assert.AreEqual(Collectible.Message(), NotCollectible.Message(), 'both must carry the same message');
    end;

    // ---------------------------------------------------------------- claim 5

    [Test]
    procedure Create_WithRecord_PopulatesTableIdAndRecordId()
    var
        RowOne: Record "ALT ErrorInfo Row";
        RowTwo: Record "ALT ErrorInfo Row";
        EI: ErrorInfo;
    begin
        Initialize();
        SeedRow(1, 'first');
        SeedRow(2, 'second');
        RowOne.Get(1);
        RowTwo.Get(2);

        EI := ErrorInfo.Create('m', true, RowOne);

        Assert.AreEqual(Database::"ALT ErrorInfo Row", EI.TableId(), 'the record overload must set TableId to the record''s table');
        // Two DIFFERENT rows, so this cannot pass by both sides being the same thing.
        Assert.AreEqual(Format(RowOne.RecordId()), Format(EI.RecordId()), 'the record overload must set RecordId to the row it was given');
        Assert.AreNotEqual(Format(RowTwo.RecordId()), Format(EI.RecordId()), 'the RecordId must not be that of a different row');
    end;

    [Test]
    procedure Create_WithoutRecord_LeavesTableIdZero()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        // The complement of the previous test: no record argument, no table id.
        EI := ErrorInfo.Create('m', true);
        Assert.AreEqual(0, EI.TableId(), 'Create without a record must leave TableId at 0');
    end;

    // ---------------------------------------------------------------- claim 6

    [Test]
    procedure FieldNoAndPageNo_RoundTripIndependently()
    var
        RowOne: Record "ALT ErrorInfo Row";
        EI: ErrorInfo;
    begin
        Initialize();
        SeedRow(1, 'first');
        RowOne.Get(1);

        // Payload is FIELD 2 of the fixture table, deliberately not field 1, so an
        // implementation answering a hardcoded 1 fails.
        EI := ErrorInfo.Create('m', true, RowOne, RowOne.FieldNo(Payload));
        Assert.AreEqual(RowOne.FieldNo(Payload), EI.FieldNo(), 'the record overload must set FieldNo from its argument');
        Assert.AreEqual(2, EI.FieldNo(), 'Payload is field 2 of the fixture table');
        Assert.AreEqual(0, EI.PageNo(), 'PageNo must stay 0 when it was not supplied');

        // Independence: writing PageNo must not disturb FieldNo.
        EI.PageNo(42);
        Assert.AreEqual(42, EI.PageNo(), 'PageNo must round-trip');
        Assert.AreEqual(2, EI.FieldNo(), 'writing PageNo must not disturb FieldNo');

        EI.FieldNo(7);
        Assert.AreEqual(7, EI.FieldNo(), 'FieldNo must round-trip');
        Assert.AreEqual(42, EI.PageNo(), 'writing FieldNo must not disturb PageNo');
    end;

    // ---------------------------------------------------------------- claim 7

    [Test]
    procedure CustomDimensions_FreshIsEmpty_AndRoundTripsAssignedEntries()
    var
        EI: ErrorInfo;
        Dims: Dictionary of [Text, Text];
        ReadBack: Dictionary of [Text, Text];
    begin
        Initialize();
        EI := ErrorInfo.Create();
        // Half one: empty by default.
        Assert.AreEqual(0, EI.CustomDimensions().Count(), 'a fresh ErrorInfo must carry no custom dimensions');

        Dims.Add('alpha', 'one');
        Dims.Add('beta', 'two');
        EI.CustomDimensions(Dims);

        ReadBack := EI.CustomDimensions();
        // Half two: the assigned entries come back, by key and by value.
        Assert.AreEqual(2, ReadBack.Count(), 'CustomDimensions must round-trip both entries');
        Assert.AreEqual('one', ReadBack.Get('alpha'), 'CustomDimensions must round-trip the first value');
        Assert.AreEqual('two', ReadBack.Get('beta'), 'CustomDimensions must round-trip the second value');
    end;

    // ---------------------------------------------------------------- claims 8-12

    [Test]
    procedure CollectibleError_UnderCollectScope_DoesNotAbortCaller()
    begin
        Initialize();
        ClearCollectedErrors();

        // The scope RETHROWS on exit (see finding C in the header), so the assertions live
        // inside it and the caller traps the rethrow. What is proved here is that execution
        // CONTINUED past the failed call inside the scope: the helper sets a flag after the
        // raiser returns and asserts it, which an implementation that let the error unwind
        // could never reach.
        asserterror CollectAndAssertCallerNotAborted('collected message');
        // The rethrown message is the collected one -- itself a claim about StopCollecting.
        Assert.ExpectedError('collected message');
    end;

    [Test]
    procedure CollectibleError_IsCollectedWithItsMessage()
    begin
        Initialize();
        ClearCollectedErrors();

        asserterror CollectAndAssertOneWithMessage('the collected message');
        Assert.ExpectedError('the collected message');
    end;

    [Test]
    procedure NonCollectibleError_InCollectScope_IsNotCollected()
    begin
        Initialize();
        ClearCollectedErrors();

        // The complement, and the discriminating half of the pair: Ncl.dll's
        // ErrorCollection.Collect returns false unless error.ALCollectible, so an
        // implementation that collected everything passes the two tests above and fails
        // this one. A non-collectible error unwinds immediately, so the scope never reaches
        // its own assertions -- which is exactly why the message trapped here is the
        // RAISER's, not a scope-exit rethrow.
        asserterror CollectNonCollectible('not collectible');
        Assert.ExpectedError('not collectible');
        // No HasCollectedErrors() assertion here: OUTSIDE a collecting scope that global is
        // not a meaningful question -- see finding D in the header. The proof that nothing
        // was collected is the Assert.Fail() inside the scope that is never reached, plus
        // the trapped message being the raiser's own rather than a scope-exit rethrow.
    end;

    [Test]
    procedure CollectedErrors_AccumulateInRaiseOrder()
    begin
        Initialize();
        ClearCollectedErrors();

        asserterror CollectTwoAndAssertOrder('first raised', 'second raised');
        // Two collected errors make StopCollecting throw the MULTIPLE-errors message, whose
        // text leads with the first one. That the singular case above reports the message
        // verbatim and this one does not is itself a pinned difference.
        Assert.ExpectedError('first raised');
    end;

    [Test]
    procedure ClearCollectedErrors_EmptiesTheSetInsideTheScope()
    begin
        Initialize();
        ClearCollectedErrors();

        // Clearing INSIDE the scope also disarms the scope-exit rethrow -- there is nothing
        // left to throw -- so this helper returns normally and needs no asserterror. That is
        // the sharpest available proof that the clear really emptied the set.
        // Returning normally at all IS the claim: had the clear not emptied the set, the
        // scope would have rethrown on exit and this call would have raised. The assertions
        // that the set is empty live inside the scope, where the question is meaningful.
        ClearInsideScopeAndAssertEmpty('to be cleared');
    end;

    // ---------------------------------------------------------------- claim 13

    [Test]
    procedure AddAction_WithRealTarget_NoThrow_AndLeavesStateIntact()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('an error', true);
        EI.Title('a title');

        // A REAL codeunit and a REAL global method taking one ErrorInfo -- not a made-up id.
        // The callback itself cannot fire without a client (see the header note), so the
        // claim is limited to: this binds, it does not throw, and it does not disturb the
        // object it was called on.
        EI.AddAction('Fix it', Codeunit::"ALT ErrorInfo Action Sink", 'HandleErrorAction');

        Assert.AreEqual('an error', EI.Message(), 'AddAction must leave the message intact');
        Assert.AreEqual('a title', EI.Title(), 'AddAction must leave the title intact');
        Assert.IsTrue(EI.Collectible(), 'AddAction must leave collectibility intact');
    end;

    [Test]
    procedure AddNavigationAction_NoThrow_AndLeavesStateIntact()
    var
        EI: ErrorInfo;
    begin
        Initialize();
        EI := ErrorInfo.Create('an error', true);
        EI.Title('a title');

        EI.AddNavigationAction('Show me');

        Assert.AreEqual('an error', EI.Message(), 'AddNavigationAction must leave the message intact');
        Assert.AreEqual('a title', EI.Title(), 'AddNavigationAction must leave the title intact');
        Assert.IsTrue(EI.Collectible(), 'AddNavigationAction must leave collectibility intact');
    end;

    // ---------------------------------------------------------------- helpers

    // THE COLLECTING SCOPE IS WHERE THE ASSERTIONS HAVE TO LIVE. Two facts, both settled
    // by the tier, force this shape:
    //   - The attribute must WRAP the raiser, not be it: [ErrorBehavior(Collect)] makes
    //     errors from the methods it CALLS collectable, and does not swallow an Error() in
    //     its own body. So each helper below calls a separate, unattributed raiser.
    //   - The scope RETHROWS whatever it collected when it exits (Ncl.dll:
    //     ErrorCollection.StopCollecting throws NavNCLDialogException with the single
    //     message, or the "Multiple errors occurred" summary for more than one). So
    //     GetCollectedErrors() has to be read INSIDE the scope; by the time the caller
    //     regains control the set is gone and an exception is in flight.
    // Assertions that fail inside a collecting scope surface through that rethrow, so a
    // broken claim still fails the test rather than being swallowed.

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectAndAssertCallerNotAborted(Message: Text)
    var
        Reached: Boolean;
    begin
        Reached := false;
        RaiseCollectible(Message);
        // Reaching this line at all IS the claim.
        Reached := true;
        Assert.IsTrue(Reached, 'execution must continue past a collected error inside the scope');
        Assert.IsTrue(HasCollectedErrors(), 'HasCollectedErrors must report true inside the scope');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectAndAssertOneWithMessage(Message: Text)
    var
        Errors: List of [ErrorInfo];
    begin
        RaiseCollectible(Message);
        Errors := GetCollectedErrors();
        // Exactly one -- not merely "not empty".
        Assert.AreEqual(1, Errors.Count(), 'exactly one error must have been collected');
        Assert.AreEqual(Message, Errors.Get(1).Message(), 'the collected error must carry the message it was raised with');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectTwoAndAssertOrder(FirstMessage: Text; SecondMessage: Text)
    var
        Errors: List of [ErrorInfo];
    begin
        // Two separate calls: the first is collected and execution continues into the
        // second, which is the whole point of a collecting scope.
        RaiseCollectible(FirstMessage);
        RaiseCollectible(SecondMessage);
        Errors := GetCollectedErrors();
        Assert.AreEqual(2, Errors.Count(), 'both collectible errors must be collected');
        // By position, with different messages -- so keeping only the first, only the last,
        // or reversing the order all fail.
        Assert.AreEqual(FirstMessage, Errors.Get(1).Message(), 'the first raised error must be first in the collected set');
        Assert.AreEqual(SecondMessage, Errors.Get(2).Message(), 'the second raised error must be second in the collected set');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure CollectNonCollectible(Message: Text)
    begin
        // Unwinds immediately, so nothing after this line runs.
        RaiseNonCollectible(Message);
        Assert.Fail('a non-collectible error must not be collected; the scope should never reach this line');
    end;

    [ErrorBehavior(ErrorBehavior::Collect)]
    local procedure ClearInsideScopeAndAssertEmpty(Message: Text)
    var
        Errors: List of [ErrorInfo];
    begin
        RaiseCollectible(Message);
        Assert.IsTrue(HasCollectedErrors(), 'the error must be held before clearing');
        Assert.AreEqual(1, GetCollectedErrors().Count(), 'exactly one error must be held before clearing');

        ClearCollectedErrors();

        // Both directions of the same flag, so an implementation hardcoding either fails.
        Assert.IsFalse(HasCollectedErrors(), 'HasCollectedErrors must report false after clearing');
        Errors := GetCollectedErrors();
        Assert.AreEqual(0, Errors.Count(), 'the collected set must be empty after clearing');
    end;

    // The actual raisers, deliberately WITHOUT the attribute.
    local procedure RaiseCollectible(Message: Text)
    var
        EI: ErrorInfo;
    begin
        EI := ErrorInfo.Create(Message, true);
        Error(EI);
    end;

    local procedure RaiseNonCollectible(Message: Text)
    var
        EI: ErrorInfo;
    begin
        // Create(Message, false) is used rather than Create(), because Create() produces a
        // COLLECTIBLE ErrorInfo -- see claim 1.
        EI := ErrorInfo.Create(Message, false);
        Error(EI);
    end;

    local procedure SeedRow(EntryNo: Integer; Payload: Text[50])
    var
        Row: Record "ALT ErrorInfo Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Payload := Payload;
        Row.Insert(true);
    end;

    local procedure Initialize()
    var
        Row: Record "ALT ErrorInfo Row";
    begin
        ClearLastError();
        Row.DeleteAll(false);
    end;
}
