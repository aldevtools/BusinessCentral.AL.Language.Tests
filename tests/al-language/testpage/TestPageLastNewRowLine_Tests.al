// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-last-method
// Scope: in-scope
// Fixtures used: Test Page New Row Line Row (60737), Test Page New Row Line List (60738),
//   Test Page New Row Line RO (60739), Test Page New Row Line NoIns (60740),
//   Test Page New Row Line Part (60741), Test Page New Row Line Host (60742)
//
// Companion to codeunit 60743 "Test Page New Row Line Tests", which pinned the implicit
// new-row line from the FORWARD direction: Next() past the last data row lands on it and
// answers true, First() on an empty editable list answers false, and a field written into an
// empty editable list with no New() and no First() still inserts a row.
//
// It left Last() unmeasured, and Last() is the one cursor move whose relationship to that
// blank line cannot be derived from the others. The blank line is the LAST row the client
// shows, so "go to the last row" is exactly the call for which "the last data row" and "the
// last row of the rowset" are different answers -- and both are defensible readings.
//
// Codeunit 60756 "Test Page Previous" asserts Last() = false on an empty rowset, but through
// OpenView, where no new-row line exists at all. That settles nothing here: the whole question
// is what Last() does on a page that HAS the blank line.
//
// This file pins three separate things, because they can come apart:
//
//   1. WHERE Last() LANDS on a non-empty editable list -- the last DATA row, or the blank line
//      past it. Arm 1 reads a concrete value ('CHARLIE') and so fails either way round: it
//      reads blank if Last() lands on the draft line, and 'CHARLIE' if it lands on the data.
//
//   2. WHAT Last() RETURNS on an EMPTY editable list. First() answers false there (60743), and
//      an implementation could reasonably answer either way for Last() independently.
//
//   3. WHETHER A WRITE AFTER Last() INSERTS on that empty page. This is the arm that decides
//      the observable difference. 60743 already proved a write with NO cursor call at all
//      inserts a row; the open question is whether an explicit Last() that found nothing
//      leaves the cursor somewhere a write can still land, or moves it off that position.
//
// Points 1 and 2 are asserted AS A PAIR against First(): every arm below that calls Last() has
// a First() counterpart in the same procedure or in 60743, so an implementation that simply
// aliased the two cannot satisfy both. The three-row seed in arm 1 is what makes "last data
// row" and "new-row line" distinguishable at all -- with one row, a cursor sitting on the only
// data row and a cursor on the blank line after it are one step apart and an off-by-one reads
// as either.
//
// The gating arms (Editable = false, InsertAllowed = false, OpenView) are the same contrast
// 60743 uses: on a page with no blank line, Last() must land on the last data row, so an
// implementation that made Last() answer blank everywhere fails them.

codeunit 60757 "Test Page Last New Row Line"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page New Row Line Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedThreeRows()
    var
        Row: Record "Test Page New Row Line Row";
    begin
        Row.Init();
        Row."No." := 'ALPHA';
        Row.Descr := 'first row';
        Row.Insert();

        Row.Init();
        Row."No." := 'BRAVO';
        Row.Descr := 'second row';
        Row.Insert();

        Row.Init();
        Row."No." := 'CHARLIE';
        Row.Descr := 'third row';
        Row.Insert();
    end;

    // CLAIM 1. Where Last() lands on an editable, insert-allowed list that HAS data.
    //
    // Three seeded rows, so the last data row ('CHARLIE') and the blank line past it are two
    // distinct positions that no off-by-one can conflate. The First() assertion in the same
    // procedure is the pair: an implementation that treated First() and Last() identically
    // reads 'ALPHA' here and fails.
    [Test]
    procedure EditableInsertableList_Last_LandsOnTheLastDataRow()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedThreeRows();

        TP.OpenEdit();

        // First() is the anchor: it must land on the FIRST data row, so the Last() assertion
        // below is a statement about direction and not about a page that reads one value
        // everywhere.
        Assert.IsTrue(TP.First(), 'First() must land on the first seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'First() must land on ALPHA, the first data row');

        Assert.IsTrue(TP.Last(), 'Last() must find a row on a list with three data rows');
        Assert.AreEqual('CHARLIE', TP.RowNo.Value(),
            'Last() must land on the last DATA row, not on the blank new-row line past it');
        Assert.AreEqual('third row', TP.Descr.Value(),
            'every control on the row Last() landed on must read that row''s values');

        TP.Close();
    end;

    // CLAIM 1b. The blank line is still THERE after Last() -- Last() lands short of it, and
    // one Next() reaches it. Without this arm, arm 1 is also satisfied by a page that has no
    // new-row line at all, which is the opposite of what 60743 measured.
    [Test]
    procedure EditableInsertableList_NextAfterLast_ReachesTheNewRowLine()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedThreeRows();

        TP.OpenEdit();
        Assert.IsTrue(TP.Last(), 'Last() must find the last data row');
        Assert.AreEqual('CHARLIE', TP.RowNo.Value(), 'Last() must land on CHARLIE');

        Assert.IsTrue(TP.Next(),
            'the new-row line follows the last data row, so Next() after Last() must reach it');
        Assert.AreEqual('', TP.RowNo.Value(), 'the new-row line must read blank');
        Assert.AreEqual('', TP.Descr.Value(), 'the new-row line must read blank');

        Assert.IsFalse(TP.Next(), 'Next() from the new-row line must end the rowset');
        TP.Close();
    end;

    // CLAIM 2. What Last() returns on an EMPTY editable, insert-allowed list -- the mirror of
    // 60743's EmptyEditableList_FirstReturnsFalse, asserted here alongside First() so the two
    // are pinned as a pair in one procedure.
    [Test]
    procedure EmptyEditableList_LastReturnsFalse()
    var
        Row: Record "Test Page New Row Line Row";
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        Assert.AreEqual(0, Row.Count(), 'the arm needs a genuinely empty table');

        TP.OpenEdit();
        Assert.IsFalse(TP.First(),
            'First() on an empty editable list must return false (the claim 60743 already pins)');
        Assert.IsFalse(TP.Last(),
            'Last() on an empty editable list must return false -- there is no data row, and the blank new-row line is not one');
        TP.Close();
    end;

    // CLAIM 3, THE DECIDING ARM. A write after a Last() that found nothing.
    //
    // 60743's EmptyEditableList_SetValueWithoutNewOrFirst_InsertsARow proved that typing into
    // an empty editable list with NO cursor call inserts a row: the page opens with its cursor
    // already on the blank line. The open question is whether an explicit Last() that found
    // nothing leaves the cursor there too, or moves it somewhere a write cannot land.
    //
    // The two answers differ observably and this is the only arm that can tell them apart:
    // either Row.Count() is 1 and the typed values reached the table, or it is 0.
    [Test]
    procedure EmptyEditableList_SetValueAfterLast_InsertsARow()
    var
        Row: Record "Test Page New Row Line Row";
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();

        TP.OpenEdit();
        Assert.IsFalse(TP.Last(), 'Last() on an empty editable list must return false');

        TP.RowNo.SetValue('AFTERLAST');
        TP.Descr.SetValue('typed after a Last that found nothing');
        TP.Close();

        Assert.AreEqual(1, Row.Count(),
            'typing into an empty editable, insert-allowed list after a Last() that found nothing must insert exactly one row');
        Assert.IsTrue(Row.Get('AFTERLAST'), 'the row must be keyed by the value typed into the key column');
        Assert.AreEqual('typed after a Last that found nothing', Row.Descr,
            'the value typed after Last() must reach the backing table');
    end;

    // CLAIM 4. Last() must not create anything by itself. Merely asking for the last row of an
    // empty editable page writes nothing -- the client only turns the blank line into a record
    // once someone types into it (60743 NewRowLine_LeftUntouched_InsertsNothing, for Next()).
    [Test]
    procedure EmptyEditableList_LastLeftUntouched_InsertsNothing()
    var
        Row: Record "Test Page New Row Line Row";
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();

        TP.OpenEdit();
        Assert.IsFalse(TP.Last(), 'Last() on an empty editable list must return false');
        TP.Close();

        Assert.AreEqual(0, Row.Count(),
            'a Last() that found nothing, with nothing typed after it, must not insert a row');
    end;

    // GATING 1: OpenView. No new-row line exists, so Last() has only one candidate position --
    // and it must still be the last data row, with the same value as under OpenEdit.
    [Test]
    procedure OpenView_Last_LandsOnTheLastDataRow()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedThreeRows();

        TP.OpenView();
        Assert.IsTrue(TP.First(), 'First() must land on the first seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'First() must land on ALPHA under OpenView');

        Assert.IsTrue(TP.Last(), 'Last() must find a row under OpenView');
        Assert.AreEqual('CHARLIE', TP.RowNo.Value(), 'Last() must land on the last data row under OpenView');
        Assert.IsFalse(TP.Next(),
            'a page opened with OpenView has no new-row line, so Next() after Last() must return false');
        TP.Close();
    end;

    // GATING 2: Editable = false.
    [Test]
    procedure EditableFalsePage_Last_LandsOnTheLastDataRow()
    var
        TP: TestPage "Test Page New Row Line RO";
    begin
        Initialize();
        SeedThreeRows();

        TP.OpenEdit();
        Assert.IsTrue(TP.Last(), 'Last() must find a row on an Editable = false page');
        Assert.AreEqual('CHARLIE', TP.RowNo.Value(),
            'Last() must land on the last data row of an Editable = false page');
        Assert.IsFalse(TP.Next(),
            'an Editable = false page has no new-row line, so Next() after Last() must return false');
        TP.Close();
    end;

    // GATING 3: InsertAllowed = false.
    [Test]
    procedure InsertAllowedFalsePage_Last_LandsOnTheLastDataRow()
    var
        TP: TestPage "Test Page New Row Line NoIns";
    begin
        Initialize();
        SeedThreeRows();

        TP.OpenEdit();
        Assert.IsTrue(TP.Last(), 'Last() must find a row on an InsertAllowed = false page');
        Assert.AreEqual('CHARLIE', TP.RowNo.Value(),
            'Last() must land on the last data row of an InsertAllowed = false page');
        Assert.IsFalse(TP.Next(),
            'an InsertAllowed = false page has no new-row line, so Next() after Last() must return false');
        TP.Close();
    end;

    // GATING 4: an EMPTY page with no new-row line. Last() must answer false there too, so a
    // false from the empty-editable arm above cannot be read as "Last() is false on any empty
    // page for a reason to do with the blank line".
    [Test]
    procedure EmptyInsertAllowedFalsePage_LastReturnsFalse()
    var
        TP: TestPage "Test Page New Row Line NoIns";
    begin
        Initialize();

        TP.OpenEdit();
        Assert.IsFalse(TP.First(), 'First() on an empty InsertAllowed = false page must return false');
        Assert.IsFalse(TP.Last(), 'Last() on an empty InsertAllowed = false page must return false');
        TP.Close();
    end;

    // THE PART ARM. A ListPart carries its own new-row line (60743's ModalHostPart arm), so
    // Last() inside a part is a separate code path from Last() on a standalone page -- the
    // runner implements them in different classes.
    [Test]
    [HandlerFunctions('HostModalHandler')]
    procedure ModalHostPart_Last_LandsOnTheLastDataRow()
    var
        HostPage: Page "Test Page New Row Line Host";
    begin
        Initialize();
        SeedThreeRows();
        HostPage.RunModal();
    end;

    // THE PART ARM, EMPTY. The part's own mirror of claim 3: whether a write after a Last()
    // that found nothing starts a row in a linked part.
    [Test]
    [HandlerFunctions('EmptyHostModalHandler')]
    procedure ModalHostPart_EmptyPart_SetValueAfterLast_InsertsARow()
    var
        Row: Record "Test Page New Row Line Row";
        HostPage: Page "Test Page New Row Line Host";
    begin
        Initialize();
        HostPage.RunModal();

        Assert.AreEqual(1, Row.Count(),
            'typing into an empty editable part after a Last() that found nothing must insert exactly one row');
        Assert.IsTrue(Row.Get('PARTLAST'), 'the part row must be keyed by the value typed into the key column');
        Assert.AreEqual('typed into the part after Last', Row.Descr,
            'the value typed into the part after Last() must reach the backing table');
    end;

    [ModalPageHandler]
    procedure HostModalHandler(var Host: TestPage "Test Page New Row Line Host")
    begin
        Assert.IsTrue(Host.Lines.First(), 'the part must land on the first seeded row');
        Assert.AreEqual('ALPHA', Host.Lines.RowNo.Value(), 'First() in the part must land on ALPHA');

        Assert.IsTrue(Host.Lines.Last(), 'Last() must find a row in a part with three data rows');
        Assert.AreEqual('CHARLIE', Host.Lines.RowNo.Value(),
            'Last() in the part must land on the last DATA row, not on the part''s blank new-row line');

        Assert.IsTrue(Host.Lines.Next(),
            'the part''s new-row line follows its last data row, so Next() after Last() must reach it');
        Assert.AreEqual('', Host.Lines.RowNo.Value(), 'the part''s new-row line must read blank');
        Assert.IsFalse(Host.Lines.Next(), 'Next() from the part''s new-row line must end the rowset');
    end;

    [ModalPageHandler]
    procedure EmptyHostModalHandler(var Host: TestPage "Test Page New Row Line Host")
    begin
        Assert.IsFalse(Host.Lines.Last(), 'Last() on an empty editable part must return false');
        Host.Lines.RowNo.SetValue('PARTLAST');
        Host.Lines.Descr.SetValue('typed into the part after Last');
    end;
}
