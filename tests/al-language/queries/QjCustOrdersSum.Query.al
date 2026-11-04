// Sibling of "QJ Cust Orders Inner" with aggregated columns: a multi-dataitem JOIN query
// with Method = Sum/Count implicitly groups the JOINED rows by every OTHER (non-aggregated)
// column — here, CustNo alone — the same GROUP BY the compiled SQL SELECT performs over the
// join. Reuses the "QJ Customer"/"QJ Order" tables already established by TestQueryJoin.al.
query 60903 "QJ Cust Orders Sum"
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

                column(TotalAmount; Amount) { Method = Sum; }
                // Method = Count takes NO data source (AL0353) — it counts rows in the group.
                column(CountOrders) { Method = Count; }
            }
        }
    }
}
