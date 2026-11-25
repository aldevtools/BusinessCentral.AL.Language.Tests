// @expect AL0105 | Syntax error, identifier expected; 'true' is a keyword
// The member True, unquoted, in a codeunit's global option variable (al-runner issue 8657).
// Quoted, as "True", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53586 "MNC KO3586"
{
    var
        O: Option Zero,True;
    procedure P()
    begin
    end;
}
