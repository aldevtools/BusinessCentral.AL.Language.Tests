// A multi-dataitem JOIN query whose PLAIN (non-aggregated) column on the driving dataitem
// carries a static ColumnFilter — a WHERE-style filter, evaluated against raw joined rows
// before any grouping. Reuses the "QJ Customer"/"QJ Order" tables already established by
// TestQueryJoin.al.
query 60781 "QJ Cust Orders Filtered"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Customer; "QJ Customer")
        {
            column(CustNo; "No.")
            {
                ColumnFilter = CustNo = const('C1');
            }

            dataitem(Ord; "QJ Order")
            {
                DataItemLink = "Customer No." = Customer."No.";
                SqlJoinType = InnerJoin;

                column(EntryNo; "Entry No.") { }
                column(Amount; Amount) { }
            }
        }
    }
}
