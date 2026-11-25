// @expect AL0105 | Syntax error, identifier expected; 'chartpart' is a keyword
// The member ChartPart, unquoted, in an option variable's member list, `O: Option Zero,ChartPart;` (al-runner issue 8657).
// Quoted, as "ChartPart", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53563 "MNC KO3563"
{
    procedure P()
    var
        O: Option Zero,ChartPart;

    begin
    end;
}
