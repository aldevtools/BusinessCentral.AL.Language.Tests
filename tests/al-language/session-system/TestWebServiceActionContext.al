// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/webserviceactioncontext/webserviceactioncontext-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: none; shared Assert (60021)
// BC versions: 27.0+ (WebServiceActionContext is runtime 2.0; every version in this matrix has it)
//
/// <summary>
/// CLAIM: WebServiceActionContext is a mutable in-memory value object that an API page action
/// fills in to tell the OData layer what it did -- which object to redirect to, which entity
/// row, and what HTTP status to report. Its whole 7-method surface is get/set pairs plus one
/// collection-add, so ALL of it is observable from a plain [Test] with no web service request
/// in flight. The type is what an action WRITES; a web service client is only what eventually
/// READS it, and nothing in the write path needs a client attached.
///
/// Nothing in this repository measured any part of WebServiceActionContext before this file.
/// docs/al-language-coverage-gaps.md lists it under gap #5 as "no test file at all; the least-
/// covered remaining candidate", and searching the suite for the type name finds only that doc
/// and the scraper scripts. Note that scripts/al-surface-inscope.json labels all 7 members
/// "out-of-scope" -- that label is wrong in the same way it was wrong for SecretText (now a
/// merged suite) and SessionSettings (now 31 passing tests): it classifies by the type's NAME
/// rather than by what the members actually do.
///
/// WHAT IS PINNED HERE, and what each test would catch if it broke:
///
///   1. ROUND-TRIPPING, WITH DISTINCTIVE VALUES. SetObjectId/GetObjectId and
///      SetObjectType/GetObjectType read back exactly what was written. Every value asserted
///      here is deliberately NOT the type's default -- never object id 0, never the unnamed
///      zero-valued object type -- so an implementation that ignores its argument and returns
///      a default fails rather than passing by coincidence.
///   2. THE PROPERTIES ARE INDEPENDENT, AND LAST-WRITE-WINS. Setting the object type must not
///      disturb the object id and vice versa; a second write to either must replace the first.
///      An implementation backing both with one field, or accepting only a first value, fails.
///   3. THE RESULT-CODE ROUND TRIP IS LOSSY, AND THIS IS THE REASON THE FILE IS WORTH HAVING.
///      GetResultCode() does NOT always return the member that was passed to SetResultCode().
///      WebServiceActionResultCode declares FIVE members over FOUR distinct values --
///      None = 0, Get = 200, Created = 201, Updated = 200, Deleted = 204 -- so Get and Updated
///      are the SAME underlying value. The platform stores the code by converting the name to
///      a second, separately-declared enum and reads it back by converting the name again, so
///      the pair collapses onto whichever name is declared first. Setting Updated therefore
///      reads back as Get. Tests below assert BOTH directions of that collision: the three
///      unambiguous members survive the round trip unchanged, and Updated does not. An
///      implementation that stored the AL enum member verbatim -- the obvious and otherwise
///      indistinguishable implementation -- passes every other test in this file and fails
///      exactly this one. All of it is asserted through Format(), which is not a stylistic
///      choice; see the CS1503 note below for why it is the only option available.
///   4. AddEntityKey OBEYS THE TRAPPABLE-RETURN CONVENTION IN BOTH DIRECTIONS. Adding a key
///      for a field id already present is an error, because the keys are a map keyed by field
///      id rather than a list. Like Record.Insert and its siblings, the method reports that
///      failure two different ways depending on whether the caller captures the return value:
///      captured, it returns false; not captured, it raises a catchable error naming the type.
///      Both are asserted, so an implementation that always throws, always returns true, or
///      silently overwrites the existing key fails.
///   5. Clear() RESETS THE WHOLE INSTANCE. Clear() replaces the underlying context, so the
///      object id, the object type and the result code all return to their defaults AND the
///      entity keys are emptied -- the last of which is asserted indirectly, by re-adding a
///      field id that had already been used and observing that it now succeeds. An
///      implementation that reset only the scalar properties fails that one.
///   6. ASSIGNMENT COPIES THE REFERENCE, NOT THE VALUE. This is the second surprise, and it is
///      the OPPOSITE of SessionSettings, where `A := B` deep-copies. Two AL variables assigned
///      from one another share a single underlying context, so mutating one is visible through
///      the other. Asserted explicitly rather than assumed, since the intuition carried over
///      from SessionSettings is wrong here.
///
/// DEFAULTS ARE PINNED SEPARATELY, and deliberately: a fresh instance reports object id 0,
/// WebServiceActionResultCode::None, and an object type that is none of the seven members AL
/// can name. Those assertions are what make the round-trip tests above meaningful -- they
/// establish that the values the other tests assert are genuinely different from what an
/// untouched instance answers, so none of those tests can pass by coincidence.
///
/// THE COMPILE-TIME SURFACE WAS MEASURED with the AL compiler (v17.0.34.45391) against this
/// app's Cloud target, and two refusals are worth writing down because they shape the tests:
///
///     if C1 = C2 then                error AL0175: operator '=' cannot be applied to operands
///                                    of type 'WebServiceActionContext' and
///                                    'WebServiceActionContext'
///     if R1 = R2 then                error AL0175: the same, for two operands of type
///                                    'WebServiceActionResultCode'
///     I := ResultCode.AsInteger();   error AL0132: 'WebServiceActionResultCode' does not
///                                    contain a definition for 'AsInteger'. It is a platform
///                                    enum, not an AL enum object, so the AsInteger/AsEnum
///                                    pair does not exist on it and its numeric value cannot
///                                    be read from AL at all. This is why test 3 pins the
///                                    Get/Updated collision by NAME rather than by comparing
///                                    200 to 200, which would prove nothing anyway.
///     V := Ctx;  T := Format(Ctx);   BOTH COMPILE -- unlike SecretText, the CONTEXT converts
///                                    to Variant. But Format(Ctx) returns '' on real BC, so
///                                    compiling is not the same as being readable; see the
///                                    MEASURED note below. And this holds for the context, NOT
///                                    for the result code: see the CS1503 note, where the
///                                    compiler agrees and the server does not.
///     Ctx := SomeVariant;            error AL0122: Cannot implicitly convert type 'Variant'
///                                    to 'WebServiceActionContext'. The Variant conversion is
///                                    ONE-DIRECTIONAL -- in, not out.
///     Clear(Ctx);                    COMPILES.
///
/// A RESULT CODE CANNOT BE PASSED TO A Variant PARAMETER ON A REAL SERVER, AND THE AL COMPILER
/// DOES NOT CATCH IT. This is the most important thing measured here, it was found only by
/// running against a service tier, and it dictates how every result-code assertion below is
/// written.
///
/// `Assert.AreEqual(WebServiceActionResultCode::Created, Ctx.GetResultCode(), '...')` COMPILES
/// CLEANLY -- Assert's parameters are Variant, and alc raises nothing. On a real BC server the
/// codeunit then fails to LOAD, because the server generates C# for each application object at
/// deployment time and that generated C# does not compile:
///
///     error CS1503: Argument 2: cannot convert from
///     'Microsoft.Dynamics.Nav.Runtime.WebServiceActionResultCode' to
///     'Microsoft.Dynamics.Nav.Runtime.NavValue'
///
/// NavValue is the runtime's boxed-value base class -- what a Variant parameter takes -- and
/// WebServiceActionResultCode has no NavValue wrapper on the argument path, unlike ObjectType
/// (which boxes fine and is asserted directly throughout this file). The failure is per-object
/// and total: the first version of this file produced 71 instances of that one error, BC
/// reported "C# compilation has failed for the application object CodeUnit_60278" plus
/// "CLR type load failed", and NONE of the 33 tests ran on ANY of the 16 legs -- while all
/// 2639 other tests in the app passed. A whole codeunit disappears, silently as far as AL is
/// concerned, from one expression the compiler accepted.
///
/// So every assertion here compares Format(...) of a result code, never the code itself. That
/// is not a workaround for a test-harness limitation -- it is the only way an AL author can
/// compare two result codes at all, given that `=` is AL0175, AsInteger() is AL0132, and the
/// Variant path does not survive deployment. Worth knowing before writing any AL that handles
/// this type.
///
/// Because `=` is refused on both types, there is no compile-time-refusal test in this file:
/// a refusal is a compiler diagnostic, not a runtime error, so `asserterror` has nothing to
/// catch and a test asserting it could never fail. The refusals are recorded above instead of
/// being fabricated into tests, following network/TestHttpClientBlockNoHandler.al.
///
/// A CONTEXT HAS AN EMPTY TEXT REPRESENTATION. Measured on real BC, and it falsified an
/// assertion in the first revision of this file. `Format(Ctx)` compiles and returns '' -- even
/// with an object id assigned beforehand. The runtime type NavWebServiceActionContext carries
/// no ToString override (it reports GetBytesSize 0 and IsZeroOrEmpty false), so there is
/// nothing for Format to render. The draft had asserted the opposite from the plain intuition
/// that a populated object formats to something, and all 8 cloud legs disagreed. Useful to
/// know before writing AL: logging a context tells you nothing, and reading its state means
/// calling the getters.
///
/// THE DEFAULT OBJECT TYPE CANNOT BE NAMED IN AL, and this shaped two tests. AL's ObjectType
/// exposes exactly SEVEN members -- Table, Page, Report, Codeunit, XmlPort, Query, MenuSuite
/// (measured: every other spelling tried, including TableData, Enum, Interface, PermissionSet,
/// ControlAddIn, PageExtension and None, is error AL0132). The platform enum behind it is
/// NavObjectType, which starts at TableData = 0 and also carries Form = 2 and Enum = 10 --
/// values AL has no expression for. A pristine context's object type is that unnamed zero, so
/// no assertion here can say what it IS. Two tests state it the way it can honestly be stated:
/// a fresh context differs from all seven assignable members, and Clear() returns the type to
/// whatever a second, never-touched context reports. Both are relative claims, in the same
/// spirit as the Init()/Company handling in session/TestSessionSettings.al, and both still
/// fail against an implementation that defaulted to a nameable member or ignored Clear.
///
/// DELIBERATELY NOT TESTED: the OData/web-service side of the contract -- that a real API page
/// action returning this context actually makes the platform emit HTTP 201 and a redirect to
/// the named entity. That needs a web service request against a published API page, which is
/// outside what a [Test] codeunit can provoke and outside this repository's Cloud-safe runtime
/// focus. Everything asserted here is the AL-observable half: what the action writes, which is
/// the half AL code is responsible for.
///
/// SIDE EFFECTS: none. Every test operates on a local WebServiceActionContext variable that
/// lives and dies inside the test method. Nothing is written to the tenant, so these tests are
/// order-independent and safe to run alongside the rest of the suite.
/// </summary>
codeunit 60278 "Test WebServiceActionContext"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;

    // ---------------------------------------------------------------------------------------
    // Defaults. These make every round-trip assertion below meaningful, by establishing that
    // the values those tests assert differ from what an untouched instance answers.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_FreshInstance_HasZeroObjectId()
    var
        Ctx: WebServiceActionContext;
    begin
        Assert.AreEqual(0, Ctx.GetObjectId(), 'A fresh WebServiceActionContext must report object id 0');
    end;

    [Test]
    procedure WSAC_FreshInstance_ObjectTypeIsNotAnyAssignableMember()
    var
        Ctx: WebServiceActionContext;
    begin
        // The default object type CANNOT BE NAMED IN AL, so this is asserted negatively rather
        // than against a member. AL's ObjectType offers exactly seven members -- Table, Page,
        // Report, Codeunit, XmlPort, Query, MenuSuite -- while the platform enum behind it
        // starts at TableData = 0, which AL does not expose. A fresh context therefore reports
        // a value that no ObjectType:: expression can name, and the honest claim is that it
        // differs from every member that CAN be assigned. That is still a proving assertion:
        // an implementation defaulting to any assignable member fails, and so does one whose
        // getter returned a fixed member regardless of state.
        Assert.AreNotEqual(ObjectType::Table, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::Table');
        Assert.AreNotEqual(ObjectType::Page, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::Page');
        Assert.AreNotEqual(ObjectType::Report, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::Report');
        Assert.AreNotEqual(ObjectType::Codeunit, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::Codeunit');
        Assert.AreNotEqual(ObjectType::XmlPort, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::XmlPort');
        Assert.AreNotEqual(ObjectType::Query, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::Query');
        Assert.AreNotEqual(ObjectType::MenuSuite, Ctx.GetObjectType(), 'A fresh context must not report ObjectType::MenuSuite');
    end;

    [Test]
    procedure WSAC_FreshInstance_HasNoneResultCode()
    var
        Ctx: WebServiceActionContext;
    begin
        Assert.AreEqual(
            'None',
            Format(Ctx.GetResultCode()),
            'A fresh WebServiceActionContext must report WebServiceActionResultCode::None');
    end;

    // ---------------------------------------------------------------------------------------
    // 1 + 2. Round-tripping, independence, and last-write-wins.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_ObjectId_RoundTripsAssignedValue()
    var
        Ctx: WebServiceActionContext;
    begin
        // 50123 is deliberately not 0 and not any id this app declares, so returning either a
        // default or some ambient "current object" is a detectable failure.
        Ctx.SetObjectId(50123);

        Assert.AreEqual(50123, Ctx.GetObjectId(), 'GetObjectId must read back the object id that was assigned');
    end;

    [Test]
    procedure WSAC_ObjectId_LastAssignmentWins()
    var
        Ctx: WebServiceActionContext;
    begin
        // An accessor that only accepts its first value passes the test above and fails this
        // one.
        Ctx.SetObjectId(50123);
        Ctx.SetObjectId(50124);

        Assert.AreEqual(50124, Ctx.GetObjectId(), 'A second SetObjectId must replace the first');
    end;

    [Test]
    procedure WSAC_ObjectId_AcceptsNegativeValue()
    var
        Ctx: WebServiceActionContext;
    begin
        // The setter is a plain assignment to an Integer, with no validation that the id names
        // a real object -- validation happens when the OData layer resolves it, not here. An
        // implementation that clamped or rejected out-of-range ids would fail.
        Ctx.SetObjectId(-7);

        Assert.AreEqual(-7, Ctx.GetObjectId(), 'SetObjectId must store a negative id unchanged, without validating it');
    end;

    [Test]
    procedure WSAC_ObjectType_RoundTripsAssignedValue()
    var
        Ctx: WebServiceActionContext;
    begin
        Ctx.SetObjectType(ObjectType::Page);

        Assert.AreEqual(ObjectType::Page, Ctx.GetObjectType(), 'GetObjectType must read back the object type that was assigned');
    end;

    [Test]
    procedure WSAC_ObjectType_LastAssignmentWins()
    var
        Ctx: WebServiceActionContext;
    begin
        Ctx.SetObjectType(ObjectType::Report);
        Ctx.SetObjectType(ObjectType::Page);

        Assert.AreEqual(ObjectType::Page, Ctx.GetObjectType(), 'A second SetObjectType must replace the first');
    end;

    [Test]
    procedure WSAC_ObjectIdAndObjectType_AreIndependentProperties()
    var
        Ctx: WebServiceActionContext;
    begin
        // Backing both with a single field, or having one setter reset the other, makes
        // exactly one of these two assertions fail.
        Ctx.SetObjectId(50123);
        Ctx.SetObjectType(ObjectType::Codeunit);

        Assert.AreEqual(50123, Ctx.GetObjectId(), 'The object id must survive a later SetObjectType');
        Assert.AreEqual(ObjectType::Codeunit, Ctx.GetObjectType(), 'The object type must survive an earlier SetObjectId');
    end;

    [Test]
    procedure WSAC_ResultCode_IsIndependentOfObjectIdAndType()
    var
        Ctx: WebServiceActionContext;
    begin
        // All three scalar properties set at once, all three asserted. Created is used rather
        // than Updated because Created has an unambiguous value -- see the collision tests
        // below for why that distinction matters.
        Ctx.SetObjectId(50123);
        Ctx.SetObjectType(ObjectType::Page);
        Ctx.SetResultCode(WebServiceActionResultCode::Created);

        Assert.AreEqual(50123, Ctx.GetObjectId(), 'The object id must survive setting the result code');
        Assert.AreEqual(ObjectType::Page, Ctx.GetObjectType(), 'The object type must survive setting the result code');
        Assert.AreEqual(
            'Created', Format(Ctx.GetResultCode()), 'The result code must survive setting the id and type');
    end;

    // ---------------------------------------------------------------------------------------
    // 3. The result-code round trip, and the Get/Updated collision.
    //
    // WebServiceActionResultCode declares five members over four distinct values:
    //     None = 0, Get = 200, Created = 201, Updated = 200, Deleted = 204
    // The three members with unique values survive the round trip. Get and Updated share the
    // value 200, and the pair collapses onto Get. Both directions are asserted.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_ResultCode_RoundTripsCreated()
    var
        Ctx: WebServiceActionContext;
    begin
        Ctx.SetResultCode(WebServiceActionResultCode::Created);

        Assert.AreEqual(
            'Created', Format(Ctx.GetResultCode()), 'GetResultCode must read back Created unchanged');
    end;

    [Test]
    procedure WSAC_ResultCode_RoundTripsDeleted()
    var
        Ctx: WebServiceActionContext;
    begin
        Ctx.SetResultCode(WebServiceActionResultCode::Deleted);

        Assert.AreEqual(
            'Deleted', Format(Ctx.GetResultCode()), 'GetResultCode must read back Deleted unchanged');
    end;

    [Test]
    procedure WSAC_ResultCode_RoundTripsGet()
    var
        Ctx: WebServiceActionContext;
    begin
        // Get is the FIRST-declared of the two members valued 200, so it is the one that
        // survives its own round trip. Paired with the Updated test below, this rules out an
        // implementation that simply collapses everything onto one member.
        Ctx.SetResultCode(WebServiceActionResultCode::Get);

        Assert.AreEqual('Get', Format(Ctx.GetResultCode()), 'GetResultCode must read back Get unchanged');
    end;

    [Test]
    procedure WSAC_ResultCode_RoundTripsBackToNoneWhenSetToNone()
    var
        Ctx: WebServiceActionContext;
    begin
        // Set to something else first, so this cannot pass merely because None is the default.
        Ctx.SetResultCode(WebServiceActionResultCode::Created);
        Ctx.SetResultCode(WebServiceActionResultCode::None);

        Assert.AreEqual(
            'None', Format(Ctx.GetResultCode()), 'SetResultCode(None) must overwrite a previously set code');
    end;

    [Test]
    procedure WSAC_ResultCode_UpdatedReadsBackAsGet()
    var
        Ctx: WebServiceActionContext;
    begin
        // THE DISCRIMINATOR. Updated and Get are both valued 200, and the platform stores the
        // code by NAME into a second enum and reads it back by name, so the value 200 resolves
        // to the first-declared name -- Get. An implementation that stored the AL enum member
        // verbatim would return Updated here and pass every other test in this file.
        Ctx.SetResultCode(WebServiceActionResultCode::Updated);

        Assert.AreEqual(
            'Get',
            Format(Ctx.GetResultCode()),
            'SetResultCode(Updated) must read back as Get -- both are valued 200 and the pair collapses onto Get');
    end;

    [Test]
    procedure WSAC_ResultCode_UpdatedIsNotDistinguishableFromGet()
    var
        CtxFromGet: WebServiceActionContext;
        CtxFromUpdated: WebServiceActionContext;
    begin
        // The same collision stated as an equivalence between two independent instances, so it
        // does not depend on the assertion above happening to name Get. Setting Get on one and
        // Updated on the other leaves the two contexts reporting the SAME result code.
        CtxFromGet.SetResultCode(WebServiceActionResultCode::Get);
        CtxFromUpdated.SetResultCode(WebServiceActionResultCode::Updated);

        Assert.AreEqual(
            Format(CtxFromGet.GetResultCode()),
            Format(CtxFromUpdated.GetResultCode()),
            'Get and Updated share the value 200, so two contexts set from them must report the same result code');
    end;

    [Test]
    procedure WSAC_ResultCode_CreatedAndDeletedRemainDistinct()
    var
        CtxCreated: WebServiceActionContext;
        CtxDeleted: WebServiceActionContext;
    begin
        // The negative half of the collision claim: only the 200-valued pair collapses. If an
        // implementation collapsed ALL members onto one value -- which would make the Updated
        // test above pass for the wrong reason -- this test fails.
        CtxCreated.SetResultCode(WebServiceActionResultCode::Created);
        CtxDeleted.SetResultCode(WebServiceActionResultCode::Deleted);

        Assert.AreNotEqual(
            Format(CtxCreated.GetResultCode()),
            Format(CtxDeleted.GetResultCode()),
            'Created and Deleted have distinct values and must remain distinguishable');
    end;

    // ---------------------------------------------------------------------------------------
    // 4. AddEntityKey, and the trappable-return convention.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_AddEntityKey_ReturnsTrueForNewFieldId()
    var
        Ctx: WebServiceActionContext;
        Added: Boolean;
    begin
        Added := Ctx.AddEntityKey(1, 'ALT-KEY-VALUE');

        Assert.IsTrue(Added, 'AddEntityKey must return true when the field id is not already present');
    end;

    [Test]
    procedure WSAC_AddEntityKey_AcceptsSeveralDistinctFieldIds()
    var
        Ctx: WebServiceActionContext;
    begin
        // Distinct field ids are independent map entries, so each add succeeds. An
        // implementation holding only one key would fail on the second or third.
        Assert.IsTrue(Ctx.AddEntityKey(1, 'first'), 'AddEntityKey must accept field id 1');
        Assert.IsTrue(Ctx.AddEntityKey(2, 'second'), 'AddEntityKey must accept field id 2 after field id 1');
        Assert.IsTrue(Ctx.AddEntityKey(3, 'third'), 'AddEntityKey must accept field id 3 after field ids 1 and 2');
    end;

    [Test]
    procedure WSAC_AddEntityKey_AcceptsValuesOfDifferentTypes()
    var
        Ctx: WebServiceActionContext;
        KeyGuid: Guid;
    begin
        // The value parameter is declared Any, so the key value is not restricted to Text. All
        // four adds use distinct field ids, so each must succeed on its own merits.
        KeyGuid := CreateGuid();

        Assert.IsTrue(Ctx.AddEntityKey(1, 'a text value'), 'AddEntityKey must accept a Text value');
        Assert.IsTrue(Ctx.AddEntityKey(2, 42), 'AddEntityKey must accept an Integer value');
        Assert.IsTrue(Ctx.AddEntityKey(3, KeyGuid), 'AddEntityKey must accept a Guid value');
        Assert.IsTrue(Ctx.AddEntityKey(4, Today()), 'AddEntityKey must accept a Date value');
    end;

    [Test]
    procedure WSAC_AddEntityKey_ReturnsFalseForDuplicateFieldIdWhenReturnValueCaptured()
    var
        Ctx: WebServiceActionContext;
        AddedAgain: Boolean;
    begin
        // The entity keys are a map keyed by field id, not a list, so re-adding a field id is
        // a failure rather than an append or an overwrite. With the return value CAPTURED the
        // platform traps the error and reports false, exactly as Record.Insert does.
        Assert.IsTrue(Ctx.AddEntityKey(1, 'first value'), 'The first add of field id 1 must succeed');

        AddedAgain := Ctx.AddEntityKey(1, 'second value');

        Assert.IsFalse(AddedAgain, 'A second AddEntityKey for the same field id must return false, not overwrite the first');
    end;

    [Test]
    procedure WSAC_AddEntityKey_DuplicateFieldIdIsDetectedRegardlessOfValue()
    var
        Ctx: WebServiceActionContext;
        AddedAgain: Boolean;
    begin
        // The duplicate is detected on the FIELD ID alone. Re-adding the same id with the
        // identical value still fails, so an implementation that only rejected a differing
        // value -- treating a repeat of the same pair as idempotent -- fails here.
        Assert.IsTrue(Ctx.AddEntityKey(7, 'same value'), 'The first add of field id 7 must succeed');

        AddedAgain := Ctx.AddEntityKey(7, 'same value');

        Assert.IsFalse(AddedAgain, 'Re-adding a field id with an identical value must still return false');
    end;

    [Test]
    procedure WSAC_AddEntityKey_RaisesErrorForDuplicateFieldIdWhenReturnValueNotCaptured()
    var
        Ctx: WebServiceActionContext;
    begin
        // The other half of the trappable-return convention: with the return value DISCARDED
        // the same duplicate raises a catchable error instead of being reported as false. The
        // error names the type, which is what is asserted -- an implementation that threw some
        // unrelated error, or that did not throw at all, fails.
        Assert.IsTrue(Ctx.AddEntityKey(1, 'first value'), 'The first add of field id 1 must succeed');

        asserterror Ctx.AddEntityKey(1, 'second value');

        Assert.ExpectedError('WebServiceActionContext');
    end;

    [Test]
    procedure WSAC_AddEntityKey_DoesNotDisturbTheScalarProperties()
    var
        Ctx: WebServiceActionContext;
    begin
        // The entity keys and the three scalar properties live on the same underlying context.
        // Adding a key must not reset any of them.
        Ctx.SetObjectId(50123);
        Ctx.SetObjectType(ObjectType::Page);
        Ctx.SetResultCode(WebServiceActionResultCode::Created);

        Assert.IsTrue(Ctx.AddEntityKey(1, 'ALT-KEY-VALUE'), 'AddEntityKey must succeed for a new field id');

        Assert.AreEqual(50123, Ctx.GetObjectId(), 'AddEntityKey must not disturb the object id');
        Assert.AreEqual(ObjectType::Page, Ctx.GetObjectType(), 'AddEntityKey must not disturb the object type');
        Assert.AreEqual(
            'Created', Format(Ctx.GetResultCode()), 'AddEntityKey must not disturb the result code');
    end;

    [Test]
    procedure WSAC_AddEntityKey_FailedDuplicateLeavesEarlierKeysIntact()
    var
        Ctx: WebServiceActionContext;
    begin
        // A rejected duplicate must not damage the keys already collected. Field id 2 is added
        // AFTER the failed duplicate of field id 1, and must still succeed -- so the failure
        // neither emptied the map nor left it in a state that rejects further adds.
        Assert.IsTrue(Ctx.AddEntityKey(1, 'first value'), 'The first add of field id 1 must succeed');
        Assert.IsFalse(Ctx.AddEntityKey(1, 'duplicate'), 'The duplicate add of field id 1 must return false');

        Assert.IsTrue(Ctx.AddEntityKey(2, 'second value'), 'A new field id must still be accepted after a failed duplicate');
        Assert.IsFalse(Ctx.AddEntityKey(1, 'another duplicate'), 'Field id 1 must still be present after the failed duplicate');
    end;

    // ---------------------------------------------------------------------------------------
    // 5. Clear() resets the whole instance, entity keys included.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_Clear_ResetsTheScalarProperties()
    var
        Ctx: WebServiceActionContext;
        Pristine: WebServiceActionContext;
    begin
        Ctx.SetObjectId(50123);
        Ctx.SetObjectType(ObjectType::Page);
        Ctx.SetResultCode(WebServiceActionResultCode::Created);

        Clear(Ctx);

        Assert.AreEqual(0, Ctx.GetObjectId(), 'Clear must reset the object id to 0');
        // The object type is asserted against the value a PRISTINE instance reports, not
        // against a named member, because the default cannot be named in AL -- see
        // WSAC_FreshInstance_ObjectTypeIsNotAnyAssignableMember. Comparing against a second,
        // never-touched context states the claim exactly: Clear returns the type to whatever
        // an untouched instance has. Assigning Page beforehand is what makes it meaningful.
        Assert.AreEqual(Pristine.GetObjectType(), Ctx.GetObjectType(), 'Clear must reset the object type to its pristine value');
        Assert.AreNotEqual(ObjectType::Page, Ctx.GetObjectType(), 'Clear must discard the assigned object type');
        Assert.AreEqual('None', Format(Ctx.GetResultCode()), 'Clear must reset the result code to None');
    end;

    [Test]
    procedure WSAC_Clear_EmptiesTheEntityKeys()
    var
        Ctx: WebServiceActionContext;
    begin
        // The entity keys have no getter, so their emptiness is observed indirectly: a field
        // id that was already used becomes addable again. An implementation whose Clear reset
        // only the three scalar properties -- which the test above cannot distinguish -- fails
        // here, because the second add of field id 1 would still be a duplicate.
        Assert.IsTrue(Ctx.AddEntityKey(1, 'first value'), 'The first add of field id 1 must succeed');
        Assert.IsFalse(Ctx.AddEntityKey(1, 'duplicate'), 'Field id 1 must be a duplicate before Clear');

        Clear(Ctx);

        Assert.IsTrue(Ctx.AddEntityKey(1, 'after clear'), 'After Clear, field id 1 must be addable again');
    end;

    [Test]
    procedure WSAC_Clear_LeavesTheInstanceUsable()
    var
        Ctx: WebServiceActionContext;
    begin
        // Clear replaces the underlying context rather than nulling it, so the instance keeps
        // working afterwards. An implementation that left it in an unusable state would fail
        // on the assignments below rather than on the assertions.
        Ctx.SetObjectId(50123);
        Clear(Ctx);

        Ctx.SetObjectId(50124);
        Ctx.SetObjectType(ObjectType::Query);

        Assert.AreEqual(50124, Ctx.GetObjectId(), 'The instance must accept a new object id after Clear');
        Assert.AreEqual(ObjectType::Query, Ctx.GetObjectType(), 'The instance must accept a new object type after Clear');
    end;

    // ---------------------------------------------------------------------------------------
    // 6. Assignment shares the underlying context -- the OPPOSITE of SessionSettings.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_Assignment_SharesTheUnderlyingContext()
    var
        Original: WebServiceActionContext;
        Copy: WebServiceActionContext;
    begin
        // SessionSettings deep-copies on assignment; this type does not. Asserted explicitly
        // because the intuition carried over from that type is wrong here, and because a
        // reader who assumed a value copy would write incorrect AL.
        Original.SetObjectId(50123);

        Copy := Original;
        Copy.SetObjectId(50124);

        Assert.AreEqual(50124, Original.GetObjectId(), 'Assignment shares the underlying context, so the original must see the change');
        Assert.AreEqual(50124, Copy.GetObjectId(), 'The assigned-to variable must report the value it was given');
    end;

    [Test]
    procedure WSAC_Assignment_SharesTheEntityKeysToo()
    var
        Original: WebServiceActionContext;
        Copy: WebServiceActionContext;
    begin
        // The sharing covers the key map as well as the scalar properties: a field id added
        // through one variable is a duplicate through the other. An implementation that shared
        // the scalars but copied the map fails here while passing the test above.
        Assert.IsTrue(Original.AddEntityKey(1, 'first value'), 'The first add of field id 1 must succeed');

        Copy := Original;

        Assert.IsFalse(Copy.AddEntityKey(1, 'duplicate'), 'The assigned-to variable must see the key added through the original');
    end;

    // ---------------------------------------------------------------------------------------
    // Format() and Variant conversion. Both compile -- pinned so the file records what the
    // type supports, not only what it refuses.
    // ---------------------------------------------------------------------------------------

    [Test]
    procedure WSAC_ResultCode_FormatsToItsMemberName()
    var
        Ctx: WebServiceActionContext;
    begin
        // Format on the result code yields the member NAME, and the name is what the platform
        // round-trips -- which is why every assertion in this file goes through Format, and
        // why it has to: `=` is AL0175, AsInteger() does not exist (AL0132), and passing the
        // code to a Variant parameter fails to deploy (CS1503, see the header). This test
        // pins the text form itself against a code whose name is unambiguous, so the Format
        // path the other tests depend on is established rather than assumed.
        Ctx.SetResultCode(WebServiceActionResultCode::Deleted);

        Assert.AreEqual('Deleted', Format(Ctx.GetResultCode()), 'Format on the result code must yield its member name');
    end;


    [Test]
    procedure WSAC_ConvertsToVariantButNotBack()
    var
        Ctx: WebServiceActionContext;
        Holder: Variant;
    begin
        // The conversion is ONE-DIRECTIONAL. Unlike SecretText -- which refuses Variant
        // assignment outright with AL0122 -- this type converts INTO a Variant. It does not
        // convert back:
        //
        //     Recovered := Holder;   error AL0122: Cannot implicitly convert type 'Variant' to
        //                            'WebServiceActionContext'. Use an explicit conversion or
        //                            change the type.
        //
        // MEASURED ON REAL BC, and it falsified the first version of this test: a context has
        // an EMPTY text representation. Format(Ctx) compiles, and returns ''. The runtime type
        // NavWebServiceActionContext carries no ToString override -- it reports GetBytesSize 0
        // and IsZeroOrEmpty false -- so there is nothing for Format to render, and an object
        // id assigned beforehand does not appear in it. The first draft asserted the opposite
        // ("must have a non-empty text representation") purely from the intuition that a
        // populated object formats to something, and BC disagreed on all 8 cloud legs.
        //
        // So the claim pinned here is the accurate one: the context does reach a Variant, and
        // is NOT reported as any primitive type, but it carries no readable text form. That
        // combination is the useful thing for an AL author to know -- logging a context is
        // pointless, and reading its state requires the getters.
        Ctx.SetObjectId(50123);

        Holder := Ctx;

        Assert.IsFalse(Holder.IsInteger(), 'A context held in a Variant must not be reported as an Integer');
        Assert.IsFalse(Holder.IsText(), 'A context held in a Variant must not be reported as Text');
        Assert.IsFalse(Holder.IsRecord(), 'A context held in a Variant must not be reported as a Record');
        Assert.AreEqual('', Format(Holder), 'A context has an empty text representation, even with an object id assigned');
    end;
}
