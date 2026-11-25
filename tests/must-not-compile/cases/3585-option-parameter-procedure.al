// @expect AL0105 | Syntax error, identifier expected; 'procedure' is a keyword
// The member Procedure, unquoted, in an option parameter, `procedure P(O: Option Zero,Procedure)` (al-runner issue 8657).
// Quoted, as "Procedure", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53585 "MNC KO3585"
{
    procedure P(O: Option Zero,Procedure)
    begin
    end;
}
