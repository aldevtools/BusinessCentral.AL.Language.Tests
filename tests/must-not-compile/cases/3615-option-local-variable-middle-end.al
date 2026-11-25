// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// The member End, unquoted, in a middle member of an option variable, `Option Zero,End,One` (al-runner issue 8657, PR 8663 review).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53615 "MNC KO3615"
{
    procedure P()
    var
        O: Option Zero,End,One;

    begin
    end;
}
