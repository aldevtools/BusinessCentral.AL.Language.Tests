// @expect AL0105 | Syntax error, identifier expected; 'area' is a keyword
// The member Area, unquoted, in an option variable's member list, `O: Option Zero,Area;` (al-runner issue 8657).
// Quoted, as "Area", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53561 "MNC KO3561"
{
    procedure P()
    var
        O: Option Zero,Area;

    begin
    end;
}
