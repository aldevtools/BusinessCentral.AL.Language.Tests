// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in a page procedure without a return type.
table 50000 "MNC SH Base Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }
}

page 50001 "MNC SH Page"
{
    SourceTable = "MNC SH Base Table";

    local procedure DoIt()
    begin
        exit(1);
    end;
}
