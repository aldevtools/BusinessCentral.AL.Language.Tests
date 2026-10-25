// @expect AL0139 | Since 'OnBeforeOpen' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnBeforeOpen trigger of a query.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

query 50001 "MNC SH Query"
{
    elements
    {
        dataitem(B; "MNC SH Base Table")
        {
            column(Id; Id) { }
        }
    }

    trigger OnBeforeOpen()
    begin
        exit(1);
    end;
}
