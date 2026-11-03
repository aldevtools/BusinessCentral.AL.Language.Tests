// Fixture for query/TestQueryFlowFieldColumn.al — a query column backed by a FlowField whose
// CalcFormula narrows the aggregate with a flow filter, plus the `filter()` element that sets
// that flow filter.
query 60271 "QFF Header Dated"
{
    QueryType = Normal;
    elements
    {
        dataitem(QffHeader; "QFF Header")
        {
            column(No; "No.") { }
            filter(DateFilter; "Date Filter") { }
            column(DatedAmount; "Dated Amount") { }
        }
    }
}
