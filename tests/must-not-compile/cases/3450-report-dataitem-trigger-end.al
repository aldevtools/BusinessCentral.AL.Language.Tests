// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// The member is a data item's field written in its OnAfterGetRecord, unquoted (al-runner issue 8635).
// Quoted, as "End", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53450 "MNC KM3450"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "End"; Integer)
        {
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

report 53450 "MNC KM3450 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KM3450")
        {
            trigger OnAfterGetRecord()
            begin
                Row.End := 1;
            end;
        }
    }
}
