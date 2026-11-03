// Fixture for query/TestQueryDependencyTable.al — a source-defined query whose only dataitem
// is a Base Application table (a dependency, not an application-local one).
query 60982 "IQ Item Rows"
{
    Access = Public;
    QueryType = Normal;

    elements
    {
        dataitem(Item; Item)
        {
            column(No; "No.")
            {
            }
        }
    }
}
