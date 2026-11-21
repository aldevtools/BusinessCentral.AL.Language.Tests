// @expect AL0105 | Syntax error, identifier expected; 'of' is a keyword
// The member Of, unquoted, in an option variable's member list, `O: Option Zero,Of;` (al-runner issue 8657).
// Quoted, as "Of", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53573 "MNC KO3573"
{
    procedure P()
    var
        O: Option Zero,Of;

    begin
    end;
}
