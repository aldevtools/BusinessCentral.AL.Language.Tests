// A query column's static ColumnFilter property, on an AGGREGATED (Method = Sum) column —
// a HAVING-style filter: it drops GROUPS whose aggregated total fails it, evaluated after
// the implicit GROUP BY, not against individual raw rows. Reuses the "QJ Order" table already
// established by the sibling join/aggregation suites (TestQueryJoin.al, TestQueryAggregation.al)
// rather than introducing a new fixture table for the same shape.
query 60768 "QJ Order Sum Filtered"
{
    QueryType = Normal;
    OrderBy = ascending(CustNo);

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(CustNo; "Customer No.") { }
            column(TotalAmount; Amount)
            {
                ColumnFilter = TotalAmount = filter(> 0);
                Method = Sum;
            }
        }
    }
}
