// Same dataitem, same field, TWO filters: the static DataItemTableFilter names Status, and
// RowStatus is a filter column over that same field, so a runtime SetRange reaches it. This is
// the shape TestQueryDataItemTableFilter.al's older runtime-filter tests deliberately avoid —
// they filter at runtime on RowCode, a DIFFERENT field.
query 60507 "QDTF Status Filtered"
{
    QueryType = Normal;
    OrderBy = ascending(RowCode);

    elements
    {
        dataitem(Row; "QDTF Row")
        {
            DataItemTableFilter = Status = const(Open);

            column(RowCode; "Code") { }
            filter(RowStatus; Status) { }
        }
    }
}
