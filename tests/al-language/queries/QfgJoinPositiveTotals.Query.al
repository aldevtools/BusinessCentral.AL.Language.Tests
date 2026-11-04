// Fixture for query/TestQueryFilterElementGroupBy.al — the same JOIN, with a HAVING-style
// ColumnFilter on the aggregated column.
query 68601 "QFG Join Positive Totals"
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

                column(TotalAmount; Amount)
                {
                    Method = Sum;
                    ColumnFilter = TotalAmount = filter(> 0);
                }
                filter(DateFilter; "Posting Date") { }
            }
        }
    }
}
