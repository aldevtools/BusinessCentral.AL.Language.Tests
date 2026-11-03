// Fixture for query/TestQueryFlowFieldColumn.al — the same flow-filtered FlowField column on
// the non-driving side of a multi-dataitem JOIN.
query 60272 "QFF Join Header Dated"
{
    QueryType = Normal;
    elements
    {
        dataitem(QffLink; "QFF Link")
        {
            column(EntryNo; "Entry No.") { }
            dataitem(QffHeader; "QFF Header")
            {
                DataItemLink = "No." = QffLink."Header No.";
                SqlJoinType = InnerJoin;
                filter(DateFilter; "Date Filter") { }
                column(DatedAmount; "Dated Amount") { }
            }
        }
    }
}
