// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The member Begin, unquoted, in an option variable's member list, `O: Option Zero,Begin;` (al-runner issue 8657).
// Quoted, as "Begin", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53562 "MNC KO3562"
{
    procedure P()
    var
        O: Option Zero,Begin;

    begin
    end;
}
