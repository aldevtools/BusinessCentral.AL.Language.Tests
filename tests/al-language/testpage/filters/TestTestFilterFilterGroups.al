// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfilter/testfilter-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT TestFilter Row (60347), ALT TestFilter Grp Left List (60975),
//   ALT TestFilter Grp Hidden List (60976), ALT TestFilter Grp Both List (67960);
//   shared Assert (60021)
//
// CLAIM: TestPage.Filter.SetFilter writes the page's user filter (filter group 0), whatever
// filter group the page's own OnOpenPage left active on Rec.
//
//   1. OnOpenPage set Grp in group 0 and left group 2 active (page 60975, the shape of
//      Base Application's GenJnlManagement.OpenJnlBatch): a TestPage filter on Grp REPLACES
//      the group-0 value, so the page shows the rows of the new value. Writing into the
//      active group 2 instead would AND the two Grp filters and show nothing.
//   2. Same page, a TestPage filter on a DIFFERENT field: the group-0 Grp filter stays in
//      force and the two combine.
//   3. OnOpenPage set Grp in group 2 and left group 0 active (page 60976): a TestPage
//      filter on Grp does NOT override the group-2 filter — both stay in force, and a value
//      the group-2 filter excludes shows no rows. This is the negative case: it separates
//      "the TestPage filter goes to group 0" from "the TestPage filter replaces the field's
//      filter in every group". Filter.GetFilter(Grp) then reads the group-2 value 'A', not
//      the 'B' the test set: it answers the first filter on the field across the page's
//      filter groups, and group 2 was written before the TestPage filter's group 0.
//   4. OnOpenPage set Grp = A in group 0 and THEN Grp = A|B in group 2 (page 67960). Before
//      any TestPage filter, Filter.GetFilter(Grp) reads group 0's 'A', the group written
//      first. A TestPage filter change - on Grp, or on another field entirely - leaves group 0
//      AHEAD of group 2, so GetFilter(Grp) reads group 0: 'B' after a filter on Grp, still 'A'
//      after a filter on Rank. Re-applying the user filters does not move group 0 behind the
//      page's other groups (AL Runner issue #4690).
//
// Rows seeded by every test:
//   Entry No.  Grp  Rank
//       1      'A'   10
//       2      'B'   20
//       3      'A'   30
//
// AL Runner issues: StefanMaron/BusinessCentral.AL.Runner#4677, #4690

codeunit 60919 "Test TestFilter Filter Groups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure SeedRows()
    var
        Row: Record "ALT TestFilter Row";
    begin
        Row.DeleteAll();
        InsertRow(1, 'A', 10);
        InsertRow(2, 'B', 20);
        InsertRow(3, 'A', 30);
    end;

    local procedure InsertRow(EntryNo: Integer; NewGrp: Code[10]; NewRank: Integer)
    var
        Row: Record "ALT TestFilter Row";
    begin
        Row.Init();
        Row."Entry No." := EntryNo;
        Row.Grp := NewGrp;
        Row.Rank := NewRank;
        Row.Insert();
    end;

    local procedure WalkLeft(var L: TestPage "ALT TestFilter Grp Left List") Seq: Text
    begin
        if not L.First() then
            exit('');
        repeat
            if Seq <> '' then
                Seq += '|';
            Seq += Format(L.EntryNo.AsInteger());
        until not L.Next();
    end;

    local procedure WalkHidden(var L: TestPage "ALT TestFilter Grp Hidden List") Seq: Text
    begin
        if not L.First() then
            exit('');
        repeat
            if Seq <> '' then
                Seq += '|';
            Seq += Format(L.EntryNo.AsInteger());
        until not L.Next();
    end;

    [Test]
    procedure SetFilter_ReplacesGroupZeroFilter_WhenOnOpenPageLeftGroupTwoActive()
    var
        L: TestPage "ALT TestFilter Grp Left List";
    begin
        SeedRows();
        L.OpenView();
        // Precondition: OnOpenPage's group-0 filter is in force.
        Assert.AreEqual('1|3', WalkLeft(L), 'before any TestPage filter the page shows the Grp A rows');

        L.Filter.SetFilter(Grp, 'B');

        Assert.AreEqual('B', L.Filter.GetFilter(Grp), 'TestPage filter on Grp reads back');
        Assert.AreEqual('2', WalkLeft(L), 'the TestPage filter must replace the group-0 Grp filter OnOpenPage set');
        L.Close();
    end;

    [Test]
    procedure SetFilter_OnOtherField_CombinesWithGroupZeroFilter_WhenOnOpenPageLeftGroupTwoActive()
    var
        L: TestPage "ALT TestFilter Grp Left List";
    begin
        SeedRows();
        L.OpenView();

        L.Filter.SetFilter(Rank, '20..30');

        // Rank 20..30 alone admits 2 and 3; OnOpenPage's Grp = A in group 0 removes 2.
        Assert.AreEqual('3', WalkLeft(L), 'a TestPage filter on another field must combine with the group-0 Grp filter');
        L.Close();
    end;

    [Test]
    procedure SetFilter_DoesNotOverrideGroupTwoFilter_SetByOnOpenPage()
    var
        L: TestPage "ALT TestFilter Grp Hidden List";
    begin
        SeedRows();
        L.OpenView();
        Assert.AreEqual('1|3', WalkHidden(L), 'before any TestPage filter the group-2 filter admits the Grp A rows');

        L.Filter.SetFilter(Grp, 'B');

        Assert.AreEqual('', WalkHidden(L), 'the group-2 Grp = A filter stays in force, so Grp B shows no rows');
        Assert.AreEqual('A', L.Filter.GetFilter(Grp), 'GetFilter reads the first filter on Grp across filter groups: group 2, written by OnOpenPage before the TestPage filter');
        L.Close();
    end;

    [Test]
    procedure SetFilter_NarrowsWithinGroupTwoFilter_SetByOnOpenPage()
    var
        L: TestPage "ALT TestFilter Grp Hidden List";
    begin
        SeedRows();
        L.OpenView();

        L.Filter.SetFilter(Rank, '20..30');

        Assert.AreEqual('3', WalkHidden(L), 'a TestPage filter on another field combines with the group-2 Grp filter');
        L.Close();
    end;

    local procedure WalkBoth(var L: TestPage "ALT TestFilter Grp Both List") Seq: Text
    begin
        if not L.First() then
            exit('');
        repeat
            if Seq <> '' then
                Seq += '|';
            Seq += Format(L.EntryNo.AsInteger());
        until not L.Next();
    end;

    [Test]
    procedure GetFilter_ReadsGroupZero_WhenOnOpenPageWroteItBeforeGroupTwo()
    var
        L: TestPage "ALT TestFilter Grp Both List";
    begin
        SeedRows();
        L.OpenView();

        Assert.AreEqual('1|3', WalkBoth(L), 'group 0 Grp = A and group 2 Grp = A|B admit the Grp A rows');
        Assert.AreEqual('A', L.Filter.GetFilter(Grp), 'with no TestPage filter, GetFilter reads group 0, written before group 2');
        L.Close();
    end;

    [Test]
    procedure GetFilter_StillReadsGroupZero_AfterTestPageFilterOnSameField()
    var
        L: TestPage "ALT TestFilter Grp Both List";
    begin
        SeedRows();
        L.OpenView();

        L.Filter.SetFilter(Grp, 'B');

        Assert.AreEqual('2', WalkBoth(L), 'group 0 Grp = B and group 2 Grp = A|B admit only the Grp B row');
        Assert.AreEqual('B', L.Filter.GetFilter(Grp), 'group 0 stays ahead of group 2 after a TestPage filter change, so GetFilter reads the TestPage filter');
        L.Close();
    end;

    [Test]
    procedure GetFilter_StillReadsGroupZero_AfterTestPageFilterOnOtherField()
    var
        L: TestPage "ALT TestFilter Grp Both List";
    begin
        SeedRows();
        L.OpenView();

        L.Filter.SetFilter(Rank, '20..30');

        Assert.AreEqual('3', WalkBoth(L), 'Rank 20..30 combines with group 0 Grp = A');
        Assert.AreEqual('A', L.Filter.GetFilter(Grp), 'a TestPage filter on another field leaves group 0 ahead of group 2, so GetFilter still reads group 0');
        Assert.AreEqual('20..30', L.Filter.GetFilter(Rank), 'the TestPage filter on Rank reads back');
        L.Close();
    end;
}
