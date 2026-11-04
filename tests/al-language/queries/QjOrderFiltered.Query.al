// A query column's static ColumnFilter property, on a PLAIN (non-aggregated) column — a
// WHERE-style filter: it drops individual raw rows, applied before any grouping. Reuses the
// "QJ Order" table already established by the sibling join/aggregation suites.
query 60769 "QJ Order Filtered"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(EntryNo; "Entry No.") { }
            column(CustNo; "Customer No.")
            {
                ColumnFilter = CustNo = const('C1');
            }
            column(Amount; Amount) { }
        }
    }
}
