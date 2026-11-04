// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-value-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefield-assertequals-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-value-method
// Scope: in-scope
// Fixtures used: TP Blank Temporal Row (60660), TP Blank Temporal Card (60661), Assert (60021)
// BC versions: 27.5+
//
// What a BLANK temporal value reads as when it is rendered — through a TestPage control, and
// through the two AL surfaces that render the identical value on the identical row: Format() and
// FieldRef.Value. Three renderings of one value, asserted side by side, which is why the
// FieldRef tests live in this file rather than under recordref/: separating them would lose the
// comparison that is the whole point.
//
// A blank temporal is not a corner case in Base Application. Page 9807 "User Card" declares
// WebServiceExpiryDate: DateTime and renders it unset for every user with no web-service key,
// and Microsoft's own UserCardTest.GenerateWebServiceKeyNoExpires asserts that control reads ''.
// This suite pins the general rule that test depends on, for all three temporal types and for
// both the Rec-bound and the page-variable-bound control shape.
//
// Each blank claim is paired with the same read on a POPULATED row. That pairing is the point:
// an implementation that answered '' for every temporal control, blank or not, would satisfy the
// blank half alone, and the populated half is what refuses it.

codeunit 60662 "TP Blank Temporal Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        BlankPKTok: Label 'BLANK', Locked = true;
        SetPKTok: Label 'SET', Locked = true;

    local procedure Initialize()
    var
        Row: Record "TP Blank Temporal Row";
    begin
        Row.DeleteAll();
    end;

    // The blank row is inserted WITHOUT touching any temporal field, so each one holds the AL
    // type default rather than a value that happens to look empty.
    local procedure SeedBlank()
    var
        Row: Record "TP Blank Temporal Row";
    begin
        Row.Init();
        Row.PK := BlankPKTok;
        Row.Marker := 'BLANK ROW';
        Row.Insert();
    end;

    local procedure SeedPopulated()
    var
        Row: Record "TP Blank Temporal Row";
    begin
        Row.Init();
        Row.PK := SetPKTok;
        Row.Marker := 'SET ROW';
        Row."On" := DMY2DATE(17, 3, 2024);
        Row."At" := 143000T;
        Row."When" := CreateDateTime(Row."On", Row."At");
        Row.Insert();
    end;

    local procedure OpenOn(var Card: TestPage "TP Blank Temporal Card"; PK: Code[10]; ExpectedMarker: Text)
    begin
        Card.OpenView();
        Card.GoToKey(PK);
        // Sanity, and it is load-bearing: without it, "the control reads ''" cannot be told
        // apart from "the page is positioned on nothing".
        Assert.AreEqual(ExpectedMarker, Card.RecMarker.Value(),
            'sanity: the page must be positioned on the seeded row before any temporal read');
    end;

    // ---------------------------------------------------------------- DateTime, Rec-bound

    [Test]
    procedure TestPageField_Value_BlankRecBoundDateTime_ReadsEmptyString()
    // CLAIM: a DateTime source-table field that was never assigned reads as '' through its
    // TestPage control, not as a rendered minimum-value date.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Assert.AreEqual('', Card.RecWhen.Value(),
            'a blank Rec-bound DateTime control must read as the empty string');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_BlankRecBoundDateTime_AcceptsEmptyString()
    // CLAIM: AssertEquals('') on the same blank DateTime control succeeds — the shape
    // Microsoft's own UserCardTest.GenerateWebServiceKeyNoExpires relies on.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Card.RecWhen.AssertEquals('');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Value_PopulatedRecBoundDateTime_ReadsTheStoredValue()
    // CLAIM, and the guard on the three blank claims above: a DateTime that IS set does not read
    // as '' — an implementation answering '' unconditionally fails here.
    var
        Row: Record "TP Blank Temporal Row";
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedPopulated();
        Row.Get(SetPKTok);

        OpenOn(Card, SetPKTok, 'SET ROW');
        Assert.AreNotEqual('', Card.RecWhen.Value(),
            'a populated DateTime control must not read as the empty string');
        Card.RecWhen.AssertEquals(Row."When");
        Card.Close();
    end;

    // -------------------------------------------------------------------- Date, Rec-bound

    [Test]
    procedure TestPageField_Value_BlankRecBoundDate_ReadsEmptyString()
    // CLAIM: the same rule holds for Date, not only for DateTime.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Assert.AreEqual('', Card.RecOn.Value(),
            'a blank Rec-bound Date control must read as the empty string');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Value_PopulatedRecBoundDate_ReadsTheStoredValue()
    var
        Row: Record "TP Blank Temporal Row";
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedPopulated();
        Row.Get(SetPKTok);

        OpenOn(Card, SetPKTok, 'SET ROW');
        Assert.AreNotEqual('', Card.RecOn.Value(),
            'a populated Date control must not read as the empty string');
        Card.RecOn.AssertEquals(Row."On");
        Card.Close();
    end;

    // -------------------------------------------------------------------- Time, Rec-bound

    [Test]
    procedure TestPageField_Value_BlankRecBoundTime_ReadsEmptyString()
    // CLAIM: the same rule holds for Time. Worth pinning separately: 0T is the one temporal
    // default that a naive "render the underlying value" implementation is most likely to
    // surface as a real-looking 00:00:00.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Assert.AreEqual('', Card.RecAt.Value(),
            'a blank Rec-bound Time control must read as the empty string');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Value_PopulatedRecBoundTime_ReadsTheStoredValue()
    var
        Row: Record "TP Blank Temporal Row";
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedPopulated();
        Row.Get(SetPKTok);

        OpenOn(Card, SetPKTok, 'SET ROW');
        Assert.AreNotEqual('', Card.RecAt.Value(),
            'a populated Time control must not read as the empty string');
        Card.RecAt.AssertEquals(Row."At");
        Card.Close();
    end;

    // ------------------------------------------------------ DateTime, page-variable-bound

    [Test]
    procedure TestPageField_Value_BlankVariableBoundDateTime_ReadsEmptyString()
    // CLAIM: a control bound to a page GLOBAL of type DateTime that the page never assigns
    // reads as '' too. This is the shape Base Application page 9807 "User Card" uses for
    // WebServiceExpiryDate, and it resolves through different plumbing than a Rec-bound
    // control, so the Rec-bound claim above is not evidence about it.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Assert.AreEqual('', Card.GlobalWhen.Value(),
            'a blank page-variable-bound DateTime control must read as the empty string');
        Card.Close();
    end;

    [Test]
    procedure TestPageField_Value_VariableBoundDateTime_StaysBlankOnAPopulatedRow()
    // CLAIM, and the negative direction of the one above: the page never assigns GlobalWhen, so
    // it stays blank even when the ROW carries a real DateTime. Pins that the variable-bound
    // control reads the page global and not, by accident, the source-table field beside it.
    var
        Card: TestPage "TP Blank Temporal Card";
    begin
        Initialize();
        SeedPopulated();

        OpenOn(Card, SetPKTok, 'SET ROW');
        Assert.AreNotEqual('', Card.RecWhen.Value(),
            'sanity: the row under the page really does carry a populated DateTime');
        Assert.AreEqual('', Card.GlobalWhen.Value(),
            'the page global is never assigned, so its control must stay blank regardless of the row');
        Card.Close();
    end;

    // -------------------------------------------------- the same value through Format/FieldRef

    [Test]
    procedure Format_BlankTemporalFields_ProduceEmptyStrings()
    // CLAIM: AL's own Format() renders all three blank temporal types as ''. Asserted on the
    // SAME row the TestPage tests above read, so the three renderings can be compared rather
    // than assumed to agree.
    var
        Row: Record "TP Blank Temporal Row";
    begin
        Initialize();
        SeedBlank();
        Row.Get(BlankPKTok);

        Assert.AreEqual('', Format(Row."When"), 'Format() of a blank DateTime must be the empty string');
        Assert.AreEqual('', Format(Row."On"), 'Format() of a blank Date must be the empty string');
        Assert.AreEqual('', Format(Row."At"), 'Format() of a blank Time must be the empty string');
    end;

    [Test]
    procedure Format_PopulatedTemporalFields_ProduceNonEmptyStrings()
    var
        Row: Record "TP Blank Temporal Row";
    begin
        Initialize();
        SeedPopulated();
        Row.Get(SetPKTok);

        Assert.AreNotEqual('', Format(Row."When"), 'Format() of a populated DateTime must not be empty');
        Assert.AreNotEqual('', Format(Row."On"), 'Format() of a populated Date must not be empty');
        Assert.AreNotEqual('', Format(Row."At"), 'Format() of a populated Time must not be empty');
    end;

    [Test]
    procedure FieldRef_Value_BlankTemporalFields_FormatToEmptyStrings()
    // CLAIM: reading the same blank temporal fields through RecordRef/FieldRef and formatting
    // the resulting Variant gives '' as well — so the empty rendering is a property of the
    // value, not of one particular reader.
    var
        Row: Record "TP Blank Temporal Row";
        RecRef: RecordRef;
    begin
        Initialize();
        SeedBlank();
        Row.Get(BlankPKTok);
        RecRef.GetTable(Row);

        Assert.AreEqual('', Format(RecRef.Field(3).Value), 'FieldRef.Value of a blank DateTime must format to ''''');
        Assert.AreEqual('', Format(RecRef.Field(4).Value), 'FieldRef.Value of a blank Date must format to ''''');
        Assert.AreEqual('', Format(RecRef.Field(5).Value), 'FieldRef.Value of a blank Time must format to ''''');
        RecRef.Close();
    end;

    [Test]
    procedure FieldRef_Value_PopulatedTemporalFields_RoundTripThroughTheRecord()
    // CLAIM, and the guard on the one above: FieldRef.Value on a populated temporal field hands
    // back the stored value, so the '' results above are about blankness and not about FieldRef
    // failing to read temporal fields at all.
    var
        Row: Record "TP Blank Temporal Row";
        RecRef: RecordRef;
    begin
        Initialize();
        SeedPopulated();
        Row.Get(SetPKTok);
        RecRef.GetTable(Row);

        Assert.AreEqual(Row."When", RecRef.Field(3).Value, 'FieldRef.Value must hand back the stored DateTime');
        Assert.AreEqual(Row."On", RecRef.Field(4).Value, 'FieldRef.Value must hand back the stored Date');
        Assert.AreEqual(Row."At", RecRef.Field(5).Value, 'FieldRef.Value must hand back the stored Time');
        RecRef.Close();
    end;

    // ------------------------------------ the same claim through a TYPED AssertEquals argument

    // The four tests below exist because AssertEquals reaches the control's rendering by TWO
    // different routes, and the '' tests above can only ever take one of them.
    //
    // NavTestField.ALAssertEquals branches on whether the expected value is already a string:
    //
    //     if (!(value is NavStringValue)) {
    //         value = NavValue.CreateNavValueFromObject(
    //                     NavValueMetadata.DefaultMetadata(testField.FieldType), value);
    //         text  = testField.ValueToString(value.ClientObject);   // <-- typed route
    //     } else
    //         text  = value.ToString();                              // <-- string route
    //
    // So AssertEquals('') takes the string route and never reaches ValueToString, while
    // AssertEquals(<an unassigned DateTime variable>) takes the typed route, which renders the
    // EXPECTED value through ValueToString before comparing it ordinally against the control.
    //
    // This suite already pins the typed route on POPULATED values (RecWhen.AssertEquals(
    // Row."When") and its Date/Time siblings), and the blank rendering through the string route.
    // A blank value through the TYPED route was the one combination nothing pinned — precisely
    // where an implementation can render a blank expected value one way and a blank control
    // value another and still pass everything else in the file.

    [Test]
    procedure TestPageField_AssertEquals_BlankDateTimeVariable_MatchesTheBlankControl()
    // CLAIM: AssertEquals against an unassigned DateTime VARIABLE succeeds on a blank control.
    // Not a restatement of the AssertEquals('') test: the argument is typed, so BC renders it
    // through ValueToString rather than taking it as a literal string.
    var
        Card: TestPage "TP Blank Temporal Card";
        BlankWhen: DateTime;
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Card.RecWhen.AssertEquals(BlankWhen);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_BlankDateVariable_MatchesTheBlankControl()
    // CLAIM: the same holds for Date.
    var
        Card: TestPage "TP Blank Temporal Card";
        BlankOn: Date;
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Card.RecOn.AssertEquals(BlankOn);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_BlankTimeVariable_MatchesTheBlankControl()
    // CLAIM: the same holds for Time.
    var
        Card: TestPage "TP Blank Temporal Card";
        BlankAt: Time;
    begin
        Initialize();
        SeedBlank();

        OpenOn(Card, BlankPKTok, 'BLANK ROW');
        Card.RecAt.AssertEquals(BlankAt);
        Card.Close();
    end;

    [Test]
    procedure TestPageField_AssertEquals_BlankDateTimeVariable_IsRefusedByAPopulatedControl()
    // CLAIM, and the guard on the three above: the typed blank comparison is a real comparison,
    // not one that succeeds against any control. An implementation rendering every expected
    // temporal as '' would pass the three above and fail here.
    //
    // The expected substring names the CONTROL, 'RecWhen', not the field caption 'Rec When' -
    // BC reports an AssertEquals mismatch against the page control's name. It also pins
    // "Expected = ''", which is the half of the message this test exists to establish: the
    // blank DateTime argument reached the comparison rendered as the empty string, so the
    // failure is a genuine mismatch and not a refusal to compare. The ACTUAL half is
    // deliberately left out - it formats the seeded 2024-03-17 14:30 under the service tier's
    // locale ('3/17/2024 2:30 PM' on CI), which is not what this test is about.
    var
        Card: TestPage "TP Blank Temporal Card";
        BlankWhen: DateTime;
    begin
        Initialize();
        SeedPopulated();

        OpenOn(Card, SetPKTok, 'SET ROW');
        asserterror Card.RecWhen.AssertEquals(BlankWhen);
        Assert.ExpectedError('AssertEquals for Field: RecWhen Expected = ''''');
        Card.Close();
    end;
}
