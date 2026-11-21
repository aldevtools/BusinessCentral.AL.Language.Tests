// @expect AL0105 | Syntax error, identifier expected; 'procedure' is a keyword
// The member Procedure, unquoted, in an option variable's member list, `O: Option Zero,Procedure;` (al-runner issue 8657).
// Quoted, as "Procedure", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53575 "MNC KO3575"
{
    procedure P()
    var
        O: Option Zero,Procedure;

    begin
    end;
}
