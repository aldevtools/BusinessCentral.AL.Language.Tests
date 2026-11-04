// A multi-dataitem JOIN query whose AGGREGATED (Method = Sum) column also carries a static
// ColumnFilter — a HAVING-style filter, evaluated after the implicit GROUP BY the join
// performs over its aggregated column, dropping whole groups rather than raw rows. Reuses the
// "QJ Customer"/"QJ Order" tables already established by TestQueryJoin.al.
query 60780 "QJ Cust Orders Sum Filtered"
{
    QueryType = Normal;
    OrderBy = ascending(CustNo);

    elements
    {
        dataitem(Customer; "QJ Customer")
        {
            column(CustNo; "No.") { }

            dataitem(Ord; "QJ Order")
            {
                DataItemLink = "Customer No." = Customer."No.";
                SqlJoinType = InnerJoin;

                column(TotalAmount; Amount)
                {
                    ColumnFilter = TotalAmount = filter(> 0);
                    Method = Sum;
                }
            }
        }
    }
}
