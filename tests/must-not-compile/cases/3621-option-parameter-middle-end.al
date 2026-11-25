// @expect AL0104 | Syntax error, ';' expected
// The member End, unquoted, in a middle member of an option parameter, `Option Zero,End,One` (al-runner issue 8657, PR 8663 review).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53621 "MNC KO3621"
{
    procedure P(O: Option Zero,End,One)
    begin
    end;
}
