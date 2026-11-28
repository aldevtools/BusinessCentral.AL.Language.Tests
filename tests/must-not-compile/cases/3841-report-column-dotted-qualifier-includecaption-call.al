// @expect AL0385 | IncludeCaption can be set to true only if the source of the column is a named field.
// IncludeCaption = true on a report column whose source is a method call on a field qualified with a quoted data item name that
// holds a dot and a space: "Dq. Row".Name.ToUpper(). Without IncludeCaption the column compiles (corpus issue 1648,
// tests/al-language/reports/dataset/DataItemNamesDottedQualifier.al).
table 50000 "MNC Dq Row"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC Dq Caption Call"
{
    dataset
    {
        dataitem("Dq. Row"; "MNC Dq Row")
        {
            column(NameUpper; "Dq. Row".Name.ToUpper()) { IncludeCaption = true; }
        }
    }
}
