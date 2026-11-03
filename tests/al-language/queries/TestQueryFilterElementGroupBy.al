// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-query-filters
//   dev-itpro/developer/devenv-query-totals-grouping
// Scope: in-scope
// Fixtures used: QFG Header (68600), QFG Entry (68601), QFG Join Totals (68600),
//   QFG Join Positive Totals (68601), QFG Entry Totals (68602); shared Assert (60021)
//
// A filter() element names a field that is not part of the query's dataset. With an
// aggregated column in the query, this suite asserts two things about it:
//   1. it is not a grouping column, so rows that differ only in the filtered field fall into
//      one group; and
//   2. a filter set on it restricts the rows BEFORE they are aggregated (a WHERE condition),
//      so a group holding rows both inside and outside the range totals only the rows inside.
// Every dataset below gives one group rows with different values in the filtered field, and
// the filtered tests give one group rows on both sides of the range. Some rows are inserted
// out of date order, so no test depends on which row of a group is read first.
//
// Reported against AL Runner as StefanMaron/BusinessCentral.AL.Runner#5145.
codeunit 68600 "QFG Filter Element GroupBy"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Header: Record "QFG Header";
        Entry: Record "QFG Entry";
    begin
        Entry.DeleteAll();
        Header.DeleteAll();
    end;

    local procedure InsertHeader(No: Code[20])
    var
        Header: Record "QFG Header";
    begin
        Header.Init();
        Header."No." := No;
        Header.Insert();
    end;

    local procedure InsertEntry(EntryNo: Integer; HeaderNo: Code[20]; PostingDate: Date; EntryAmount: Decimal)
    var
        Entry: Record "QFG Entry";
    begin
        Entry.Init();
        Entry."Entry No." := EntryNo;
        Entry."Header No." := HeaderNo;
        Entry."Posting Date" := PostingDate;
        Entry.Amount := EntryAmount;
        Entry.Insert();
    end;

    // A: 1000 on 5 July, 100 on 10 June, 50 on 20 June. B: 9 on 5 July only.
    local procedure InsertMixedDates()
    begin
        InsertHeader('A');
        InsertHeader('B');
        InsertEntry(1, 'A', 20260705D, 1000);
        InsertEntry(2, 'A', 20260610D, 100);
        InsertEntry(3, 'A', 20260620D, 50);
        InsertEntry(4, 'B', 20260705D, 9);
    end;

    [Test]
    procedure JoinFilterElement_NoFilterSet_OneGroupPerHeader()
    var
        Totals: Query "QFG Join Totals";
    begin
        // Three dates under A must still give one A row, not one row per date.
        Initialize();
        InsertMixedDates();

        Totals.Open();
        Assert.IsTrue(Totals.Read(), 'The first group must be returned');
        Assert.AreEqual('A', Totals.HeaderNo, 'The first group must be header A');
        Assert.AreEqual(1150, Totals.TotalAmount, 'A must total all three of its entries');
        Assert.AreEqual(3, Totals.EntryCount, 'A must count all three of its entries');
        Assert.IsTrue(Totals.Read(), 'The second group must be returned');
        Assert.AreEqual('B', Totals.HeaderNo, 'The second group must be header B');
        Assert.AreEqual(9, Totals.TotalAmount, 'B must total its single entry');
        Assert.AreEqual(1, Totals.EntryCount, 'B must count its single entry');
        Assert.IsFalse(Totals.Read(), 'There must be exactly one group per header');
        Totals.Close();
    end;

    [Test]
    procedure JoinFilterElement_FilterSet_AggregatesOnlyRowsInRange()
    var
        Totals: Query "QFG Join Totals";
    begin
        // The June range keeps A's two June entries and drops its July one. B has no June
        // entry, so the inner join gives it no group at all.
        Initialize();
        InsertMixedDates();

        Totals.SetRange(DateFilter, 20260601D, 20260630D);
        Totals.Open();
        Assert.IsTrue(Totals.Read(), 'The June group for A must be returned');
        Assert.AreEqual('A', Totals.HeaderNo, 'The group must be header A');
        Assert.AreEqual(150, Totals.TotalAmount, 'A must total only its June entries');
        Assert.AreEqual(2, Totals.EntryCount, 'A must count only its June entries');
        Assert.IsFalse(Totals.Read(), 'B has no June entry, so it must not be returned');
        Totals.Close();
    end;

    [Test]
    procedure JoinFilterElement_WithColumnFilter_NegativeTotalInRangeIsExcluded()
    var
        Totals: Query "QFG Join Positive Totals";
    begin
        // A's June entries total -150, so the > 0 ColumnFilter excludes A. B's June entry is
        // 300; its July entry of -1000 is outside the range, so B's total is 300 and B stays.
        Initialize();
        InsertHeader('A');
        InsertHeader('B');
        InsertEntry(1, 'A', 20260610D, 100);
        InsertEntry(2, 'A', 20260620D, -250);
        InsertEntry(3, 'B', 20260705D, -1000);
        InsertEntry(4, 'B', 20260615D, 300);

        Totals.SetRange(DateFilter, 20260601D, 20260630D);
        Totals.Open();
        Assert.IsTrue(Totals.Read(), 'B''s positive June total must be returned');
        Assert.AreEqual('B', Totals.HeaderNo, 'The only group must be header B');
        Assert.AreEqual(300, Totals.TotalAmount, 'B must total only its June entry');
        Assert.IsFalse(Totals.Read(), 'A''s June total is negative, so A must be excluded');
        Totals.Close();
    end;

    [Test]
    procedure JoinFilterElement_WithColumnFilter_NoPositiveGroup_ReadIsFalse()
    var
        Totals: Query "QFG Join Positive Totals";
    begin
        // A's two June entries form one group totalling -150, so the > 0 ColumnFilter
        // excludes it, even though the 10 June entry alone is positive.
        Initialize();
        InsertHeader('A');
        InsertEntry(1, 'A', 20260610D, 100);
        InsertEntry(2, 'A', 20260620D, -250);

        Totals.SetRange(DateFilter, 20260601D, 20260630D);
        Totals.Open();
        Assert.IsFalse(Totals.Read(), 'A''s total of -150 must be excluded by the > 0 ColumnFilter');
        Totals.Close();
    end;

    [Test]
    procedure SingleDataItemFilterElement_GroupsAndFiltersBeforeAggregation()
    var
        Totals: Query "QFG Entry Totals";
    begin
        // The same dataset through a query over one dataitem.
        Initialize();
        InsertMixedDates();

        Totals.Open();
        Assert.IsTrue(Totals.Read(), 'The first group must be returned');
        Assert.AreEqual('A', Totals.HeaderNo, 'The first group must be header A');
        Assert.AreEqual(1150, Totals.TotalAmount, 'Unfiltered, A must total all three entries');
        Assert.AreEqual(3, Totals.EntryCount, 'Unfiltered, A must count all three entries');
        Assert.IsTrue(Totals.Read(), 'The second group must be returned');
        Assert.AreEqual('B', Totals.HeaderNo, 'The second group must be header B');
        Assert.IsFalse(Totals.Read(), 'Unfiltered, there must be exactly one group per header');
        Totals.Close();

        Totals.SetRange(DateFilter, 20260601D, 20260630D);
        Totals.Open();
        Assert.IsTrue(Totals.Read(), 'The June group for A must be returned');
        Assert.AreEqual('A', Totals.HeaderNo, 'The filtered group must be header A');
        Assert.AreEqual(150, Totals.TotalAmount, 'Filtered, A must total only its June entries');
        Assert.AreEqual(2, Totals.EntryCount, 'Filtered, A must count only its June entries');
        Assert.IsFalse(Totals.Read(), 'Filtered, B has no June entry and must not be returned');
        Totals.Close();
    end;
}
