// @expect AL0105 | Syntax error, identifier expected; 'actions' is a keyword
// The member Actions, unquoted, in an option variable's member list, `O: Option Zero,Actions;` (al-runner issue 8657).
// Quoted, as "Actions", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53560 "MNC KO3560"
{
    procedure P()
    var
        O: Option Zero,Actions;

    begin
    end;
}
