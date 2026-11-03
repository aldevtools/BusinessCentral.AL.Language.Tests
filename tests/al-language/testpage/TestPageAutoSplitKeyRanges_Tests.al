// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-autosplitkey-property
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-new-method
// Scope: in-scope
// Fixtures used: ASK Header (60915), ASK Line (60916), ASK Card (60920),
//   ASK Big Line (60923), ASK Big Lines (60924), ASK Big Card (60925),
//   ASK Dec Line (60926), ASK Dec Lines (60927), ASK Dec Card (60928); shared Assert (60021)
// BC versions: 27.5+
//
// AutoSplitKey beyond the append: what number does a row get when it is NOT simply added
// after the last line? CU60922 pins the append cases (empty grid -> 20000, last + 10000);
// this codeunit measures the remaining shapes of the same property: an insert BETWEEN two
// existing lines, lines with negative numbers, and the two other numeric key types the
// property supports.
//
// The expected values below are predictions, written to be adjudicated by this repo's CI
// against a real service tier. They are derived from the algorithm the platform's own key
// generator uses, which is NOT "split the gap at the midpoint":
//
//   new = lower + min((upper - lower) / 2, 10000)
//
// i.e. the step above the lower neighbour is CAPPED at one 10000 interval, however wide the
// gap. Two cases below are chosen precisely because the models disagree:
//
//   between 50000 and 70000 -> 60000   (midpoint and capped-step agree; the baseline)
//   between 10000 and 90000 -> 20000   (midpoint would say 50000; the cap says 20000)
//   single line at -10000   -> -6667   (a plain "last + 10000" would say 0 and a halved
//                                       range would say -5000; MEASURED as -6667: the
//                                       range [ -10000 .. 0 ] is split in THREE, because
//                                       the grid's trailing blank placeholder row counts
//                                       as a row after the insert when the insert is at
//                                       the end of the rowset — 10000 / 3 = 3333 above
//                                       the lower line)
//   between -10000 and 10000 -> -1     (a range crossing zero reserves zero itself and
//                                       steps (range-1)/2 = 9999 above the lower bound,
//                                       landing at -1 rather than 0 — and NOT -6667's
//                                       three-way split: mid-grid the placeholder sits
//                                       beyond the upper line and does not participate)
//
// If a measured run disagrees with any of these, the measurement wins and the assertion
// must be corrected to what BC actually assigns — the point of this file is to replace
// derivation with measurement. That happened once already: the single-negative case was
// first predicted as -5000 and corrected to the measured -6667 (identical on 27.5 and
// 28.3), which is what pinned the placeholder's role in the divisor.
//
// The BigInteger and Decimal cases pin that the arithmetic runs in the key field's own
// type: the BigInteger seed does not fit in an Integer at all, and the Decimal seed
// carries a fraction that an integer step could not preserve. Both types still start an
// empty grid at 20000 (the empty-grid placeholder interval is a property of the grid, not
// of the key type).

codeunit 60929 "ASK Range Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        BigLine: Record "ASK Big Line";
        DecLine: Record "ASK Dec Line";
    begin
        Line.DeleteAll();
        BigLine.DeleteAll();
        DecLine.DeleteAll();
        Header.DeleteAll();
    end;

    local procedure GivenHeader(HeaderNo: Code[20]) Header: Record "ASK Header"
    begin
        Header.Init();
        Header."No." := HeaderNo;
        Header.Insert();
    end;

    local procedure GivenLine(HeaderNo: Code[20]; LineNo: Integer; DescrText: Text[50])
    var
        Line: Record "ASK Line";
    begin
        Line.Init();
        Line."No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.Descr := DescrText;
        Line.Insert();
    end;

    // Positive: the baseline mid-grid insert, where the capped-step and midpoint models
    // agree — inserting between 50000 and 70000 lands at 60000. Establishes that New() on
    // a cursor positioned mid-grid splits the interval at all (rather than appending),
    // before the discriminating cases below establish HOW.
    [Test]
    procedure TestPage_New_BetweenLines50000And70000_LandsAt60000()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        GivenLine('H1', 50000, 'lower');
        GivenLine('H1', 70000, 'upper');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('between');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(3, Line.Count(), 'both seeded lines and the inserted one');
        Assert.IsTrue(Line.Get('H1', 60000), 'a line inserted between 50000 and 70000 must land at 60000');
        Assert.AreEqual('between', Line.Descr, 'and it must be the line the test entered');
    end;

    // Positive AND the discriminator: between 10000 and 90000 the midpoint model says
    // 50000, the capped-step model says 10000 + min(80000/2, 10000) = 20000. Only one of
    // them can pass; the seeds are chosen so the wrong model lands nowhere near the right
    // answer.
    [Test]
    procedure TestPage_New_BetweenLines10000And90000_StepsOneIncrementTo20000()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        GivenLine('H1', 10000, 'lower');
        GivenLine('H1', 90000, 'upper');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('capped');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(3, Line.Count(), 'both seeded lines and the inserted one');
        Assert.IsTrue(Line.Get('H1', 20000),
            'a wide gap is stepped one 10000 interval above the lower line, not split at the midpoint');
        Assert.AreEqual('capped', Line.Descr, 'and it must be the line the test entered');
    end;

    // Negative-key territory: a grid holding only a line at -10000. A plain "last + 10000"
    // would assign 0, and halving the range up to zero would give -5000; BC measures -6667
    // (identically on 27.5 and 28.3): the range is split in three, the trailing blank
    // placeholder row counting as a third occupant because the insert sits at the end of
    // the rowset. This pins both that negative keys do not fall back to the empty-grid
    // constant and that the placeholder participates in the divisor here — the same
    // placeholder the empty-grid 20000 comes from.
    [Test]
    procedure TestPage_New_AfterSingleNegativeLine_LandsAtMinus6667()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        GivenLine('H1', -10000, 'negative');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('after negative');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(2, Line.Count(), 'the seeded line and the inserted one');
        // AreEqual on the found row, not IsTrue(Get(...)), so a failing run REPORTS the
        // number BC assigned instead of only denying the predicted one.
        Line.SetFilter("Line No.", '<>%1', -10000);
        Assert.IsTrue(Line.FindFirst(), 'the inserted line must exist alongside the seeded one');
        Assert.AreEqual(-6667, Line."Line No.",
            'a line inserted after a single line at -10000 must land at -6667: the range up to zero split in three, the trailing placeholder row taking the third share');
        Assert.AreEqual('after negative', Line.Descr, 'and it must be the line the test entered');
    end;

    // The zero-crossing: between -10000 and 10000. Midpoint says 0; the prediction is that
    // a range crossing zero reserves zero itself and steps (20000 - 1) / 2 = 9999 above the
    // lower bound, landing at -1. Nothing else in the suite exercises a signed range, so
    // this is the case that decides whether zero is a value like any other here.
    [Test]
    procedure TestPage_New_BetweenMinus10000And10000_LandsAtMinusOne()
    var
        Header: Record "ASK Header";
        Line: Record "ASK Line";
        Card: TestPage "ASK Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        GivenLine('H1', -10000, 'lower');
        GivenLine('H1', 10000, 'upper');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.First();
        Card.Lines.New();
        Card.Lines.Descr.SetValue('crossing');
        Card.Close();

        Line.SetRange("No.", 'H1');
        Assert.AreEqual(3, Line.Count(), 'both seeded lines and the inserted one');
        Assert.IsTrue(Line.Get('H1', -1),
            'a line inserted between -10000 and 10000 must land at -1: zero is reserved and the step is (range - 1) / 2');
        Assert.AreEqual('crossing', Line.Descr, 'and it must be the line the test entered');
    end;

    // Positive: a BigInteger split key starts an empty grid at 20000, the same placeholder
    // interval CU60922 pins for Integer — the 20000 belongs to the grid, not the type.
    [Test]
    procedure TestPage_New_BigIntegerKey_EmptyGridStartsAt20000()
    var
        Header: Record "ASK Header";
        BigLine: Record "ASK Big Line";
        Card: TestPage "ASK Big Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('first big');
        Card.Close();

        BigLine.SetRange("No.", 'H1');
        Assert.AreEqual(1, BigLine.Count(), 'the one line the test entered');
        Assert.IsTrue(BigLine.Get('H1', 20000L), 'a BigInteger grid starts empty at 20000, like an Integer one');
        Assert.AreEqual('first big', BigLine.Descr, 'and it must be the line the test entered');
    end;

    // Positive: the append arithmetic runs in the key field's own 64-bit type. The seed is
    // above Integer's 2,147,483,647 ceiling, so a 32-bit path could not even represent the
    // lower bound, let alone land 10000 past it.
    [Test]
    procedure TestPage_New_BigIntegerKey_AppendsTenThousandPastTheIntegerCeiling()
    var
        Header: Record "ASK Header";
        BigLine: Record "ASK Big Line";
        Card: TestPage "ASK Big Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        BigLine.Init();
        BigLine."No." := 'H1';
        BigLine."Line No." := 5000000000L;
        BigLine.Descr := 'seeded big';
        BigLine.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('appended big');
        Card.Close();

        BigLine.Reset();
        BigLine.SetRange("No.", 'H1');
        Assert.AreEqual(2, BigLine.Count(), 'the seeded line and the appended one');
        Assert.IsTrue(BigLine.Get('H1', 5000010000L),
            'the appended line must be numbered 5000000000 + 10000, in 64-bit arithmetic');
        Assert.AreEqual('appended big', BigLine.Descr, 'and it must be the line the test entered');
    end;

    // Positive: a Decimal split key starts an empty grid at 20000 as well.
    [Test]
    procedure TestPage_New_DecimalKey_EmptyGridStartsAt20000()
    var
        Header: Record "ASK Header";
        DecLine: Record "ASK Dec Line";
        Card: TestPage "ASK Dec Card";
    begin
        Initialize();
        Header := GivenHeader('H1');

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('first dec');
        Card.Close();

        DecLine.SetRange("No.", 'H1');
        Assert.AreEqual(1, DecLine.Count(), 'the one line the test entered');
        Assert.IsTrue(DecLine.Get('H1', 20000.0), 'a Decimal grid starts empty at 20000, like an Integer one');
        Assert.AreEqual('first dec', DecLine.Descr, 'and it must be the line the test entered');
    end;

    // Positive: the append arithmetic runs in Decimal — the seeded fraction survives the
    // step. An integer-typed computation from 50000.5 could not land on 60000.5.
    [Test]
    procedure TestPage_New_DecimalKey_AppendKeepsTheFraction()
    var
        Header: Record "ASK Header";
        DecLine: Record "ASK Dec Line";
        Card: TestPage "ASK Dec Card";
    begin
        Initialize();
        Header := GivenHeader('H1');
        DecLine.Init();
        DecLine."No." := 'H1';
        DecLine."Line No." := 50000.5;
        DecLine.Descr := 'seeded dec';
        DecLine.Insert();

        Card.OpenEdit();
        Card.GoToRecord(Header);
        Card.Lines.New();
        Card.Lines.Descr.SetValue('appended dec');
        Card.Close();

        DecLine.Reset();
        DecLine.SetRange("No.", 'H1');
        Assert.AreEqual(2, DecLine.Count(), 'the seeded line and the appended one');
        Assert.IsTrue(DecLine.Get('H1', 60000.5),
            'the appended line must be numbered 50000.5 + 10000, keeping the fraction');
        Assert.AreEqual('appended dec', DecLine.Descr, 'and it must be the line the test entered');
    end;
}
