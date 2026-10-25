// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in an xmlport procedure without a return type.
xmlport 50001 "MNC SH Xmlport"
{
    schema
    {
        textelement(Root)
        {
        }
    }

    procedure DoIt()
    begin
        exit(1);
    end;
}
