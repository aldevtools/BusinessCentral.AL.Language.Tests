// @expect AL0139 | Since 'OnInsert' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnInsert trigger of a table.
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    trigger OnInsert()
    begin
        exit(1);
    end;
}
