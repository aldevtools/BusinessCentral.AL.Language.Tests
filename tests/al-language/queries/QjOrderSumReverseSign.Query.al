// A query column declaring BOTH Method = Sum and ReverseSign = true — the sign flip and the
// aggregation are mathematically commutative for Sum (negating every source row before
// summing, or negating the sum afterward, produce the same result regardless of the mix of
// signs among the source rows), so this exists to pin the observable OUTCOME rather than to
// distinguish an ordering that Sum itself cannot distinguish. Reuses the "QJ Order" table
// already established by the sibling join/aggregation suites.
query 60939 "QJ Order Sum Reverse Sign"
{
    QueryType = Normal;
    OrderBy = ascending(CustNo);

    elements
    {
        dataitem(Order; "QJ Order")
        {
            column(CustNo; "Customer No.") { }
            column(TotalAmount; Amount) { Method = Sum; ReverseSign = true; }
        }
    }
}
