// @expect AL0139 | Since 'DoIt' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in a report procedure without a return type.
report 50001 "MNC SH Report"
{
    ProcessingOnly = true;

    procedure DoIt()
    begin
        exit(1);
    end;
}
