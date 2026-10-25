// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in a table procedure without a return type.
table 50000 "MNC SH Table"
{
    fields { field(1; Id; Integer) { } }
    keys { key(PK; Id) { Clustered = true; } }

    procedure DoIt()
    begin
        exit('x');
    end;
}
