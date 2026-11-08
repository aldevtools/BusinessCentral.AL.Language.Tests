// @expect AL0118 | The name '"MNC Kind"' does not exist in the current context.
// ColumnFilter that names an enum member with the qualified form "Enum"::Member: the column is over a table field with the same name as its enum.
// The same form compiles in DataItemTableFilter (tests/al-language/queries/VqQueryEnumFilter.al).
enum 50900 "MNC Kind"
{
    Extensible = true;
    value(0; Alpha) { }
    value(1; Beta) { }
    value(2; "Gamma Delta") { }
}

table 50901 "MNC Kind Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "MNC Kind") { }
        field(3; "MNC Kind"; Enum "MNC Kind") { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

query 50902 "MNC Kind Query"
{
    QueryType = Normal;

    elements
    {
        dataitem(Row; "MNC Kind Row")
        {
            column(RowId; Id) { }
            column(SameCol; "MNC Kind")
            {
                ColumnFilter = SameCol = filter("MNC Kind"::Beta);
            }
        }
    }
}
