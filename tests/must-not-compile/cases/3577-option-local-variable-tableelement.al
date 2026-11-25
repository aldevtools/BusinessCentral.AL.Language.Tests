// @expect AL0105 | Syntax error, identifier expected; 'tableelement' is a keyword
// The member TableElement, unquoted, in an option variable's member list, `O: Option Zero,TableElement;` (al-runner issue 8657).
// Quoted, as "TableElement", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53577 "MNC KO3577"
{
    procedure P()
    var
        O: Option Zero,TableElement;

    begin
    end;
}
