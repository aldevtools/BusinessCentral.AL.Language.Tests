// A nested dataitem that declares NO SqlJoinType at all. AL's default for the property is
// what this query exists to pin — see TestQueryJoinDefaultType.al for the assertion and why
// a query that spells the join out cannot answer the question.
query 60601 "QJ Cust Orders Implicit"
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

                column(EntryNo; "Entry No.") { }
                column(Amount; "Amount") { }
            }
        }
    }
}
