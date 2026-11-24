// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The member Begin, unquoted, in the first member of an option variable, `O: Option Begin,Zero;` (al-runner issue 8657).
// Quoted, as "Begin", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53599 "MNC KO3599"
{
    procedure P()
    var
        O: Option Begin,Zero;

    begin
    end;
}
