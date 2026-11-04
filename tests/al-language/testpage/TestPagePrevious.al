// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-previous-method
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60019), ALT Keyed (60006),
//   ALT Source Table View List (60821)
//
// TestPage.Previous() walks the page's rowset BACKWARDS. Nothing in this corpus called it --
// First(), Next() and Last() are used in a dozen files, Previous() in none -- so the five
// things a test author relies on when stepping backwards were all unstated:
//
//   1. it steps to the previous row IN THE PAGE'S ORDER, not to the primary-key predecessor;
//   2. on the first row it returns false;
//   3. a Previous() that returned false leaves the page on the row it was already on, rather
//      than dropping the cursor off the rowset;
//   4. it walks the page's ROWSET, so a row excluded by the page's view or by a filter the
//      test applied after opening is not reachable backwards either;
//   5. on a page whose rowset is empty it reports false instead of throwing -- and a page can
//      have an empty rowset over a table that is not empty.
//
// Point 1 is what makes the rest worth pinning. Backwards navigation is only meaningful if it
// is the inverse of the page's own forward order, and a page's order is frequently not its
// table's -- so an implementation that stepped through the table by primary key would satisfy
// a naive "Previous() returns true three times" test and be wrong at every single row.
//
// The fixture is "ALT Source Table View List" (60821), a List over "ALT Keyed" declaring
//   SourceTableView = sorting(Amount) order(descending)
//                     where("Entry No." = filter(1 | 2 | 3), Status = const(Active))
// which gives both halves for free: an order that disagrees with the primary key at every
// position, and a where(...) clause whose excluded rows are a ready-made negative.
//
// The data is chosen so no assertion can be satisfied by walking the table instead of the page:
//
//   Entry No.  Amount  Status   position on the page   position by primary key
//   1          10      Active   3rd (last)             1st
//   2          30      Active   1st (first)            2nd
//   3          20      Active   2nd                    3rd
//   4          40      Active   not shown              4th
//
// Every row sits in a different place under the two orders, so each assertion below fails if
// the walk followed "Entry No." instead of descending Amount. Row 4 is the load-bearing
// negative: it carries the HIGHEST Amount, so a walk that ignored the view's where(...) would
// put it first and surface it as the last row Previous() reaches.

codeunit 60756 "Test Page Previous"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    local procedure SeedKeyed(EntryNo: Integer; NewName: Text[50]; NewAmount: Decimal; NewStatus: Enum "ALT Status")
    var
        ALTKeyed: Record "ALT Keyed";
    begin
        ALTKeyed.Init();
        ALTKeyed."Entry No." := EntryNo;
        ALTKeyed.Name := NewName;
        ALTKeyed.Amount := NewAmount;
        ALTKeyed.Status := NewStatus;
        ALTKeyed.Insert();
    end;

    // The four rows every arm below shares -- see the table in the file header for how each
    // one places differently under the page's order and under the primary key. Name records
    // the Amount in words so an assertion on a NON-key field can prove which row the cursor
    // is really on, rather than reading back the key the assertion just navigated by.
    local procedure SeedTheFourRows()
    var
        ALTStatus: Enum "ALT Status";
    begin
        SeedKeyed(1, 'ten', 10, ALTStatus::Active);
        SeedKeyed(2, 'thirty', 30, ALTStatus::Active);
        SeedKeyed(3, 'twenty', 20, ALTStatus::Active);
        SeedKeyed(4, 'forty', 40, ALTStatus::Active);
    end;

    // CLAIM: Previous() steps to the previous row in the PAGE's order, not to the primary-key
    // predecessor, and returns false once there is no row before the current one.
    [Test]
    procedure TestPage_Previous_WalksThePageOrderBackwards()
    var
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();

        // Under sorting(Amount) order(descending) the LOWEST Amount is last, so the walk
        // starts on row 1 -- which is the row the primary key would have put FIRST.
        Assert.IsTrue(ViewList.Last(), 'the view admits three rows, so the page has a last row');
        Assert.AreEqual(1, ViewList."Entry No.".AsInteger(),
            'order(descending) on sorting(Amount) must put the lowest Amount last');

        // Row 3 (Amount 20) is the row before row 1 in the PAGE's order. It is not row 1's
        // neighbour by primary key -- row 1 has no predecessor by key at all -- so a walk that
        // stepped through the table by key could not arrive here.
        Assert.IsTrue(ViewList.Previous(), 'a second row must be reachable walking backwards');
        Assert.AreEqual(3, ViewList."Entry No.".AsInteger(),
            'Previous() must step to the next-lowest Amount, not to the primary-key neighbour');
        Assert.AreEqual('twenty', ViewList.Name.Value(),
            'the non-key field must come from the row Previous() landed on');

        Assert.IsTrue(ViewList.Previous(), 'the third admitted row must be reachable walking backwards');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'the highest Amount is the FIRST row under order(descending), so it is reached last');
        Assert.AreEqual('thirty', ViewList.Name.Value(),
            'the non-key field must come from the row Previous() landed on');

        // Row 4 carries the highest Amount of all and would be first -- and therefore the row
        // this call reached -- on a page that ignored the view's where(...) clause.
        Assert.IsFalse(ViewList.Previous(),
            'exactly three rows are admitted, so there is nothing before the first one');

        ViewList.Close();
    end;

    // CLAIM: a Previous() that finds nothing leaves the page on the row it was already on.
    [Test]
    procedure TestPage_Previous_OnTheFirstRow_ReturnsFalseAndKeepsTheCursorThere()
    var
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();

        Assert.IsTrue(ViewList.First(), 'the view admits three rows, so the page has a first row');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'the highest Amount is first under order(descending)');

        Assert.IsFalse(ViewList.Previous(), 'there is no row before the first');

        // The point of the test: false means "did not move", not "moved off the rowset". Both
        // the key and a non-key field must still read the row the page was on, so a page that
        // blanked its buffer or stepped somewhere anyway fails here.
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'a Previous() that returned false must leave the page on the row it was on');
        Assert.AreEqual('thirty', ViewList.Name.Value(),
            'the row still shown after a failed Previous() must be a real row, fields and all');

        ViewList.Close();
    end;

    // CLAIM: Previous() undoes exactly one Next().
    [Test]
    procedure TestPage_Previous_AfterNext_ReturnsToTheSameRow()
    var
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();

        Assert.IsTrue(ViewList.First(), 'the view admits three rows');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(), 'the walk starts on the highest Amount');

        Assert.IsTrue(ViewList.Next(), 'a second row must be reachable walking forwards');
        Assert.AreEqual(3, ViewList."Entry No.".AsInteger(),
            'Next() must step to the next-highest Amount');

        Assert.IsTrue(ViewList.Previous(), 'the row stepped away from must still be reachable');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'Previous() must undo exactly one Next(), landing back on the row it started from');
        Assert.AreEqual('thirty', ViewList.Name.Value(),
            'the non-key field must come from the row Previous() returned to');

        ViewList.Close();
    end;

    // CLAIM: Previous() walks the page's rowset, so a row a filter applied after open excludes
    // is not reachable backwards either.
    [Test]
    procedure TestPage_Previous_DoesNotReachARowOutsideThePageFilter()
    var
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();
        SeedTheFourRows();

        ViewList.OpenView();

        // Row 3 passes the page's own view -- the walk in the first test reaches it -- so the
        // only thing keeping it out here is this filter. That makes it a genuine negative
        // rather than a row that was never visible in the first place.
        ViewList.Filter.SetFilter("Entry No.", '1|2');

        Assert.IsTrue(ViewList.Last(), 'rows 1 and 2 both pass the filter, so the page has a last row');
        Assert.AreEqual(1, ViewList."Entry No.".AsInteger(),
            'the lowest Amount of the filtered rows is last under order(descending)');

        Assert.IsTrue(ViewList.Previous(), 'the other filtered row must be reachable backwards');
        Assert.AreEqual(2, ViewList."Entry No.".AsInteger(),
            'Previous() must land on the other row the filter admits');

        // Row 3 sits between rows 1 and 2 in the page's Amount order, so a backwards walk that
        // ignored the filter would stop here and report a third row.
        Assert.IsFalse(ViewList.Previous(),
            'a row excluded by the page filter must not be reachable by walking backwards');

        ViewList.Close();
    end;

    // CLAIM: on a page whose rowset is empty, Previous() reports false rather than throwing --
    // and "empty rowset" is not the same thing as "empty table".
    [Test]
    procedure TestPage_Previous_OnAnEmptyRowset_ReturnsFalse()
    var
        ALTKeyed: Record "ALT Keyed";
        ALTStatus: Enum "ALT Status";
        ViewList: TestPage "ALT Source Table View List";
    begin
        Initialize();

        // Both rows are real rows in a table that is NOT empty, and both are excluded by the
        // page's own view -- row 4 by "Entry No." = filter(1 | 2 | 3) and row 2 by
        // Status = const(Active). So a page that opened over the table rather than over its
        // view has two rows to walk and cannot report false three times below.
        SeedKeyed(4, 'forty', 40, ALTStatus::Active);
        SeedKeyed(2, 'thirty', 30, ALTStatus::Closed);
        Assert.AreEqual(2, ALTKeyed.Count(), 'the table must hold rows the page is not allowed to show');

        ViewList.OpenView();
        Assert.IsFalse(ViewList.First(), 'no row passes the view, so there is no first row');
        Assert.IsFalse(ViewList.Last(), 'no row passes the view, so there is no last row');
        Assert.IsFalse(ViewList.Previous(), 'there is no row before nothing');
        ViewList.Close();
    end;
}
