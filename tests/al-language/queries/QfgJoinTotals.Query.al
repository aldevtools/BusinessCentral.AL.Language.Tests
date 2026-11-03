// Fixture for query/TestQueryFilterElementGroupBy.al — a JOIN whose joined dataitem carries a
// filter() element beside aggregated columns.
query 68600 "QFG Join Totals"
{
    QueryType = Normal;
    OrderBy = ascending(HeaderNo);

    elements
    {
        dataitem(Header; "QFG Header")
        {
            column(HeaderNo; "No.") { }

            dataitem(Entry; "QFG Entry")
            {
                DataItemLink = "Header No." = Header."No.";
                SqlJoinType = InnerJoin;

                column(TotalAmount; Amount) { Method = Sum; }
                column(EntryCount) { Method = Count; }
                filter(DateFilter; "Posting Date") { }
            }
        }
    }
}
