// @expect AL0139 | Since 'OnAfterInsert' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnAfterInsert trigger of a table extension.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

tableextension 50001 "MNC SH Table Ext" extends "MNC SH Base Table"
{
    trigger OnAfterInsert()
    begin
        exit(1);
    end;
}
