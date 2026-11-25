// @expect AL0104 | Syntax error, ';' expected
// The member End, unquoted, in the last member of an option parameter, `Option Zero,End` (al-runner issue 8657, PR 8663 review).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53622 "MNC KO3622"
{
    procedure P(O: Option Zero,End)
    begin
    end;
}
