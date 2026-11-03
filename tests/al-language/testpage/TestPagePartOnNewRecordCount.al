// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/pagetriggers/devenv-triggers-auto-onnewrecord
// Scope: in-scope
// Fixtures used: ONRC Log (60353), ONRC Header (60354), ONRC Line (60355),
//                ONRC Lines (60356), ONRC Card (60357), ONRC Line List (67001);
//                shared Assert (60021)
//
/// <summary>
/// Pins HOW MANY TIMES a subpage part's OnNewRecord trigger runs -- the question codeunit 60996
/// ("TPDL Tests") leaves open, and cannot answer with the witness it uses.
///
/// WHY THE EXISTING SUITE CANNOT ANSWER IT. 60996 measured, on all 8 BC legs, that the draft
/// line of a linked part has ALREADY run the page's OnNewRecord before anyone types into it
/// (LinkedPart_DraftLine_HasRunTheOnNewRecordTrigger, run 33997895349). Its witness is
/// `Rec."Set By OnNewRecord" := 'NEWREC'`, and an assignment is idempotent: one firing, two
/// firings and five firings all leave 'NEWREC' in the field. So every arm of that file passes
/// whether the platform raises the trigger once per row or repeatedly, and the same is true of
/// any OnNewRecord that only assigns defaults -- which is what most real ones do.
///
/// That matters as soon as an OnNewRecord has a SIDE EFFECT rather than only a default: a
/// number-series draw, a log row, a counter, a call out to a setup codeunit. Repeated firings
/// silently multiply it, and nothing in the finished row says so.
///
/// WHAT REAL BC ANSWERED, and it is not "once" -- nor is it one number. This file was first
/// written asserting one firing per row throughout. A real service tier said otherwise,
/// identically on all 8 cloud legs of run 34140530877 (BC 27.0 through 28.4):
///
///   * opening the card on an EMPTY part and landing on its draft line cost SIX firings;
///   * New() on that same empty part cost SEVEN -- the six above, plus one for New() itself.
///
/// Those six and seven were then pinned here as exact constants, described as deterministic
/// platform behaviour. THAT WAS WRONG, and a second real tier is what showed it. The official
/// Microsoft BC container on Windows, BC 28.4, nightly run 34182689878, answers THREE and FOUR
/// for the same two arms (corpus issue #281).
///
/// So the absolute count is a property of the TIER, not of the platform, and this file no
/// longer asserts one. What differs between the two tiers is how many blank rows the client
/// renders to fill the viewport, which is exactly what the mechanism below predicts would vary.
///
/// WHAT IS ASSERTED INSTEAD, and why nothing is weakened by it. Every claim this file exists to
/// make is a DELTA, and both tiers agree on all of them:
///
///   * landing on an existing data row costs 0, and Next() onto the draft line costs exactly 1
///     (arm 4, absolute and portable, because it never renders an empty repeater);
///   * First() on an ALREADY-open empty part costs exactly 0 more -- the draft line was
///     started during the open (arm 1);
///   * New() on an empty part costs exactly +1 over the open (arm 3);
///   * writing into a draft line already started costs exactly +0 (arms 2 and 5);
///   * a second row started through the draft line costs exactly +1 (arm 5).
///
/// Those are exact integers, so an implementation that fires an extra time still fails and one
/// that stops firing still fails. The single non-exact assertion in the file is arm 1's "the
/// open cost is greater than zero", which is the honest portable form of "showing a blank draft
/// line raises the trigger at all": the tier decides how many times, and both measured tiers
/// agree that it is more than once.
///
/// THE MECHANISM the numbers point at, stated as the reading it is: showing a blank draft line
/// in an EMPTY repeater raises the trigger repeatedly as the client fills the visible viewport,
/// whereas a row that genuinely starts adds exactly one. Arm 4 is what makes that reading
/// falsifiable rather than decorative -- on a part that already HAS a row, opening costs zero
/// (landing on real data is not a new record) and walking onto the draft line with Next() costs
/// exactly one. So the six is a property of rendering an empty repeater, not a per-row cost.
///
/// HOW THE LATER ASSERTIONS IN EACH ARM ARE WRITTEN, and why they are not absolute integers.
/// Run 34140530877 failed each arm at its FIRST count assertion, so only that first number was
/// measured; every count after it in the same arm never executed. Rather than invent absolutes
/// that no tier has confirmed, each arm now captures the measured baseline in a variable and
/// asserts the exact DELTA from it -- +0 for a step that must not start a record, +1 for a step
/// that starts exactly one. The deltas are exact integers, so nothing here is weakened to a
/// range or an inequality: an implementation that fires an extra time fails, and one that stops
/// firing fails too.
///
/// THE ARMS, and what each isolates.
///
///   1. DraftLine_Shown  -- land on the draft line and touch nothing. Counts what merely SHOWING
///      the blank line costs. Measured: 6.
///   2. DraftLine_Written -- land on the draft line and write one field. Arm 2's delta over
///      arm 1's baseline answers "does the write start the record a second time".
///   3. New_OnEmptyPart  -- New() on an empty part. Measured: 7, i.e. arm 1's six plus one.
///   4. DraftLine_ReachedByNext -- the control, and the arm that passed unchanged. A part with
///      existing data: opening costs 0, Next() onto the draft line costs 1. This is what keeps
///      the sixes above attributable to the empty-repeater render rather than to counting at all.
///
/// The negative is in the data: a second header carries its own line, so an implementation that
/// ignores the SubPageLink shows a row it should not, and the counts move.
/// </summary>
codeunit 60358 "ONRC Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "ONRC Header";
        Line: Record "ONRC Line";
        Log: Record "ONRC Log";
    begin
        Log.DeleteAll();
        Line.DeleteAll();
        Header.DeleteAll();

        AddHeader('H1', 'First');
        AddHeader('H2', 'Second');
    end;

    local procedure AddHeader(No: Code[20]; Descr: Text[50])
    var
        Header: Record "ONRC Header";
    begin
        Header.Init();
        Header."No." := No;
        Header.Descr := Descr;
        Header.Insert();
    end;

    // Assignment, not Validate, and no page involved: a seeded line must not run the part's
    // OnNewRecord, so the log counts only what the tests themselves cause.
    local procedure AddLine(HeaderNo: Code[20]; LineNo: Integer; Descr: Text[50])
    var
        Line: Record "ONRC Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Descr := Descr;
        Line.Insert();
    end;

    local procedure OpenCardOn(HeaderNo: Code[20]; var Card: TestPage "ONRC Card")
    var
        Header: Record "ONRC Header";
    begin
        Header.Get(HeaderNo);
        Card.OpenEdit();
        Card.GoToRecord(Header);
    end;

    local procedure OnNewRecordCount(): Integer
    var
        Log: Record "ONRC Log";
    begin
        exit(Log.Count());
    end;

    local procedure LineCountFor(HeaderNo: Code[20]): Integer
    var
        Line: Record "ONRC Line";
    begin
        Line.SetRange("Header No.", HeaderNo);
        exit(Line.Count());
    end;

    // ARM 3. New() on an empty linked part. The claim is the DELTA: New() raises OnNewRecord
    // exactly once more than opening the card on that empty part already did. The open cost
    // itself is measured here rather than asserted, because it differs by tier -- 6 on bc-linux
    // and 3 on the official MS Windows container (#281).
    [Test]
    procedure New_OnEmptyLinkedPart_RunsOnNewRecordOncePlusTheOpenCost()
    var
        Card: TestPage "ONRC Card";
        AfterOpen: Integer;
        AfterNew: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        // The tier's own open cost, measured, not assumed. Every assertion below is a delta
        // from it, so a tier that renders a different number of blank lines does not change
        // what this arm claims.
        AfterOpen := OnNewRecordCount();

        Card.Lines.New();

        AfterNew := OnNewRecordCount();
        Assert.AreEqual(AfterOpen + 1, AfterNew,
            'New() on an empty linked part must raise OnNewRecord exactly once more than opening the card on that empty part already did');

        Card.Lines.Descr.SetValue('typed after New');
        Card.Close();

        // The write after New() must not start a SECOND record: the row New() started is the one
        // being filled in. Asserted as an exact delta of zero against the count measured above.
        Assert.AreEqual(AfterNew, OnNewRecordCount(),
            'writing into the row New() started must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor('H1'), 'exactly one line must have been written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 1. Merely showing the draft line of an EMPTY part, and the arm that establishes what
    // the open costs on whatever tier is running. Two claims, both portable:
    //
    //   * the open raises the trigger AT ALL -- the one non-exact assertion in this file, and
    //     the honest form of the claim, since how many times is the tier's decision (6 on
    //     bc-linux, 3 on the official MS Windows container -- #281);
    //   * First() on an already-open empty part then costs EXACTLY ZERO more, because the draft
    //     line was already started during the open. That is an exact integer and it is the
    //     mechanism claim this whole file rests on.
    //
    // Nothing is typed, so nothing is saved either, which is asserted: the firings cannot be
    // explained as rows having been written.
    [Test]
    procedure DraftLine_ShownAndUntouched_RunsOnNewRecordOncePerRenderedBlankLine()
    var
        Card: TestPage "ONRC Card";
        AfterOpen: Integer;
        AfterShown: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);

        AfterOpen := OnNewRecordCount();
        Assert.IsTrue(AfterOpen > 0,
            'opening a card on an empty part must raise the part''s OnNewRecord at least once -- the blank draft line is rendered, and rendering it starts a record');

        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');

        AfterShown := OnNewRecordCount();
        Assert.AreEqual(AfterOpen, AfterShown,
            'First() on an empty part must not raise OnNewRecord again -- the draft line was already started while the card opened');

        Card.Close();

        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'closing a card over an untouched draft line must not raise OnNewRecord again');
        Assert.AreEqual(0, LineCountFor('H1'),
            'an untouched draft line must not be written -- so the firings above cannot be saved rows');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 2, AND THE ONE THIS FILE EXISTS FOR. Land on the draft line, then write one field.
    // Against the baseline measured in the same arm this isolates what the WRITE costs: an equal
    // count means typing only marks an already-started row for saving, a higher count means the
    // promotion starts the record again. Asserted as an exact delta so either answer is
    // falsifiable, and measured rather than compared against a constant so the claim holds on
    // any tier (#281).
    [Test]
    procedure DraftLine_ShownThenWritten_WriteDoesNotRaiseOnNewRecordAgain()
    var
        Line: Record "ONRC Line";
        Card: TestPage "ONRC Card";
        AfterShown: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(),
            'H1 has no lines, so First() on the part must return false and land on the draft line');
        AfterShown := OnNewRecordCount();

        Card.Lines.Descr.SetValue('typed into the draft line');

        // THE MEASUREMENT. Read BEFORE Close(), so a later firing on the way out cannot be
        // mistaken for one the write caused. Exact delta of zero against the baseline above.
        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'writing into the draft line must not raise OnNewRecord again -- the row was already started when the blank line became current');

        Card.Close();

        Assert.AreEqual(AfterShown, OnNewRecordCount(),
            'saving the promoted draft line on close must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor('H1'),
            'typing into the draft line must insert exactly one line for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.FindFirst();
        Assert.AreEqual('typed into the draft line', Line.Descr,
            'the typed value must reach the backing table -- the count above is for a row that really was written');
        Assert.AreEqual('H1', Line."Header No.",
            'the promoted row must carry the SubPageLink''s value');
    end;

    // ARM 4, THE CONTROL, and the one arm run 34140530877 passed exactly as written -- so not a
    // character of it is changed here. It is what stops the sixes above from being read as "the
    // fixture miscounts": on a part that already has a row, opening costs ZERO and Next() onto
    // the draft line costs exactly ONE. The empty-part cost is therefore a render property, not
    // a counting artefact and not a per-row price.
    [Test]
    procedure DraftLine_ReachedByNextThenWritten_RunsOnNewRecordExactlyOnce()
    var
        Line: Record "ONRC Line";
        Card: TestPage "ONRC Card";
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');

        // Standing on a REAL row is not a new record. This is what stops the counts below from
        // being read as "any cursor move fires the trigger".
        Assert.AreEqual(0, OnNewRecordCount(),
            'landing on an existing data row must not raise OnNewRecord at all');

        Assert.IsTrue(Card.Lines.Next(), 'Next() past the last data row must land on the draft line');
        Assert.AreEqual(1, OnNewRecordCount(),
            'walking onto the draft line must raise OnNewRecord exactly once');

        Card.Lines.Descr.SetValue('typed after walking to the end');

        Assert.AreEqual(1, OnNewRecordCount(),
            'writing into a draft line reached by Next() must not raise OnNewRecord a second time');

        Card.Close();

        Assert.AreEqual(1, OnNewRecordCount(),
            'saving the promoted row on close must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'),
            'the promoted draft line must be a second line for H1, alongside the seeded one');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');

        Line.SetRange("Header No.", 'H1');
        Line.SetRange(Descr, 'typed after walking to the end');
        Assert.AreEqual(1, Line.Count(), 'exactly one line must carry the typed description');
        Line.FindFirst();
        Assert.IsTrue(Line."Line No." > 10000,
            'AutoSplitKey must number the promoted line past the line already there');
    end;

    // TWO ROWS. The arm that stops the counts above from being read as "the trigger fires a fixed
    // number of times per page and then stops". The count tracks work the platform does, so a
    // second row started after the first is saved raises it AGAIN. Both claims are exact deltas
    // against a baseline this arm measures for itself: writing the first row costs +0 over the
    // open, and the second row costs +1 over that (#281).
    [Test]
    procedure TwoRowsWrittenThroughTheDraftLine_SecondRowRaisesOnNewRecordOnceMore()
    var
        Card: TestPage "ONRC Card";
        AfterShown: Integer;
        AfterFirstRow: Integer;
    begin
        Initialize();
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsFalse(Card.Lines.First(), 'H1 has no lines, so First() must return false');

        // Measured BEFORE the write, so the next assertion is a delta across the write alone.
        AfterShown := OnNewRecordCount();

        Card.Lines.Descr.SetValue('first line');
        AfterFirstRow := OnNewRecordCount();
        Assert.AreEqual(AfterShown, AfterFirstRow,
            'writing the first row must cost nothing beyond the firings opening the empty part already paid');

        Assert.IsTrue(Card.Lines.Next(),
            'Next() must leave the row just written and land on a fresh draft line');
        Card.Lines.Descr.SetValue('second line');

        Assert.AreEqual(AfterFirstRow + 1, OnNewRecordCount(),
            'a second row started through the draft line must raise OnNewRecord exactly once more -- one firing per row started, not a fixed budget per page');

        Card.Close();

        Assert.AreEqual(AfterFirstRow + 1, OnNewRecordCount(),
            'closing the card must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'), 'both rows must be written for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 6. New() while standing on a draft line reached by Next() on a part that HAS rows.
    // Arm 4 shows Next() onto the draft line costs exactly 1; this asks whether New() there is
    // one more new-record step or only commits the row the draft line already started. Exact
    // delta from the count after Next().
    [Test]
    procedure New_OnDraftLineReachedByNext_RunsOnNewRecordOnceMore()
    var
        Card: TestPage "ONRC Card";
        AfterNext: Integer;
        AfterNew: Integer;
    begin
        Initialize();
        AddLine('H1', 10000, 'seeded');
        AddLine('H2', 10000, 'foreign');

        OpenCardOn('H1', Card);
        Assert.IsTrue(Card.Lines.First(), 'the part must land on H1''s seeded line');
        Assert.IsTrue(Card.Lines.Next(), 'Next() past the last data row must land on the draft line');
        AfterNext := OnNewRecordCount();

        Card.Lines.New();

        AfterNew := OnNewRecordCount();
        Assert.AreEqual(AfterNext + 1, AfterNew,
            'New() on a draft line reached by Next() must raise OnNewRecord exactly once more');

        Card.Lines.Descr.SetValue('typed after New');
        Card.Close();

        Assert.AreEqual(AfterNew, OnNewRecordCount(),
            'writing into the row New() started must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor('H1'), 'the row New() started must be a second line for H1');
        Assert.AreEqual(1, LineCountFor('H2'), 'H2''s own line must be untouched');
    end;

    // ARM 7. New() on an EMPTY top-level list page, not a part. The open cost is measured, not
    // asserted; the claim is the delta New() adds, and that the write after it adds nothing.
    [Test]
    procedure ListPage_New_OnEmptyList_RunsOnNewRecordOnceMoreThanTheOpen()
    var
        List: TestPage "ONRC Line List";
        AfterOpen: Integer;
        AfterNew: Integer;
    begin
        Initialize();

        List.OpenEdit();
        AfterOpen := OnNewRecordCount();

        List.New();

        AfterNew := OnNewRecordCount();
        Assert.AreEqual(AfterOpen + 1, AfterNew,
            'New() on an empty list page must raise OnNewRecord exactly once more than opening it did');

        List.Descr.SetValue('typed after New');
        List.Close();

        Assert.AreEqual(AfterNew, OnNewRecordCount(),
            'writing into the row New() started must not raise OnNewRecord again');
        Assert.AreEqual(1, LineCountFor(''), 'exactly one line must have been written');
    end;

    // ARM 8, the control for arm 7. The same list page with a row, standing on that row: New()
    // costs exactly one more than whatever opening and landing on the row cost.
    [Test]
    procedure ListPage_New_OnDataRow_RunsOnNewRecordExactlyOnce()
    var
        List: TestPage "ONRC Line List";
        OnRow: Integer;
    begin
        Initialize();
        AddLine('', 10000, 'seeded');

        List.OpenEdit();
        Assert.IsTrue(List.First(), 'the list must land on its seeded row');
        OnRow := OnNewRecordCount();

        List.New();
        Assert.AreEqual(OnRow + 1, OnNewRecordCount(),
            'New() from an existing data row must raise OnNewRecord exactly once');

        List.Descr.SetValue('typed after New');
        List.Close();

        Assert.AreEqual(OnRow + 1, OnNewRecordCount(), 'the write must not raise OnNewRecord again');
        Assert.AreEqual(2, LineCountFor(''), 'the row New() started must be a second line');
    end;
}
