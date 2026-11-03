// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/query/query-data-type
//   dev-itpro/developer/devenv-query-object
// Scope: in-scope
// Fixtures used: QJ Order (60862), QJ Order Sum (60760), QJ Order Scalar Sum (60761); shared Assert (60021)
//
// A query column declaring Method = Sum/Count/Average/Min/Max implicitly groups the result
// by every OTHER (non-aggregated) column in the query, and computes the aggregate PER GROUP
// — exactly what the compiled SQL SELECT ... GROUP BY does. A query with only aggregated
// columns (no grouping column at all) is the scalar-aggregate case: always exactly one
// output row, even over zero matching source rows.
codeunit 60762 "QJ Query Aggregation Tests"
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

    // Two customers, C1 with two orders and C2 with one — the grouped result must have
    // exactly one row per customer, with every aggregate computed over that customer's
    // orders only (not the whole table).
    [Test]
    procedure GroupedAggregation_ComputesEachMethodPerGroup()
    var
        Query: Query "QJ Order Sum";
        C1Seen, C2Seen : Boolean;
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', 200);
        InsertOrder(3, 'C2', 50);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            case Query.CustNo of
                'C1':
                    begin
                        C1Seen := true;
                        Assert.AreEqual(300, Query.TotalAmount, 'C1 Sum must total both its orders');
                        Assert.AreEqual(2, Query.CountAmount, 'C1 Count must be 2');
                        Assert.AreEqual(150, Query.AverageAmount, 'C1 Average must be 150');
                        Assert.AreEqual(100, Query.MinAmount, 'C1 Min must be 100');
                        Assert.AreEqual(200, Query.MaxAmount, 'C1 Max must be 200');
                    end;
                'C2':
                    begin
                        C2Seen := true;
                        Assert.AreEqual(50, Query.TotalAmount, 'C2 Sum must equal its single order');
                        Assert.AreEqual(1, Query.CountAmount, 'C2 Count must be 1');
                        Assert.AreEqual(50, Query.AverageAmount, 'C2 Average must equal its single order');
                        Assert.AreEqual(50, Query.MinAmount, 'C2 Min must equal its single order');
                        Assert.AreEqual(50, Query.MaxAmount, 'C2 Max must equal its single order');
                    end;
                else
                    Error('Unexpected CustNo %1 - grouping produced an extra/wrong group', Query.CustNo);
            end;
        end;
        Query.Close();

        Assert.IsTrue(C1Seen, 'C1 group must be present');
        Assert.IsTrue(C2Seen, 'C2 group must be present');
        Assert.AreEqual(2, RowCount, 'Grouping must produce exactly one row per distinct CustNo, not one per raw order row');
    end;

    // Negative sibling: a wrong implementation that returns one row PER RAW ORDER instead of
    // per group would still let the C1/C2 case ABOVE happen to read plausible individual
    // values on the FIRST row of each group and simply be checked twice more — this asserts
    // the row COUNT directly against a single customer with three separate orders, where an
    // ungrouped result is unambiguously 3 rows instead of 1.
    [Test]
    procedure GroupedAggregation_SingleCustomerMultipleOrders_ProducesOneRow()
    var
        Query: Query "QJ Order Sum";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 10);
        InsertOrder(2, 'C1', 20);
        InsertOrder(3, 'C1', 30);

        Query.Open();
        while Query.Read() do
            RowCount += 1;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'Three orders for the SAME customer must group into exactly one row');
    end;

    // Scalar aggregate (no grouping column at all): exactly one row over the whole table.
    [Test]
    procedure ScalarAggregation_NonEmptyTable_ReturnsOneRowOverTheWholeTable()
    var
        Query: Query "QJ Order Scalar Sum";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 100);
        InsertOrder(2, 'C1', 200);
        InsertOrder(3, 'C2', 50);

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual(350, Query.TotalAmount, 'Scalar Sum must total every row in the table');
            Assert.AreEqual(3, Query.CountAmount, 'Scalar Count must count every row in the table');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'A scalar aggregate (no grouping column) must return exactly one row');
    end;

    // Scalar aggregate over an EMPTY table: still exactly one row (SQL's "GROUP BY ()" is
    // always one group), with the aggregates defaulting rather than the query returning zero
    // rows the way a query WITH a grouping column would over an empty table.
    [Test]
    procedure ScalarAggregation_EmptyTable_StillReturnsOneDefaultedRow()
    var
        Query: Query "QJ Order Scalar Sum";
        RowCount: Integer;
    begin
        Initialize();

        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual(0, Query.TotalAmount, 'Sum over an empty table must default to 0');
            Assert.AreEqual(0, Query.CountAmount, 'Count over an empty table must default to 0');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'A scalar aggregate must return exactly one row even over an empty table');
    end;

    // Negative sibling to the empty-table case above: a query WITH a grouping column
    // (Method columns alongside a plain column) over an empty table must return ZERO rows,
    // not one — the scalar-vs-grouped distinction hinges entirely on whether a non-aggregated
    // column is present, so this is the case that would silently break if a fix collapsed
    // both shapes into "always one row" or "always zero rows".
    [Test]
    procedure GroupedAggregation_EmptyTable_ReturnsNoRows()
    var
        Query: Query "QJ Order Sum";
        RowCount: Integer;
    begin
        Initialize();

        Query.Open();
        while Query.Read() do
            RowCount += 1;
        Query.Close();

        Assert.AreEqual(0, RowCount, 'A query WITH a grouping column must return zero rows over an empty table, unlike the scalar-aggregate case');
    end;

    // A runtime SetFilter on an AGGREGATED column is a HAVING-clause filter: it is evaluated
    // against the per-group aggregated result, not against the raw source row. C1's two raw
    // orders (60 and 60) never individually satisfy "> 100"; only their sum (120) does. C2's
    // single raw order (100) does not satisfy it either, and neither does its sum (100).
    // A WHERE-style (pre-aggregation, per-row) application of the same filter would keep no
    // customer at all, which is a different and distinguishable answer from the one below.
    [Test]
    procedure FilterOnAggregatedColumn_EvaluatesAgainstGroupResult_NotRawRow()
    var
        Query: Query "QJ Order Sum";
        RowCount: Integer;
    begin
        Initialize();
        InsertOrder(1, 'C1', 60);
        InsertOrder(2, 'C1', 60);
        InsertOrder(3, 'C2', 100);

        Query.SetFilter(TotalAmount, '>%1', 100);
        Query.Open();
        while Query.Read() do begin
            RowCount += 1;
            Assert.AreEqual('C1', Query.CustNo, 'Only C1 has a group sum greater than 100');
            Assert.AreEqual(120, Query.TotalAmount, 'C1 group sum must be 120 (60+60)');
        end;
        Query.Close();

        Assert.AreEqual(1, RowCount, 'A filter on an aggregated column must keep exactly one group (C1)');
    end;

    // Negative sibling: a bound no group's aggregate reaches must return zero rows, proving
    // the filter is genuinely evaluated and not dropped.
    [Test]
    procedure FilterOnAggregatedColumn_ExcludingEveryGroup_ReturnsNoRows()
    var
        Query: Query "QJ Order Sum";
    begin
        Initialize();
        InsertOrder(1, 'C1', 60);
        InsertOrder(2, 'C1', 60);
        InsertOrder(3, 'C2', 100);

        Query.SetFilter(TotalAmount, '>%1', 1000);
        Query.Open();
        Assert.IsFalse(Query.Read(), 'No group sum reaches 1000, so the result must be empty');
        Query.Close();
    end;
}
