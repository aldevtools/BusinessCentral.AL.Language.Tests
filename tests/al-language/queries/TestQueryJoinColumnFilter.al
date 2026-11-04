// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-columnfilter-property
//   dev-itpro/developer/methods-auto/query/query-data-type
// Scope: in-scope
// Fixtures used: QJ Customer (60861), QJ Order (60862), QJ Cust Orders Sum Filtered (60780),
//   QJ Cust Orders Filtered (60781); shared Assert (60021)
//
// TestQueryColumnFilter.al proved a query column's static ColumnFilter property on a
// SINGLE-dataitem query. This suite proves the identical ColumnFilter semantics hold when the
// column's dataitem also participates in a multi-dataitem JOIN (SqlJoinType/DataItemLink):
// on an AGGREGATED (Method = Sum) column it is still a HAVING-style filter, evaluated against
// the per-group aggregated result AFTER the join's own implicit GROUP BY (dropping whole
// groups); on a plain column it is still a WHERE-style filter, evaluated against individual
// raw JOINED rows before any grouping. A runtime SetRange/SetFilter on the SAME column still
// REPLACES its static ColumnFilter rather than combining with it.
codeunit 60782 "QJ Join ColumnFilter Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    local procedure Initialize()
    var
        Cust: Record "QJ Customer";
        Ord: Record "QJ Order";
    begin
        Cust.DeleteAll();
        Ord.DeleteAll();
    end;

    local procedure InsertCust(No: Code[20])
    var
        Cust: Record "QJ Customer";
    begin
        Cust.Init();
        Cust."No." := No;
        Cust.Name := No;
        Cust.Insert();
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

    // C1's two joined orders sum to 0 (100 + -100); C2's single joined order sums to 50. The
    // joined query's static ColumnFilter (TotalAmount = filter(> 0)) must drop C1's group
    // entirely, keeping only C2's — proving the join's own implicit GROUP BY (#2146-class
    // behavior) and the static ColumnFilter compose correctly.
    [Test]
    procedure ColumnFilterOnJoinedSum_ExcludesZeroTotalGroup_KeepsOnlyPositiveGroups()
    var
        Query: Query "QJ Cust Orders Sum Filtered";
        RowCount: Integer;
        LastCust: Code[20];
    begin
        Initialize();
        InsertCust('C1');
        InsertCust('C2');
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

    // A runtime SetFilter on the SAME aggregated joined column REPLACES the static
    // ColumnFilter rather than AND-combining with it: C1's joined group total (0) fails the
    // static "> 0" filter but satisfies the runtime "<10" filter, so switching to the runtime
    // filter must bring C1 back (and, since C2's total 50 fails "<10", drop C2).
    [Test]
    procedure ColumnFilterOnJoinedSum_RuntimeFilterOnSameColumn_ReplacesStaticFilter()
    var
        Query: Query "QJ Cust Orders Sum Filtered";
        RowCount: Integer;
        LastCust: Code[20];
        LastTotal: Decimal;
    begin
        Initialize();
        InsertCust('C1');
        InsertCust('C2');
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
        Assert.AreEqual(0, LastTotal, 'C1''s joined group total must be 0 (100 + -100)');
    end;

    // A static ColumnFilter on a PLAIN (non-aggregated) column of the driving dataitem is
    // still WHERE-style on the JOIN path: it drops raw joined rows before any grouping. Only
    // C1's joined rows may be returned; C2's must not appear.
    [Test]
    procedure ColumnFilterOnJoinedPlainColumn_FiltersRawJoinedRows()
    var
        Query: Query "QJ Cust Orders Filtered";
        RowCount: Integer;
    begin
        Initialize();
        InsertCust('C1');
        InsertCust('C2');
        InsertOrder(1, 'C1', 10);
        InsertOrder(2, 'C2', 20);
        InsertOrder(3, 'C1', 30);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual('C1', Query.CustNo, 'Only C1''s joined rows may pass the static ColumnFilter');
        end;
        Query.Close();

        Assert.AreEqual(2, RowCount, 'Both of C1''s joined rows must be returned, none of C2''s');
    end;

    // Negative sibling: no joined row satisfies the static ColumnFilter, so the result must be
    // completely empty — proving the filter is genuinely evaluated per joined row, not a no-op.
    [Test]
    procedure ColumnFilterOnJoinedPlainColumn_NoRowMatches_ReturnsNoRows()
    var
        Query: Query "QJ Cust Orders Filtered";
    begin
        Initialize();
        InsertCust('C2');
        InsertCust('C3');
        InsertOrder(1, 'C2', 10);
        InsertOrder(2, 'C3', 20);

        Query.Open();
        Assert.IsFalse(Query.Read(), 'No joined row is for customer C1, so the result must be empty');
        Query.Close();
    end;
}
