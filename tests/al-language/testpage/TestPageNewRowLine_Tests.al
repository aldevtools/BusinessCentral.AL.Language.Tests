// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-next-method
// Scope: in-scope
// Fixtures used: Test Page New Row Line Row (60737), Test Page New Row Line List (60738),
//   Test Page New Row Line RO (60739), Test Page New Row Line NoIns (60740),
//   Test Page New Row Line Part (60741), Test Page New Row Line Host (60742)
//
// An editable, insert-allowed repeater carries a trailing BLANK line past its data — the line
// a user types into to create a record. It is part of the client's rowset, so TestPage.Next()
// walks onto it: Next() past the last DATA row answers true, every control there reads blank,
// and only the following Next() answers false.
//
// This is not a detail of the client's chrome. `repeat ... until not Page.Next()` is how AL
// tests iterate a list page, and on such a page that loop runs one extra time on a blank row.
// A test that counts rows, sums a column, or asserts on Rec inside the loop has to know this;
// anything that answers false one step early silently skips it and every such loop diverges.
//
// The gating is the measurement. Three arms below are pages that differ from the first ONLY in
// a property that suppresses the blank line (OpenView instead of OpenEdit, Editable = false,
// InsertAllowed = false), and they must all answer false. An implementation that simply made
// Next() return true once more at the end of any rowset passes the first arm and fails these.
// The empty-list arm pins the other edge: First() does not land on the blank line, so an empty
// editable list is still empty.
//
// The two-data-row arm separates "the blank line comes after ALL the data" from a plain
// off-by-one, and the no-side-effect arm pins that walking onto the blank line and leaving it
// untouched writes nothing — the client only persists that line once someone types into it.

codeunit 60743 "Test Page New Row Line Tests"
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

    local procedure SeedOneRow()
    var
        Row: Record "Test Page New Row Line Row";
    begin
        Row.Init();
        Row."No." := 'ALPHA';
        Row.Descr := 'first row';
        Row.Insert();
    end;

    local procedure SeedTwoRows()
    var
        Row: Record "Test Page New Row Line Row";
    begin
        SeedOneRow();
        Row.Init();
        Row."No." := 'BRAVO';
        Row.Descr := 'second row';
        Row.Insert();
    end;

    // THE CLAIM. Next() past the last data row lands on the blank new-row line and answers
    // true; the controls there read blank; the next Next() ends the rowset.
    [Test]
    procedure EditableInsertable_NextPastLastDataRow_LandsOnTheNewRowLine()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedOneRow();

        TP.OpenEdit();
        Assert.IsTrue(TP.First(), 'First() must land on the seeded row');
        // Value assertions on the data row first: they prove the cursor really is on the
        // seeded row, so the blank read below is the NEW-ROW LINE and not a page that
        // answers blank everywhere.
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'the seeded row must read through the page');
        Assert.AreEqual('first row', TP.Descr.Value(), 'the seeded row must read through the page');

        Assert.IsTrue(TP.Next(),
            'Next() past the last data row must land on the implicit new-row line of an editable, insert-allowed page');
        Assert.AreEqual('', TP.RowNo.Value(), 'the new-row line must read blank');
        Assert.AreEqual('', TP.Descr.Value(), 'the new-row line must read blank');

        Assert.IsFalse(TP.Next(), 'Next() from the new-row line must end the rowset');
        TP.Close();
    end;

    // The blank line comes after ALL the data, not in place of the last row. An off-by-one
    // that returned true one row early would read 'BRAVO' where this expects blank.
    [Test]
    procedure EditableInsertable_TwoDataRows_NewRowLineFollowsBoth()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedTwoRows();

        TP.OpenEdit();
        Assert.IsTrue(TP.First(), 'First() must land on the first seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'the first row must read ALPHA');

        Assert.IsTrue(TP.Next(), 'Next() must reach the second data row');
        Assert.AreEqual('BRAVO', TP.RowNo.Value(), 'the second row must read BRAVO');

        Assert.IsTrue(TP.Next(), 'Next() past the last data row must land on the new-row line');
        Assert.AreEqual('', TP.RowNo.Value(), 'the new-row line must read blank, after BOTH data rows');

        Assert.IsFalse(TP.Next(), 'Next() from the new-row line must end the rowset');
        TP.Close();
    end;

    // Walking onto the new-row line and leaving it untouched must write nothing. The client
    // only turns that line into a record once someone types into it.
    [Test]
    procedure NewRowLine_LeftUntouched_InsertsNothing()
    var
        Row: Record "Test Page New Row Line Row";
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedOneRow();

        TP.OpenEdit();
        Assert.IsTrue(TP.First(), 'First() must land on the seeded row');
        Assert.IsTrue(TP.Next(), 'Next() must land on the new-row line');
        Assert.IsFalse(TP.Next(), 'Next() from the new-row line must end the rowset');
        TP.Close();

        Assert.AreEqual(1, Row.Count(),
            'walking onto the new-row line without typing must not insert a row');
        Assert.IsTrue(Row.Get('ALPHA'), 'the seeded row must still be the only row');
    end;

    // GATING 1: OpenView. Same page, opened read-only — no new-row line.
    [Test]
    procedure OpenView_NextPastLastDataRow_ReturnsFalse()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();
        SeedOneRow();

        TP.OpenView();
        Assert.IsTrue(TP.First(), 'First() must land on the seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'the seeded row must read through the page');
        Assert.IsFalse(TP.Next(),
            'a page opened with OpenView has no new-row line, so Next() past the last row must return false');
        TP.Close();
    end;

    // GATING 2: Editable = false.
    [Test]
    procedure EditableFalsePage_NextPastLastDataRow_ReturnsFalse()
    var
        TP: TestPage "Test Page New Row Line RO";
    begin
        Initialize();
        SeedOneRow();

        TP.OpenEdit();
        Assert.IsTrue(TP.First(), 'First() must land on the seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'the seeded row must read through the page');
        Assert.IsFalse(TP.Next(),
            'an Editable = false page has no new-row line, so Next() past the last row must return false');
        TP.Close();
    end;

    // GATING 3: InsertAllowed = false.
    [Test]
    procedure InsertAllowedFalsePage_NextPastLastDataRow_ReturnsFalse()
    var
        TP: TestPage "Test Page New Row Line NoIns";
    begin
        Initialize();
        SeedOneRow();

        TP.OpenEdit();
        Assert.IsTrue(TP.First(), 'First() must land on the seeded row');
        Assert.AreEqual('ALPHA', TP.RowNo.Value(), 'the seeded row must read through the page');
        Assert.IsFalse(TP.Next(),
            'an InsertAllowed = false page has no new-row line, so Next() past the last row must return false');
        TP.Close();
    end;

    // THE OTHER EDGE: First() does not land on the new-row line, so an empty editable list is
    // still empty. Without this arm, "the rowset always has one more row" would pass every
    // arm above.
    [Test]
    procedure EmptyEditableList_FirstReturnsFalse()
    var
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();

        TP.OpenEdit();
        Assert.IsFalse(TP.First(),
            'First() on an empty editable list must return false — BC does not land on the new-row line from First()');
        TP.Close();
    end;

    // First() answers false on an empty editable list (the arm above), but the CLIENT still
    // shows the user exactly one row on such a page: the blank new-row line. Real Microsoft
    // AL never calls First() before typing into a page it just opened empty — it types
    // straight into a field (e.g. Base App's ApprovalCommentsHandler on codeunit 1535's
    // "Approval Comments" page). This is the shape that observation depends on: no explicit
    // New(), no explicit First()/Next(), just a field write on a page that opened with zero
    // rows matching its view. If the client's implicit cursor position at open time is not
    // the new-row line, the write lands on nothing and there is no row to persist.
    [Test]
    procedure EmptyEditableList_SetValueWithoutNewOrFirst_InsertsARow()
    var
        Row: Record "Test Page New Row Line Row";
        TP: TestPage "Test Page New Row Line List";
    begin
        Initialize();

        TP.OpenEdit();
        TP.RowNo.SetValue('DIRECT');
        TP.Descr.SetValue('typed without New or First');
        TP.Close();

        Assert.AreEqual(1, Row.Count(),
            'typing into a field of an empty editable, insert-allowed list — without calling New() or First() first — must still insert a row');
        Row.Get('DIRECT');
        Assert.AreEqual('typed without New or First', Row.Descr,
            'the value typed directly into the page must reach the backing table');
    end;

    // THE PART ARM. A ListPart on a modal host is the shape this was first observed on
    // (BusinessCentral.AL.Language.Tests PR #66): the part is its own editable, insert-allowed
    // repeater, so it carries its own new-row line.
    [Test]
    [HandlerFunctions('HostModalHandler')]
    procedure ModalHostPart_NextPastLastDataRow_LandsOnTheNewRowLine()
    var
        HostPage: Page "Test Page New Row Line Host";
    begin
        Initialize();
        SeedOneRow();
        HostPage.RunModal();
    end;

    // GATING 4, on the PART: the same part hosted by a read-only card. A part is opened
    // inside its host, so the host's read-only state has to reach it — a part that judged
    // its own editability in isolation would offer a blank line here.
    [Test]
    [HandlerFunctions('HostROModalHandler')]
    procedure ReadOnlyHostPart_NextPastLastDataRow_ReturnsFalse()
    var
        HostPage: Page "Test Page New Row Ln Host RO";
    begin
        Initialize();
        SeedOneRow();
        HostPage.RunModal();
    end;

    [ModalPageHandler]
    procedure HostROModalHandler(var Host: TestPage "Test Page New Row Ln Host RO")
    begin
        Assert.IsTrue(Host.Lines.First(), 'the part must land on the seeded row');
        Assert.AreEqual('ALPHA', Host.Lines.RowNo.Value(), 'the part must read the seeded row');
        Assert.IsFalse(Host.Lines.Next(),
            'a part on an Editable = false host has no new-row line, so Next() past the last row must return false');
    end;

    [ModalPageHandler]
    procedure HostModalHandler(var Host: TestPage "Test Page New Row Line Host")
    begin
        Assert.IsTrue(Host.Lines.First(), 'the part must land on the seeded row');
        Assert.AreEqual('ALPHA', Host.Lines.RowNo.Value(), 'the part must read the seeded row');

        Assert.IsTrue(Host.Lines.Next(),
            'Next() past the part''s last data row must land on the part''s own new-row line');
        Assert.AreEqual('', Host.Lines.RowNo.Value(), 'the part''s new-row line must read blank');

        Assert.IsFalse(Host.Lines.Next(), 'Next() from the part''s new-row line must end the rowset');
    end;
}
