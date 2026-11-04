// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-testpage-class
// Scope: in-scope
// Fixtures used: BNR Header (69940), BNR Line (69941), BNR Kind (enum 69940), BNR Lines Part (69940),
//                BNR Card (69941), BNR Lines List (69942), BNR Line Card (69943), BNR Temp List (69944),
//                BNR Temp Open List (69945), BNR Get List (69946), BNR Real List (69948); shared Assert (60021)
//
// WHAT does a control read when its part or page shows NO row?
// The first revisions of this file recorded the readings of one control of every field type
// instead of asserting them. Measured on real BC (every cloud leg): every control reads the empty
// string, whatever its type: Text, Code, Integer, Decimal, Boolean, Option, Date, Time, DateTime,
// Enum, BigInteger, Guid, Duration, and the fields that declare an InitValue. The typed accessors
// answer the type's default (AsInteger 0, AsDecimal 0, AsBoolean false, AsDate 0D, AsTime 0T),
// also on a field with an InitValue.
// This holds for a part whose link matches no row (the host moved to a row with no lines, or the
// host has no row at all), for a list and a card over an empty table, and for a list filtered to
// nothing. It does NOT hold for the draft line of an editable page, which is a row: there the
// controls read the defaults the line was started with (QInt 0, QIntInit its InitValue 5).
//
// A page that showed no row shows one again once page code has put a row into its rowset and
// positioned Rec on it (the NoRow_Action_ arms: a temporary-source list filled by an action, the shape
// of Navigate). Page code that only changes the buffer, sets a key it never inserts, or Gets a row the
// page's filter hides, shows nothing; neither does a row test code inserts after the page opened.
// A top-level card over an empty table reads blank with OpenEdit and its defaults with OpenNew.
//
// NOT pinned here, on purpose: AsDateTime() on a control with no row raises an unhandled CLR
// NullReferenceException on BC (BC unboxes a null into a DateTime), and the text of that failure is
// not something an AL test should assert. Nor is which row First() shows after test code inserted rows behind
// the page's back: BC stayed blank (the page keeps the rowset it loaded), the runner re-queries. The Value of a populated Date/Time/DateTime/Guid/Duration
// control is not asserted either; its spelling is not this file's claim.
codeunit 69940 "BNR Blank Part Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "BNR Header";
        Line: Record "BNR Line";
    begin
        Line.DeleteAll();
        Header.DeleteAll();
        Header.Init();
        Header."No." := 'H0';
        Header.Insert();
        Header.Init();
        Header."No." := 'H1';
        Header.Insert();
    end;

    local procedure InsertFullLine(HeaderNo: Code[20]; LineNo: Integer)
    var
        Line: Record "BNR Line";
    begin
        Line.Init();
        Line."Header No." := HeaderNo;
        Line."Line No." := LineNo;
        Line.QTxt := 'text';
        Line.QCd := 'CODE';
        Line.QInt := 42;
        Line.QDec := 3.25;
        Line.QBool := true;
        Line.QOpt := Line.QOpt::Gamma;
        Line.QDt := DMY2Date(2, 3, 2024);
        Line.QTm := 123456T;
        Line.QDtTm := CreateDateTime(DMY2Date(2, 3, 2024), 123456T);
        Line.QEn := Line.QEn::One;
        Line.QBig := 9000000000L;
        Line.QGd := '{11111111-2222-3333-4444-555555555555}';
        Line.QDur := 5000;
        Line.QIntInit := 7;
        Line.QDecInit := 7.5;
        Line.QBoolInit := false;
        Line.Insert();
    end;

    local procedure ObsPart(var Card: TestPage "BNR Card"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.Lines.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.Lines.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.Lines.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.Lines.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.Lines.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.Lines.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.Lines.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.Lines.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.Lines.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.Lines.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.Lines.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.Lines.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.Lines.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.Lines.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.Lines.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.Lines.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.Lines.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.Lines.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure ObsList(var Card: TestPage "BNR Lines List"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure ObsLCard(var Card: TestPage "BNR Line Card"): Text
    var
        Obs: Text;
    begin
        Obs += 'HeaderNo=[' + Card.HeaderNo.Value + '] ';
        Obs += 'LineNo=[' + Card.LineNo.Value + '] ';
        Obs += 'QTxt=[' + Card.QTxt.Value + '] ';
        Obs += 'QCd=[' + Card.QCd.Value + '] ';
        Obs += 'QInt=[' + Card.QInt.Value + '] ';
        Obs += 'QDec=[' + Card.QDec.Value + '] ';
        Obs += 'QBool=[' + Card.QBool.Value + '] ';
        Obs += 'QOpt=[' + Card.QOpt.Value + '] ';
        Obs += 'QDt=[' + Card.QDt.Value + '] ';
        Obs += 'QTm=[' + Card.QTm.Value + '] ';
        Obs += 'QDtTm=[' + Card.QDtTm.Value + '] ';
        Obs += 'QEn=[' + Card.QEn.Value + '] ';
        Obs += 'QBig=[' + Card.QBig.Value + '] ';
        Obs += 'QGd=[' + Card.QGd.Value + '] ';
        Obs += 'QDur=[' + Card.QDur.Value + '] ';
        Obs += 'QIntInit=[' + Card.QIntInit.Value + '] ';
        Obs += 'QDecInit=[' + Card.QDecInit.Value + '] ';
        Obs += 'QBoolInit=[' + Card.QBoolInit.Value + '] ';
        exit(Obs);
    end;

    local procedure AssertPartBlank(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual('', Card.Lines.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.Lines.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.Lines.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.Lines.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.Lines.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.Lines.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.Lines.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.Lines.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.Lines.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.Lines.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.Lines.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.Lines.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.Lines.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.Lines.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.Lines.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.Lines.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.Lines.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.Lines.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertPartTypedDefaults(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual(0, Card.Lines.QInt.AsInteger(), 'AsInteger');
        Assert.AreEqual(0, Card.Lines.QDec.AsDecimal(), 'AsDecimal');
        Assert.IsFalse(Card.Lines.QBool.AsBoolean(), 'AsBoolean');
        Assert.AreEqual(0D, Card.Lines.QDt.AsDate(), 'AsDate');
        Assert.AreEqual(0T, Card.Lines.QTm.AsTime(), 'AsTime');
        Assert.AreEqual(0, Card.Lines.QIntInit.AsInteger(), 'AsInteger of a field with an InitValue');
        Assert.AreEqual(0, Card.Lines.QDecInit.AsDecimal(), 'AsDecimal of a field with an InitValue');
        Assert.IsFalse(Card.Lines.QBoolInit.AsBoolean(), 'AsBoolean of a field with an InitValue');
    end;

    local procedure AssertListBlank(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual('', Card.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertListTypedDefaults(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'AsInteger');
        Assert.AreEqual(0, Card.QDec.AsDecimal(), 'AsDecimal');
        Assert.IsFalse(Card.QBool.AsBoolean(), 'AsBoolean');
        Assert.AreEqual(0D, Card.QDt.AsDate(), 'AsDate');
        Assert.AreEqual(0T, Card.QTm.AsTime(), 'AsTime');
        Assert.AreEqual(0, Card.QIntInit.AsInteger(), 'AsInteger of a field with an InitValue');
        Assert.AreEqual(0, Card.QDecInit.AsDecimal(), 'AsDecimal of a field with an InitValue');
        Assert.IsFalse(Card.QBoolInit.AsBoolean(), 'AsBoolean of a field with an InitValue');
    end;

    local procedure AssertLineCardBlank(var Card: TestPage "BNR Line Card")
    begin
        Assert.AreEqual('', Card.HeaderNo.Value, 'HeaderNo reads blank');
        Assert.AreEqual('', Card.LineNo.Value, 'LineNo reads blank');
        Assert.AreEqual('', Card.QTxt.Value, 'QTxt reads blank');
        Assert.AreEqual('', Card.QCd.Value, 'QCd reads blank');
        Assert.AreEqual('', Card.QInt.Value, 'QInt reads blank');
        Assert.AreEqual('', Card.QDec.Value, 'QDec reads blank');
        Assert.AreEqual('', Card.QBool.Value, 'QBool reads blank');
        Assert.AreEqual('', Card.QOpt.Value, 'QOpt reads blank');
        Assert.AreEqual('', Card.QDt.Value, 'QDt reads blank');
        Assert.AreEqual('', Card.QTm.Value, 'QTm reads blank');
        Assert.AreEqual('', Card.QDtTm.Value, 'QDtTm reads blank');
        Assert.AreEqual('', Card.QEn.Value, 'QEn reads blank');
        Assert.AreEqual('', Card.QBig.Value, 'QBig reads blank');
        Assert.AreEqual('', Card.QGd.Value, 'QGd reads blank');
        Assert.AreEqual('', Card.QDur.Value, 'QDur reads blank');
        Assert.AreEqual('', Card.QIntInit.Value, 'QIntInit reads blank');
        Assert.AreEqual('', Card.QDecInit.Value, 'QDecInit reads blank');
        Assert.AreEqual('', Card.QBoolInit.Value, 'QBoolInit reads blank');
    end;

    local procedure AssertListDraftLine(var Card: TestPage "BNR Lines List")
    begin
        Assert.AreEqual('0', Card.QInt.Value, 'QInt reads its default on the draft line');
        Assert.AreEqual('0.00', Card.QDec.Value, 'QDec');
        Assert.AreEqual('No', Card.QBool.Value, 'QBool');
        Assert.AreEqual('Alpha', Card.QOpt.Value, 'QOpt');
        Assert.AreEqual('Zero', Card.QEn.Value, 'QEn');
        Assert.AreEqual('0', Card.QBig.Value, 'QBig');
        Assert.AreEqual('5', Card.QIntInit.Value, 'QIntInit reads its InitValue');
        Assert.AreEqual('2.50', Card.QDecInit.Value, 'QDecInit reads its InitValue');
        Assert.AreEqual('Yes', Card.QBoolInit.Value, 'QBoolInit reads its InitValue');
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'AsInteger on the draft line');
    end;

    local procedure AssertPartDraftLine(var Card: TestPage "BNR Card")
    begin
        Assert.AreEqual('0', Card.Lines.QInt.Value, 'QInt reads its default on the draft line');
        Assert.AreEqual('0.00', Card.Lines.QDec.Value, 'QDec');
        Assert.AreEqual('No', Card.Lines.QBool.Value, 'QBool');
        Assert.AreEqual('Alpha', Card.Lines.QOpt.Value, 'QOpt');
        Assert.AreEqual('Zero', Card.Lines.QEn.Value, 'QEn');
        Assert.AreEqual('0', Card.Lines.QBig.Value, 'QBig');
        Assert.AreEqual('5', Card.Lines.QIntInit.Value, 'QIntInit reads its InitValue');
        Assert.AreEqual('2.50', Card.Lines.QDecInit.Value, 'QDecInit reads its InitValue');
        Assert.AreEqual('Yes', Card.Lines.QBoolInit.Value, 'QBoolInit reads its InitValue');
        Assert.AreEqual(0, Card.Lines.QInt.AsInteger(), 'AsInteger on the draft line');
    end;

    // CLAIM: a part whose link matches no row reads blank in every control.
    [Test]
    procedure NoRow_Part_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        AssertPartBlank(Card);
    end;

    // CLAIM: the typed accessors of such a control answer the type's default, also for a field whose
    // InitValue is not the default.
    [Test]
    procedure NoRow_Part_TypedReadsAreTheTypeDefault()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H0');
        AssertPartTypedDefaults(Card);
    end;

    // CLAIM: the part blanks while the host shows a row without lines and reads its row again after,
    // so the blank is the part's state and not a one-way latch.
    [Test]
    procedure NoRow_Part_ReadsBlankWhileTheHostShowsNoLines_AndItsValuesAgainAfter()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GoToKey('H1');
        Assert.AreEqual('42', Card.Lines.QInt.Value, 'a row is shown');
        Assert.AreEqual('7', Card.Lines.QIntInit.Value, 'a row is shown (InitValue field)');
        Assert.AreEqual(42, Card.Lines.QInt.AsInteger(), 'typed read of a shown row');

        Card.GoToKey('H0');
        AssertPartBlank(Card);

        Card.GoToKey('H1');
        Assert.AreEqual('42', Card.Lines.QInt.Value, 'a row is shown again');
        Assert.AreEqual('text', Card.Lines.QTxt.Value, 'a row is shown again (text)');
    end;

    // CLAIM: a part of a host that has no row at all reads blank too.
    [Test]
    procedure NoRow_PartOfAHostOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Card";
        Header: Record "BNR Header";
        Line: Record "BNR Line";
    begin
        Initialize();
        Header.DeleteAll();
        Line.DeleteAll();
        Card.OpenView();
        AssertPartBlank(Card);
    end;

    // CLAIM: a list over an empty table reads blank in every control, and so do its typed accessors.
    [Test]
    procedure NoRow_ListOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        AssertListBlank(Card);
        AssertListTypedDefaults(Card);
    end;

    // CLAIM: First() and Last() on that list answer false and leave it showing no row.
    [Test]
    procedure NoRow_ListOverAnEmptyTable_AfterFirstAndLast_StillReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenView();
        Assert.IsFalse(Card.First(), 'First() has no row to go to');
        AssertListBlank(Card);
        Assert.IsFalse(Card.Last(), 'Last() has no row to go to');
        AssertListBlank(Card);
    end;

    // CONTRAST: the same list with a row reads that row, so the blank above is the absence of a row.
    [Test]
    procedure NoRow_Contrast_ListWithARow_ReadsItsValues()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Assert.AreEqual('42', Card.QInt.Value, 'a row is shown');
        Assert.AreEqual('text', Card.QTxt.Value, 'a row is shown (text)');
        Assert.AreEqual('7', Card.QIntInit.Value, 'a row is shown (InitValue field)');
    end;

    // CLAIM: a card over an empty table reads blank in every control.
    [Test]
    procedure NoRow_CardOverAnEmptyTable_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Line Card";
    begin
        Initialize();
        Card.OpenView();
        AssertLineCardBlank(Card);
    end;

    // CLAIM: a list filtered to nothing reads blank.
    [Test]
    procedure NoRow_ListFilteredToNothing_EveryControlReadsBlank()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.Filter.SetFilter("Header No.", 'ZZZ');
        AssertListBlank(Card);
    end;

    // CONTRAST: the draft line of an editable list over an empty table is a row, whose controls read
    // the defaults it was started with.
    [Test]
    procedure NoRow_Contrast_EditableListOverAnEmptyTable_ShowsTheDraftLine_ReadingItsDefaults()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        AssertListDraftLine(Card);
    end;

    // CONTRAST: and so is the draft line of a part under an editable host.
    [Test]
    procedure NoRow_Contrast_PartUnderAnEditableHostWithNoLines_ShowsTheDraftLine_ReadingItsDefaults()
    var
        Card: TestPage "BNR Card";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenEdit();
        Card.GoToKey('H0');
        Assert.AreEqual('H0', Card.Lines.HeaderNo.Value, 'the draft line carries the link value');
        AssertPartDraftLine(Card);
    end;

    // CLAIM: a row started with New() on an empty editable list reads the values written to it.
    [Test]
    procedure NoRow_Contrast_NewRowOnAnEmptyEditableList_ReadsTheValuesWrittenToIt()
    var
        Card: TestPage "BNR Lines List";
    begin
        Initialize();
        Card.OpenEdit();
        Card.New();
        Card.HeaderNo.SetValue('X');
        Card.LineNo.SetValue(1);
        Card.QInt.SetValue(5);
        Assert.AreEqual('5', Card.QInt.Value, 'the new row reads what was written');
        Assert.AreEqual(5, Card.QInt.AsInteger(), 'typed read of the new row');
        Assert.AreEqual('X', Card.HeaderNo.Value, 'the new row reads its key');
    end;

    // The actions below fill and position Rec from AL, the shape of Navigate: a list over a temporary
    // source table that shows nothing when it opens, then an action inserts rows and positions Rec.
    // CLAIM: once page code has put a row into the rowset and positioned Rec on it, the page shows
    // that row, whether or not the page showed nothing before.
    [Test]
    procedure NoRow_Action_TempListInsertAndFind_ShowsTheRow()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Assert.AreEqual('', Card.QInt.Value, 'no row before the action');
        Card.InsertFind.Invoke();
        Assert.AreEqual('T', Card.HeaderNo.Value, 'the row the action inserted is shown');
        Assert.AreEqual('1', Card.LineNo.Value, 'its line');
        Assert.AreEqual('found', Card.QTxt.Value, 'its text');
        Assert.AreEqual('7', Card.QInt.Value, 'its integer');
        Assert.AreEqual(7, Card.QInt.AsInteger(), 'and its typed read');
    end;

    // CLAIM: the same when the action also calls CurrPage.Update.
    [Test]
    procedure NoRow_Action_TempListInsertFindUpdate_ShowsTheRow()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Card.InsertFindUpdate.Invoke();
        Assert.AreEqual('7', Card.QInt.Value, 'the row is shown after CurrPage.Update');
        Assert.AreEqual('found', Card.QTxt.Value, 'its text');
    end;

    // CLAIM: an Insert alone leaves Rec on the inserted row, and the page shows it.
    [Test]
    procedure NoRow_Action_TempListInsertOnly_ShowsTheRow()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Card.InsertOnly.Invoke();
        Assert.AreEqual('7', Card.QInt.Value, 'the inserted row is shown');
    end;

    // CLAIM: two inserts and a FindLast: the page shows the row Rec stands on, and First() shows the other.
    [Test]
    procedure NoRow_Action_TempListTwoInsertsAndFindLast_ShowsTheLastRow()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Card.InsertTwoFindLast.Invoke();
        Assert.AreEqual('2', Card.QInt.Value, 'Rec stands on the second row');
        Card.First();
        Assert.AreEqual('1', Card.QInt.Value, 'First() shows the first row');
    end;

    // CLAIM: the same on a list over the stored table.
    [Test]
    procedure NoRow_Action_StoredListInsertAndFind_ShowsTheRow()
    var
        Card: TestPage "BNR Real List";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenView();
        Assert.AreEqual('', Card.QInt.Value, 'no row before the action');
        Card.InsertFind.Invoke();
        Assert.AreEqual('4', Card.QInt.Value, 'the inserted row is shown');
        Assert.AreEqual('R', Card.HeaderNo.Value, 'its key');
    end;

    // CLAIM: an insert of a row the page's filter lets through, positioned on, is shown.
    [Test]
    procedure NoRow_Action_InsertOfARowTheFilterAdmits_ShowsTheRow()
    var
        Card: TestPage "BNR Get List";
    begin
        Initialize();
        Card.OpenView();
        Assert.AreEqual('', Card.QInt.Value, 'no row before the action');
        Card.InsertMatching.Invoke();
        Assert.AreEqual('3', Card.QInt.Value, 'the inserted row is shown');
        Assert.AreEqual('ZZZ', Card.HeaderNo.Value, 'its key');
    end;

    // CONTRAST: page code that changes only the buffer, with no row in the rowset, shows nothing.
    [Test]
    procedure NoRow_Action_TempListFieldsOnly_StaysBlank()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Card.FieldsOnly.Invoke();
        Assert.AreEqual('', Card.QInt.Value, 'QInt');
        Assert.AreEqual('', Card.QTxt.Value, 'QTxt');
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'typed');
    end;

    // CONTRAST: and so does a key set on Rec that was never inserted.
    [Test]
    procedure NoRow_Action_TempListKeyOnlyNoInsert_StaysBlank()
    var
        Card: TestPage "BNR Temp List";
    begin
        Initialize();
        Card.OpenView();
        Card.KeyOnly.Invoke();
        Assert.AreEqual('', Card.HeaderNo.Value, 'the key');
        Assert.AreEqual('', Card.QInt.Value, 'QInt');
    end;

    // CONTRAST: Get of a stored row the page's filter hides leaves the page showing nothing.
    [Test]
    procedure NoRow_Action_GetOfARowTheFilterHides_StaysBlank()
    var
        Card: TestPage "BNR Get List";
    begin
        Initialize();
        InsertFullLine('H1', 10);
        Card.OpenView();
        Card.GetRow.Invoke();
        Assert.AreEqual('', Card.QInt.Value, 'Rec is on a stored row the page filters out');
        Assert.AreEqual('', Card.QTxt.Value, 'its text');
    end;

    // CONTRAST: a row that test code inserts after the page opened is not shown before the list moves.
    [Test]
    procedure NoRow_TestCodeInsertAfterOpen_StaysBlankUntilTheListMoves()
    var
        Card: TestPage "BNR Real List";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenView();
        Line.Init();
        Line."Header No." := 'R';
        Line."Line No." := 9;
        Line.QTxt := 'late';
        Line.QInt := 6;
        Line.Insert();
        Assert.AreEqual('', Card.QInt.Value, 'the page has not seen the new row');
        Assert.AreEqual('', Card.QTxt.Value, 'its text');
    end;

    // CLAIM: rows a temporary-source page inserts in its own OnOpenPage are shown, not blank.
    [Test]
    procedure NoRow_TempListInsertingInOnOpenPage_ShowsARow()
    var
        Card: TestPage "BNR Temp Open List";
    begin
        Initialize();
        Card.OpenView();
        Assert.AreEqual('T', Card.HeaderNo.Value, 'a row the page inserted is shown');
        Assert.AreNotEqual('', Card.QInt.Value, 'its integer is not blank');
    end;

    // CLAIM: a card over an empty table opened for editing reads blank (a card has no draft line) ...
    [Test]
    procedure NoRow_Card_OpenEditOverAnEmptyTable_ReadsBlank()
    var
        Card: TestPage "BNR Line Card";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenEdit();
        AssertLineCardBlank(Card);
    end;

    // ... and one opened with OpenNew reads the defaults of the new record.
    [Test]
    procedure NoRow_Contrast_CardOpenNewOverAnEmptyTable_ReadsItsDefaults()
    var
        Card: TestPage "BNR Line Card";
        Line: Record "BNR Line";
    begin
        Initialize();
        Line.DeleteAll();
        Card.OpenNew();
        Assert.AreEqual('', Card.HeaderNo.Value, 'the key is blank');
        Assert.AreEqual('0', Card.LineNo.Value, 'the integer key reads its default');
        Assert.AreEqual('0', Card.QInt.Value, 'QInt reads its default');
        Assert.AreEqual('5', Card.QIntInit.Value, 'QIntInit reads its InitValue');
        Assert.AreEqual(0, Card.QInt.AsInteger(), 'typed');
    end;
}
