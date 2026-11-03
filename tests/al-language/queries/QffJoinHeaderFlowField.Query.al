query 60955 "QFF Join Header FlowField"
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
                column(TotalAmount; "Total Amount") { }
            }
        }
    }
}
