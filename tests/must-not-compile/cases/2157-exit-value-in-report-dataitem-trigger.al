// @expect AL0139 | Since 'OnAfterGetRecord' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnAfterGetRecord trigger of a report data item.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

report 50001 "MNC SH Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(B; "MNC SH Base Table")
        {
            trigger OnAfterGetRecord()
            begin
                exit(1);
            end;
        }
    }
}
