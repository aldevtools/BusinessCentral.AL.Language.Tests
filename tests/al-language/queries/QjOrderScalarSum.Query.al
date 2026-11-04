// Sibling of "QJ Order Sum" with NO non-aggregated column at all — BC's scalar-aggregate
// case. A GROUP BY with no grouping column is still exactly one group (SQL's "GROUP BY ()"),
// so this always returns exactly one row, even over an empty table.
query 60761 "QJ Order Scalar Sum"
{
    QueryType = Normal;

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(TotalAmount; Amount) { Method = Sum; }
            column(CountAmount) { Method = Count; }
        }
    }
}
