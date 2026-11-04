// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
// Scope: in-scope
// Fixtures used: QJ Order (60862), QJ Order Sum Filtered (60768), QJ Order Filtered (60769); shared Assert (60021)
//
// A query column's static ColumnFilter property applies a filter that the query's compiled
// definition carries WITHOUT any runtime SetRange/SetFilter call. On an AGGREGATED (Method =
// Sum/Count/Average/Min/Max) column it is a HAVING-style filter, evaluated against the
// per-group aggregated result (dropping whole groups); on a plain column it is a WHERE-style
// filter, evaluated against individual raw rows before any grouping. A runtime SetRange/
// SetFilter on the SAME column REPLACES its static ColumnFilter rather than combining with it.
codeunit 60770 "QJ Query ColumnFilter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Ord: Record "QJ Order";
    begin
        Ord.DeleteAll();
    end;

    local procedure InsertOrder(EntryNo: Integer; CustNo: Code[20]; Amount: Decimal)
    var
        Ord: Record "QJ Order";
    begin
        Ord.Init();
        Ord."Entry No." := EntryNo;
        Ord."Customer No." := CustNo;
        Ord.Amount := Amount;
        Ord.Insert();
    end;

    // C1's two orders sum to 0 (100 + -100); C2's single order sums to 50. The query's static
    // ColumnFilter (TotalAmount = filter(> 0)) must drop C1's group entirely, keeping only C2.
    [Test]
    procedure ColumnFilterOnSum_ExcludesZeroOrNegativeGroup_KeepsOnlyPositiveGroups()
    var
        Query: Query "QJ Order Sum Filtered";
        RowCount: Integer;
        LastCust: Code[20];
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', -100);
        InsertOrder(3, 'C2', 50);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            LastCust := Query.CustNo;
            Assert.IsTrue(Query.TotalAmount > 0, 'Every returned group must have a positive total');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'Only C2''s group must pass the static ColumnFilter');
        Assert.AreEqual('C2', LastCust, 'The surviving group must be C2');
    end;

    // Negative sibling: every group's total fails the static ColumnFilter, so the result must
    // be completely empty — proving the filter is genuinely evaluated per group, not a no-op.
    [Test]
    procedure ColumnFilterOnSum_EveryGroupFails_ReturnsNoRows()
    var
        Query: Query "QJ Order Sum Filtered";
    begin
        Initialize();
        InsertOrder(1, 'C1', -10);
        InsertOrder(2, 'C2', 0);

        Query.Open();
        Assert.IsFalse(Query.Read(), 'No group has a positive total, so the result must be empty');
        Query.Close();
    end;

    // A runtime SetFilter on the SAME aggregated column REPLACES the static ColumnFilter
    // rather than AND-combining with it: C1's group total (0) fails the static "> 0" filter but
    // satisfies the runtime "<10" filter, so switching to the runtime filter must bring C1 back
    // (and, since C2's total 50 fails "<10", drop C2 — the mirror image of the static-only case).
    [Test]
    procedure ColumnFilterOnSum_RuntimeFilterOnSameColumn_ReplacesStaticFilter()
    var
        Query: Query "QJ Order Sum Filtered";
        RowCount: Integer;
        LastCust: Code[20];
        LastTotal: Decimal;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', -100);
        InsertOrder(3, 'C2', 50);

        Query.SetFilter(TotalAmount, '<%1', 10);
        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            LastCust := Query.CustNo;
            LastTotal := Query.TotalAmount;
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'The runtime filter must replace the static one, keeping exactly C1');
        Assert.AreEqual('C1', LastCust, 'C1 must be the surviving group under the runtime filter');
        Assert.AreEqual(0, LastTotal, 'C1''s group total must be 0 (100 + -100)');
    end;

    // A static ColumnFilter on a PLAIN (non-aggregated) column is WHERE-style: it drops raw
    // rows before any grouping. Only C1's rows may be returned; C2's rows must not appear.
    [Test]
    procedure ColumnFilterOnPlainColumn_FiltersRawRows()
    var
        Query: Query "QJ Order Filtered";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 10);
        InsertOrder(2, 'C2', 20);
        InsertOrder(3, 'C1', 30);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual('C1', Query.CustNo, 'Only C1 rows may pass the static ColumnFilter');
        end;
        Query.Close();

        Assert.AreEqual(2, RowCount, 'Both of C1''s raw rows must be returned, none of C2''s');
    end;

    // Negative sibling: no row satisfies the static ColumnFilter, so the result must be
    // completely empty — proving the filter is genuinely evaluated per row, not a no-op.
    [Test]
    procedure ColumnFilterOnPlainColumn_NoRowMatches_ReturnsNoRows()
    var
        Query: Query "QJ Order Filtered";
    begin
        Initialize();
        InsertOrder(1, 'C2', 10);
        InsertOrder(2, 'C3', 20);

        Query.Open();
        Assert.IsFalse(Query.Read(), 'No row is for customer C1, so the result must be empty');
        Query.Close();
    end;
}
