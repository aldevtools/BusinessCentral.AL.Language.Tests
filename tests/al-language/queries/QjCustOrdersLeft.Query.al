// Migrated from AL Runner tests/runner-extras/query-join (src/Queries.al).
// LeftOuterJoin: a customer with no order row is KEPT, with null/default child columns.
query 60864 "QJ Cust Orders Left"
{
    QueryType = Normal;
    OrderBy = ascending(CustNo);

    elements
    {
        dataitem(Customer; "QJ Customer")
        {
            column(CustNo; "No.") { }
            column(CustName; "Name") { }

            dataitem(Ord; "QJ Order")
            {
                DataItemLink = "Customer No." = Customer."No.";
                SqlJoinType = LeftOuterJoin;

                column(EntryNo; "Entry No.") { }
                column(Amount; "Amount") { }
            }
        }
    }
}
