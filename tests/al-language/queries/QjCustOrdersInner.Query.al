// Migrated from AL Runner tests/runner-extras/query-join (src/Queries.al).
// InnerJoin: a customer with no order row is dropped from the result.
query 60863 "QJ Cust Orders Inner"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Customer; "QJ Customer")
        {
            column(CustNo; "No.") { }
            column(CustName; "Name") { }

            dataitem(Ord; "QJ Order")
            {
                DataItemLink = "Customer No." = Customer."No.";
                SqlJoinType = InnerJoin;

                column(EntryNo; "Entry No.") { }
                column(Amount; "Amount") { }
            }
        }
    }
}
