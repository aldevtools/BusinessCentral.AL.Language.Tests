// Two conditions on DIFFERENT fields, combined. Both must hold for a row to survive.
query 60501 "QDTF Two Field Filter"
{
    QueryType = Normal;
    OrderBy = ascending(RowCode);

    elements
    {
        dataitem(Row; "QDTF Row")
        {
            DataItemTableFilter = Status = const(Open), Amount = filter(> 100);

            column(RowCode; "Code") { }
        }
    }
}
