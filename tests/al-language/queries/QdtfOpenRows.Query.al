// The filtered field (Status) is deliberately NOT projected as a column: DataItemTableFilter
// restricts the dataitem's own TABLE rows and needs no result column, which is what
// distinguishes it from a column's ColumnFilter property.
query 60500 "QDTF Open Rows"
{
    QueryType = Normal;
    OrderBy = ascending(RowCode);

    elements
    {
        dataitem(Row; "QDTF Row")
        {
            DataItemTableFilter = Status = const(Open);

            column(RowCode; "Code") { }
            column(RowAmount; Amount) { }
        }
    }
}
