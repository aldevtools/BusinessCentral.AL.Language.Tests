// Fixture for query/TestQueryFilterElementGroupBy.al — the single-dataitem counterpart of
// "QFG Join Totals".
query 68602 "QFG Entry Totals"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo);

    elements
    {
        dataitem(Entry; "QFG Entry")
        {
            column(HeaderNo; "Header No.") { }
            column(TotalAmount; Amount) { Method = Sum; }
            column(EntryCount) { Method = Count; }
            filter(DateFilter; "Posting Date") { }
        }
    }
}
