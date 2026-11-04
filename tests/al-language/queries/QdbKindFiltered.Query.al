// Fixture for TestQueryDataItemTableFilterDatabaseConst.al. The table filter's const names an
// OBJECT through Database::, which the compiler replaces with the object id.
query 69980 "QDB Kind Filtered"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "QDB Row")
        {
            DataItemTableFilter = Kind = const(Database::"QDB Row");

            column(RowCode; Code)
            {
            }
        }
    }
}
