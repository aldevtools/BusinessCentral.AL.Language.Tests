// @expect AL0161 | 'MyProc()' is inaccessible due to its protection level
// @expect AL0161 | 'MyProc()' is inaccessible due to its protection level
// A procedure declared inside a report extension's request page is visible only inside that request page (al-runner issue 6651): from a data
// item trigger and from a report trigger of the extension the name binds to the base report's local procedure of the same name (AL0161 twice).
// Inside the request page the calls compile and run the extension's procedure: tests/al-language/reportext/lt-y64-local-proc-names/Y64LocalProcNames.al.
table 52624 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
report 52624 "MNC Y64 Report"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC Y64 Row") { } }
    requestpage { layout { area(Content) { field(MyField; MyOption) { } } } }
    var MyOption: Boolean;
    local procedure MyProc() begin end;
}
reportextension 52625 "MNC Y64 Report Ext" extends "MNC Y64 Report"
{
    dataset
    {
        modify(Row)
        {
            trigger OnBeforePreDataItem()
            begin
                MyProc();
            end;
        }
    }
    requestpage
    {
        local procedure MyProc() begin end;
    }
    trigger OnPreReport()
    begin
        MyProc();
    end;
}
