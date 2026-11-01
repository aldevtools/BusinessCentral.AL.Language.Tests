// @expect AL0196 | The call is ambiguous between the method 'Pub()' defined in ReportExtension 'MNC Y64 Report Ext'
// A report extension declares a local procedure with the name of a public procedure of its base report and calls it by its bare name from a
// report trigger: the call is ambiguous (al-runner issue 6651; the page extension form is case 2239). Declared inside the request page, the
// procedure hides the base one there: tests/al-language/reportext/lt-y64-local-proc-names/Y64LocalProcNames.al.
table 52626 "MNC Y64 Row" { fields { field(1; Id; Integer) { } } keys { key(PK; Id) { Clustered = true; } } }
report 52626 "MNC Y64 Report"
{
    ProcessingOnly = true;
    dataset { dataitem(Row; "MNC Y64 Row") { } }
    procedure Pub() begin end;
}
reportextension 52627 "MNC Y64 Report Ext" extends "MNC Y64 Report"
{
    trigger OnPreReport()
    begin
        Pub();
    end;
    local procedure Pub() begin end;
}
