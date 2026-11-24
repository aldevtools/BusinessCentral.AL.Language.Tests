// @expect AL0105 | Syntax error, identifier expected; 'false' is a keyword
// The member False, unquoted, in an option variable's member list, `O: Option Zero,False;` (al-runner issue 8657).
// Quoted, as "False", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53568 "MNC KO3568"
{
    procedure P()
    var
        O: Option Zero,False;

    begin
    end;
}
