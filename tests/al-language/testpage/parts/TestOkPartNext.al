// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpart/testpart-next-method
// Scope: in-scope
// Fixtures used: OKP Header (60760), OKP Line (60761), OKP Header Card (60760),
//                OKP Lines Part (60761), OKP Read-Only Header Card (60013),
//                OKP Read-Only Lines Part (60014), ALT TestPart Row (60341), ALT TestPart Host (60344),
//                Assert (60021)
//
// WHERE does a part's FIRST Next() land when nothing has navigated the part yet?
//
// "Test TestPart" (60346) walks a part with Next() only after First() or Last(). This codeunit
// pins the unpositioned case: right after the host opens, and right after the host moves with
// GoToKey. Measured on a service tier (27.0 through 28.5): the part already reads its FIRST
// row, and the first Next() steps PAST it to the SECOND row -- the same as Next() after
// First(). It does not move "onto" the row the part already shows. On an editable host a
// second Next() then lands on the part's new-row line, which reads blank.
//
// Two headers with two lines each, and every line's Reference names its header and line, so
// a part that ignored the link or stayed on the first header's rows fails on the value.
//
// Filed from AlRunner#4623 (a first draft asserted the opposite and was red on every leg).
codeunit 60229 "OKP Part Next Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Line: Record "OKP Line";
        Header: Record "OKP Header";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        AddHeader('H1');
        AddLine('H1', 10000, 'H1-FIRST');
        AddLine('H1', 20000, 'H1-SECOND');
        AddHeader('H2');
        AddLine('H2', 10000, 'H2-FIRST');
        AddLine('H2', 20000, 'H2-SECOND');
    end;

    local procedure AddHeader(HeaderCode: Code[20])
    var
        Header: Record "OKP Header";
    begin
        Header.Init();
        Header."Code" := HeaderCode;
        Header.Descr := HeaderCode;
        Header.Insert();
    end;

    local procedure AddLine(HeaderCode: Code[20]; LineNo: Integer; Reference: Text[30])
    var
        Line: Record "OKP Line";
    begin
        Line.Init();
        Line."Header Code" := HeaderCode;
        Line."Line No." := LineNo;
        Line.Reference := Reference;
        Line.Insert();
    end;

    // CLAIM: host opened, moved to another header by GotoKey, then one Next() on the part: it
    // answers true and lands on that header's SECOND line, not its first.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_FirstNextLandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'the first Next() after the host''s GotoKey must step past the first row to the second');
        Card.Close();
    end;

    // CLAIM: on an editable host the second Next() then moves past the last line onto the
    // part's new-row line: it answers true and the line reads blank.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_SecondNextLandsOnTheNewRowLine()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Card.Lines.Next();
        Assert.IsTrue(Card.Lines.Next(), 'the second Next() on an editable part must answer true (new-row line)');
        Assert.AreEqual('', Card.Lines.Reference.Value(),
            'the second Next() after the host''s GotoKey must land on the blank new-row line');
        Card.Close();
    end;

    // CLAIM: before any Next(), the part already READS as its first row. Unpositioned is about
    // where the next move goes, not about what the controls show.
    [Test]
    procedure LinkedPart_AfterHostGotoKey_ReadsTheFirstRowBeforeAnyNext()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Assert.AreEqual('H2-FIRST', Card.Lines.Reference.Value(),
            'before any navigation the part must read its first row');
        Card.Close();
    end;

    // CLAIM: the same holds on a read-only host, which is how Microsoft's tests open a posted
    // document: the first Next() lands on the second line.
    [Test]
    procedure LinkedPart_OpenView_AfterHostGotoKey_FirstNextLandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenView();
        Card.GoToKey('H2');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'on a read-only host the first Next() after GotoKey must land on the part''s second row');
        Card.Close();
    end;

    // CLAIM: with no host move at all -- the host has just opened on its first header -- the
    // part's first Next() also lands on its second row.
    [Test]
    procedure LinkedPart_AtOpen_FirstNextLandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Assert.AreEqual('H1', Card."Code".Value(), 'the card must open on the lowest header');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('H1-SECOND', Card.Lines.Reference.Value(),
            'the first Next() after the host opens must land on the part''s second row');
        Card.Close();
    end;

    // CONTROL: with First() first, Next() also steps to the SECOND row -- so the unpositioned
    // part above behaves exactly as if it stood on its first row.
    [Test]
    procedure LinkedPart_FirstThenNext_LandsOnTheSecondRow()
    var
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Card.Lines.First();
        Assert.IsTrue(Card.Lines.Next(), 'Next() after First() must answer true while a second row exists');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'Next() after First() must land on the part''s second row');
        Card.Close();
    end;

    // CONTROL: after New() and a write on a part nothing had positioned, Next() steps on from
    // the new row to the SECOND existing row.
    [Test]
    procedure LinkedPart_NewThenWriteThenNext_LandsOnTheSecondRow()
    var
        Line: Record "OKP Line";
        Card: TestPage "OKP Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Assert.AreEqual('H1', Card."Code".Value(), 'the card must open on the lowest header');
        Card.Lines.New();
        Card.Lines.Reference.SetValue('H1-NEW');
        Assert.IsTrue(Card.Lines.Next(), 'Next() after a new row must answer true while a row follows it');
        Assert.AreEqual('H1-SECOND', Card.Lines.Reference.Value(),
            'Next() after New() and a write must land on the row after the new one, not on the first row');
        Card.Close();

        Line.SetRange("Header Code", 'H1');
        Line.SetRange(Reference, 'H1-NEW');
        Assert.AreEqual(1, Line.Count(), 'the new row must have been saved under the host''s header');
    end;

    // CLAIM: a part with no SubPageLink behaves the same way at open -- the first Next() lands
    // on the second row of its own rowset.
    [Test]
    procedure UnlinkedPart_AtOpen_FirstNextLandsOnTheSecondRow()
    var
        Row: Record "ALT TestPart Row";
        Host: TestPage "ALT TestPart Host";
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
        Row.Descr := 'Beta';
        Row.Insert();

        Host.OpenEdit();
        Assert.IsTrue(Host.Lines.Next(), 'the first Next() on a part with rows must answer true');
        Assert.AreEqual('20', Host.Lines.LineNo.Value(),
            'the first Next() after the host opens must land on the unlinked part''s second row');
        Host.Close();
    end;

    // CLAIM: a part page declared Editable = false behaves the same way: after the host's
    // GotoKey the part reads its first row, and the first Next() lands on the second row.
    [Test]
    procedure ReadOnlyPart_AfterHostGotoKey_FirstNextLandsOnTheSecondRow()
    var
        Card: TestPage "OKP Read-Only Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Assert.AreEqual('H2-FIRST', Card.Lines.Reference.Value(),
            'before any navigation the read-only part must read its first row');
        Assert.IsTrue(Card.Lines.Next(), 'the first Next() on a read-only part with two rows must answer true');
        Assert.AreEqual('H2-SECOND', Card.Lines.Reference.Value(),
            'the first Next() after the host''s GotoKey must land on the read-only part''s second row');
        Card.Close();
    end;

    // CLAIM: a read-only part has no new-row line, so after the first Next() lands on the last
    // of two rows, a second Next() answers false.
    [Test]
    procedure ReadOnlyPart_AfterHostGotoKey_SecondNextAnswersFalse()
    var
        Card: TestPage "OKP Read-Only Header Card";
    begin
        Initialize();
        Card.OpenEdit();
        Card.GoToKey('H2');
        Card.Lines.Next();
        Assert.IsFalse(Card.Lines.Next(), 'a second Next() on a two-row read-only part must answer false');
        Card.Close();
    end;
}
