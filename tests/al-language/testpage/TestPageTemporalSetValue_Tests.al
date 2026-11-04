// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpagefield-setvalue-method
// Scope: in-scope
// Fixtures used: ALT Temporal Row (60667), ALT Temporal Card (60668), ALT Temporal Globals (60669)
//
// What a TestPage control does with a Date, DateTime or Time.
//
// SetValue is string-typed in the AL surface, so a caller can reach a temporal control three
// ways - a typed AL variable, Format() text in the session's own format, and the ISO
// 'yyyy-mm-dd' spelling the platform's own refusal message recommends. All three land the same
// value, on a control bound to a source-table field and on a control bound to a page variable.
//
// The last two tests pin the other direction: a spelling the platform cannot evaluate is
// refused, and a Text carried in a Variant onto the field itself is refused even in the ISO
// spelling a control accepts. Without those, "accepts everything" would pass a control that
// silently ignored what it was given.
//
// One thing here looks over-careful and is not: every Date arm drives a control bound to a page
// VARIABLE, while the DateTime and Time arms drive a control bound to a table FIELD. That split
// is measured, not stylistic.
//
// Writing a Date into a table field through a control goes through the license's allowed-date
// interval. A probe on this branch wrote eleven candidate dates through a Rec-bound Date control
// and reported which the tier took:
//
//   BC 28.4  accepted 2024-01-01, 2024-01-12, 2024-12-01, 2024-11-11, 2025-01-01, 2026-01-15,
//            2012-01-15, 2028-12-31 and its own WorkDate; refused 2011-06-15 and Today
//   BC 27.0  accepted NOTHING - all eleven refused, including its own WorkDate and Today,
//            each with "outside the allowed interval ... the filter '??11*|??12*|??01*|??02*',
//            which is defined by the license file"
//
// So there is no date a Date table field will take on every supported version, and three
// literals plus WorkDate were refused somewhere before that was measured. A page variable is not
// a table field and is not checked against the interval, so the Date arms live there and the
// claim they make - which spellings a control accepts - is unchanged by the move.
//
// The Rec-bound arms that remain are load-bearing rather than leftovers: DateTime and Time
// fields are NOT checked against the interval (that is what identified the boundary, since they
// passed on 27.x with a literal the Date arms were refused for), and they drive the same
// control-write path a Date field would. So the table-field path stays covered upstream; only
// the Date *type* on it does not, and that one is proven runner-side against a precompiled
// Sales Header instead - see StefanMaron/BusinessCentral.AL.Runner#3394.
//
// The refusal arms name the type rather than the rejected value. 27.x refuses a Text carried in
// a Variant with 'Unable to convert from ...NavText to System.DateTime.', which never quotes the
// value; 28.x quotes it. Asserting the quoted value pinned one version's wording.

codeunit 60670 "Test TestPage Temporal Value"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    // A literal, with nothing session-scoped in it, so every arm's input is the same on every
    // leg. Safe on a DateTime or Time table field, which the license's allowed-date interval
    // does not check, and on a page variable, which is not a table field at all.
    local procedure TemporalSetValue_Date(): Date
    begin
        exit(20240101D);
    end;

    local procedure TemporalSetValue_Seed(No: Code[20]) Row: Record "ALT Temporal Row"
    begin
        Row.SetRange("No.", No);
        Row.DeleteAll();
        Row.Reset();
        Row.Init();
        Row."No." := No;
        Row.Insert();
        exit(Row);
    end;




    [Test]
    procedure TemporalSetValue_RecBoundDateTimeControlTakesADateTimeVariable()
    var
        Row: Record "ALT Temporal Row";
        Card: TestPage "ALT Temporal Card";
        Expected: DateTime;
    begin
        Row := TemporalSetValue_Seed('TSV-D');
        Expected := CreateDateTime(TemporalSetValue_Date(), 0T);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card."The DateTime".SetValue(Expected);
        Card.Close();

        Row.Get('TSV-D');
        Assert.AreEqual(Expected, Row."The DateTime", 'Rec-bound DateTime control, DateTime variable');
    end;

    // The arm above seeds midnight, where a round trip that shifts the time of day by a
    // whole-hour or half-hour offset can still read back equal. 14:30 has non-zero minutes, so
    // an hour-granular or 30-minute error in the control's DateTime path cannot pass here
    // (StefanMaron/BusinessCentral.AL.Runner#4499, #3567).
    [Test]
    procedure TemporalSetValue_RecBoundDateTimeControlKeepsANonMidnightTimeOfDay()
    var
        Row: Record "ALT Temporal Row";
        Card: TestPage "ALT Temporal Card";
        Expected: DateTime;
    begin
        Row := TemporalSetValue_Seed('TSV-DT');
        Expected := CreateDateTime(TemporalSetValue_Date(), 143000T);

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card."The DateTime".SetValue(Expected);
        Card.Close();

        Row.Get('TSV-DT');
        Assert.AreEqual(Expected, Row."The DateTime", 'Rec-bound DateTime control, 14:30 DateTime variable');
        Assert.AreEqual(143000T, DT2Time(Row."The DateTime"), 'Rec-bound DateTime control must keep the 14:30 time of day');
        Assert.AreEqual(TemporalSetValue_Date(), DT2Date(Row."The DateTime"), 'Rec-bound DateTime control must keep the date');
    end;

    [Test]
    procedure TemporalSetValue_RecBoundTimeControlTakesATimeVariable()
    var
        Row: Record "ALT Temporal Row";
        Card: TestPage "ALT Temporal Card";
        Expected: Time;
    begin
        Row := TemporalSetValue_Seed('TSV-E');
        Expected := 143000T;

        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card."The Time".SetValue(Expected);
        Card.Close();

        Row.Get('TSV-E');
        Assert.AreEqual(Expected, Row."The Time", 'Rec-bound Time control, Time variable');
    end;

    [Test]
    procedure TemporalSetValue_PageVariableDateControlTakesADateVariable()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: Date;
    begin
        Expected := TemporalSetValue_Date();

        Globals.OpenEdit();
        Globals.GDate.SetValue(Expected);

        Assert.AreEqual(
            Format(Expected, 0, 9), Globals.GEcho.Value(),
            'page-variable Date control, Date variable');
        Globals.Close();
    end;

    [Test]
    procedure TemporalSetValue_PageVariableDateControlTakesIsoText()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: Date;
    begin
        Expected := TemporalSetValue_Date();

        Globals.OpenEdit();
        // Format 9 is BC's own XML/invariant rendering, yyyy-MM-dd - the spelling the
        // platform's own refusal message names as the one that always works.
        Globals.GDate.SetValue(Format(Expected, 0, 9));

        Assert.AreEqual(
            Format(Expected, 0, 9), Globals.GEcho.Value(),
            'page-variable Date control, ISO text');
        Globals.Close();
    end;

    [Test]
    procedure TemporalSetValue_PageVariableDateControlTakesFormattedText()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: Date;
    begin
        Expected := TemporalSetValue_Date();

        Globals.OpenEdit();
        Globals.GDate.SetValue(Format(Expected));

        Assert.AreEqual(
            Format(Expected, 0, 9), Globals.GEcho.Value(),
            'page-variable Date control, Format() text');
        Globals.Close();
    end;

    // The negative direction, and the arm that stops the positive ones from passing against a
    // control that silently ignores what it is handed. The refusal must name the type it could
    // not produce; the wording around it is the platform's and differs by version.
    //
    // On a page variable rather than a table field for a second reason beyond the interval: on a
    // tier that refuses every date outright, a Rec-bound arm would still see an error and still
    // pass, having proven nothing about how the control read the text.
    [Test]
    procedure TemporalSetValue_PageVariableDateControlRefusesAnUnevaluableSpelling()
    var
        Globals: TestPage "ALT Temporal Globals";
    begin
        Globals.OpenEdit();
        asserterror Globals.GDate.SetValue('not-a-date');

        Assert.IsTrue(
            StrPos(GetLastErrorText(), 'Date') > 0,
            StrSubstNo('the refusal should name the Date type; it said <%1>', GetLastErrorText()));
    end;

    [Test]
    procedure TemporalSetValue_PageVariableDateTimeControlTakesADateTimeVariable()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: DateTime;
    begin
        Expected := CreateDateTime(TemporalSetValue_Date(), 0T);

        Globals.OpenEdit();
        Globals.GDateTime.SetValue(Expected);

        Assert.AreEqual(
            Format(Expected, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'),
            Globals.GEcho.Value(), 'page-variable DateTime control, DateTime variable');
        Globals.Close();
    end;

    // Same reason as the Rec-bound 14:30 arm: the arm above is midnight only.
    [Test]
    procedure TemporalSetValue_PageVariableDateTimeControlKeepsANonMidnightTimeOfDay()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: DateTime;
    begin
        Expected := CreateDateTime(TemporalSetValue_Date(), 143000T);

        Globals.OpenEdit();
        Globals.GDateTime.SetValue(Expected);

        Assert.AreEqual(
            Format(Expected, 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'),
            Globals.GEcho.Value(), 'page-variable DateTime control, 14:30 DateTime variable');
        Assert.AreNotEqual(
            Format(CreateDateTime(TemporalSetValue_Date(), 0T), 0, '<Year4>-<Month,2>-<Day,2> <Hours24,2>:<Minutes,2>:<Seconds,2>'),
            Globals.GEcho.Value(), 'page-variable DateTime control must not collapse 14:30 to midnight');
        Globals.Close();
    end;

    [Test]
    procedure TemporalSetValue_PageVariableTimeControlTakesATimeVariable()
    var
        Globals: TestPage "ALT Temporal Globals";
        Expected: Time;
    begin
        Expected := 143000T;

        Globals.OpenEdit();
        Globals.GTime.SetValue(Expected);

        Assert.AreEqual(
            Format(Expected, 0, '<Hours24,2>:<Minutes,2>:<Seconds,2>'), Globals.GEcho.Value(),
            'page-variable Time control, Time variable');
        Globals.Close();
    end;


    // 'w' is the working date, and it is the arm that decides HOW a control reads its text: no
    // general-purpose date parser accepts it under any culture, so a control that resolves it
    // is going through the platform's own date evaluator rather than a parser standing in for
    // one. Asserted against WorkDate() itself, so the tier's own value is the expected value.
    // On a page variable rather than a table field, because the resulting date is whatever the
    // tier's working date happens to be and a table field would put that through the license's
    // allowed-date interval - see the header.
    [Test]
    procedure TemporalSetValue_PageVariableDateControlTakesTheWorkingDateShorthand()
    var
        Globals: TestPage "ALT Temporal Globals";
    begin
        Globals.OpenEdit();
        Globals.GDate.SetValue('w');

        Assert.AreEqual(
            Format(WorkDate(), 0, 9), Globals.GEcho.Value(),
            'page-variable Date control, the working-date shorthand');
        Globals.Close();
    end;

    // Not the same claim, and it is here so nobody reads the tests above as making it: a Text
    // carried in a Variant and validated straight onto the FIELD is not evaluated the way a
    // control's input is. The platform refuses it, even in the ISO spelling a control accepts.
    [Test]
    procedure TemporalSetValue_ValidateRefusesTextCarriedInAVariant()
    var
        Row: Record "ALT Temporal Row";
        AsText: Variant;
    begin
        Row.Init();
        Row."No." := 'TSV-P2';
        AsText := Format(TemporalSetValue_Date(), 0, 9);

        asserterror Row.Validate("The Date", AsText);

        // Named type, not quoted value: 27.x says 'Unable to convert from ...NavText to
        // System.DateTime.' and never quotes the text, where 28.x quotes it.
        Assert.IsTrue(
            StrPos(GetLastErrorText(), 'Date') > 0,
            StrSubstNo('the refusal should name the Date type; it said <%1>', GetLastErrorText()));
        Assert.AreEqual(0D, Row."The Date", 'a refused Validate must leave the field blank');
    end;
}
