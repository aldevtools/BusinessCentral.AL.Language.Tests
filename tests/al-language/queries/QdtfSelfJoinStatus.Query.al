// A self-join whose two dataitems each carry a filter column over the SAME source field
// (Status). Both columns are independent query columns — OuterStatus and InnerStatus — and a
// runtime SetRange on each has to reach its own dataitem, not be merged into one condition.
// The link is the primary key, so the two dataitems always resolve to the same row, which is
// what makes a contradictory pair of filters return nothing.
query 60508 "QDTF Self Join Status"
{
    QueryType = Normal;
    OrderBy = ascending(RowCode);

    elements
    {
        dataitem(Outer; "QDTF Row")
        {
            column(RowCode; "Code") { }
            filter(OuterStatus; Status) { }

            dataitem(Inner; "QDTF Row")
            {
                DataItemLink = "Code" = Outer."Code";
                SqlJoinType = InnerJoin;

                filter(InnerStatus; Status) { }
            }
        }
    }
}
