// Fixture for TestQueryJoinStaticFilterElement.al: an aggregated join whose filter() element carries
// a STATIC ColumnFilter. The filter element is not in the dataset, so it is not a group key.
query 69982 "QDB Static Filter Join"
{
    QueryType = Normal;
    OrderBy = ascending(RowCode);

    elements
    {
        dataitem(Header; "QDB Row")
        {
            column(RowCode; Code)
            {
            }
            dataitem(Entry; "QDB Entry")
            {
                DataItemLink = "Item No." = Header.Code;
                SqlJoinType = InnerJoin;

                column(TotalQuantity; Quantity)
                {
                    Method = Sum;
                }
                column(EntryCount)
                {
                    Method = Count;
                }
                filter(EntryNoFilter; "Entry No.")
                {
                    ColumnFilter = EntryNoFilter = filter(2 .. 3);
                }
            }
        }
    }
}
