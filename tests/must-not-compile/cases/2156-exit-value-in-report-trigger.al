// @expect AL0139 | Since 'OnPreReport' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in the OnPreReport trigger of a report.
report 50001 "MNC SH Report"
{
    ProcessingOnly = true;

    trigger OnPreReport()
    begin
        exit(1);
    end;
}
