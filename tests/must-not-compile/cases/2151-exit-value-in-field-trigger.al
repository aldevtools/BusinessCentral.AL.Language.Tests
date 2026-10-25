// @expect AL0139 | Since 'OnValidate' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnValidate trigger of a table field.
table 50000 "MNC SH Table"
{
    fields
    {
        field(1; Id; Integer)
        {
            trigger OnValidate()
            begin
                exit(true);
            end;
        }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
