// @expect AL0519 | 'End' is not valid value in this context
// The member End, unquoted, in an option return type, `procedure P(): Option Zero,End` (al-runner issue 8657).
// Quoted, as "End", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53589 "MNC KO3589"
{
    procedure P(): Option Zero,End
    begin
    end;
}
