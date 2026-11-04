// A query column's ReverseSign property negates the value it reads, independent of every
// OTHER column in the query — a sibling column over the SAME field without ReverseSign must
// keep reading the un-negated value. Reuses the "QJ Order" table already established by the
// sibling join/aggregation suites.
query 60935 "QJ Order Reverse Sign"
{
    QueryType = Normal;
    OrderBy = ascending(EntryNo);

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(EntryNo; "Entry No.") { }
            column(Amount; Amount) { }
            column(ReversedAmount; Amount) { ReverseSign = true; }
        }
    }
}
