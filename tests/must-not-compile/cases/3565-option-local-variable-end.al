// @expect AL0104 | Syntax error, ';' expected
// The member End, unquoted, in an option variable's member list, `O: Option Zero,End;` (al-runner issue 8657).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53565 "MNC KO3565"
{
    procedure P()
    var
        O: Option Zero,End;

    begin
    end;
}
