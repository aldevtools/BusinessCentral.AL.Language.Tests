// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagetestpage-gotorecord-method
// Scope: in-scope
// Fixtures used: Test Page GoToRecord Row (60695), Test Page GoToRecord List (60696), Assert (60021)
//
// GoToRecord positions the page's cursor on the row identified by the record's primary key.

codeunit 60697 "Test Page GoToRecord Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Row: Record "Test Page GoToRecord Row";
    begin
        Row.DeleteAll();
    end;

    local procedure SeedRows()
    var
        Row: Record "Test Page GoToRecord Row";
    begin
        Row.Init();
        Row."No." := 'A';
        Row.Descr := 'Alpha';
        Row.Insert();

        Row.Init();
        Row."No." := 'B';
        Row.Descr := 'Bravo';
        Row.Insert();

        Row.Init();
        Row."No." := 'C';
        Row.Descr := 'Charlie';
        Row.Insert();
    end;

    // Positive: GoToRecord must land on the requested row, NOT merely "not throw".
    // Asserting Descr (a non-key field) proves the page's cursor actually moved to
    // that row rather than the assertion reading back the key we supplied.
    [Test]
    procedure GoToRecord_PositionsPageOnRequestedRow()
    var
        Row: Record "Test Page GoToRecord Row";
        TgrList: TestPage "Test Page GoToRecord List";
    begin
        Initialize();
        SeedRows();

        Row.Get('B');

        TgrList.OpenView();
        Assert.IsTrue(TgrList.GoToRecord(Row), 'GoToRecord must find the seeded row B');
        Assert.AreEqual('B', TgrList."No.".Value(), 'TestPage must be positioned on row B');
        Assert.AreEqual('Bravo', TgrList.Descr.Value(), 'TestPage must expose row B''s non-key field');
        TgrList.Close();
    end;

    // Positive: navigating to a DIFFERENT row from an already-positioned page must
    // move the cursor. Guards against an implementation that only ever lands on the
    // first row (which would still satisfy a single-row test).
    [Test]
    procedure GoToRecord_MovesBetweenRows()
    var
        Row: Record "Test Page GoToRecord Row";
        TgrList: TestPage "Test Page GoToRecord List";
    begin
        Initialize();
        SeedRows();

        TgrList.OpenView();

        Row.Get('C');
        Assert.IsTrue(TgrList.GoToRecord(Row), 'GoToRecord must find row C');
        Assert.AreEqual('Charlie', TgrList.Descr.Value(), 'TestPage must be positioned on row C');

        Row.Get('A');
        Assert.IsTrue(TgrList.GoToRecord(Row), 'GoToRecord must find row A');
        Assert.AreEqual('Alpha', TgrList.Descr.Value(), 'TestPage must have moved back to row A');

        TgrList.Close();
    end;

    // Negative: a record whose key is not present on the page must report "not found"
    // rather than silently succeeding or landing on an arbitrary row.
    [Test]
    procedure GoToRecord_ReturnsFalseForRowNotOnPage()
    var
        Row: Record "Test Page GoToRecord Row";
        TgrList: TestPage "Test Page GoToRecord List";
    begin
        Initialize();
        SeedRows();

        // Build an in-memory record whose key was never inserted.
        Row.Init();
        Row."No." := 'ZZZ';
        Row.Descr := 'Not inserted';

        TgrList.OpenView();
        Assert.IsFalse(TgrList.GoToRecord(Row), 'GoToRecord must not claim to find a row that was never inserted');
        TgrList.Close();
    end;
}
