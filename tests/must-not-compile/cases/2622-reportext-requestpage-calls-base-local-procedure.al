// @expect AL0161 | 'MyProc()' is inaccessible due to its protection level
// A report extension's request page calls a local procedure of its base report that the extension does not declare (al-runner issue 6651).
// The report trigger form is case 0041; with a request page local procedure of the same name the call compiles and runs the extension's own
// (tests/al-language/reportext/lt-y64-local-proc-names/Y64LocalProcNames.al).
table 52622 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
report 52622 "MNC Y64 Report"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC Y64 Row") { } }
    requestpage { layout { area(Content) { field(MyField; MyOption) { } } } }
    var MyOption: Boolean;
    local procedure MyProc() begin end;
}
reportextension 52623 "MNC Y64 Report Ext" extends "MNC Y64 Report"
{
    requestpage
    {
        trigger OnOpenPage()
        begin
            MyProc();
        end;
    }
}
