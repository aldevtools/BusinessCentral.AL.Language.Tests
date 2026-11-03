// @expect AL0157 | 'TableFilter' is not a valid variable type.
// al-runner issue 5998 (writer SI): a TableFilter exists only as a table field; a local variable of type TableFilter is refused, so
// Evaluate into TableFilter only reaches a field (records/W4PlatformAndMeta.al, TableFilterEvaluate_* tests).
codeunit 50214 "MNC C2214"
{
    procedure Probe()
    var
        Filter: TableFilter;
    begin
        Evaluate(Filter, 'MNC Table: Id=1');
    end;
}
