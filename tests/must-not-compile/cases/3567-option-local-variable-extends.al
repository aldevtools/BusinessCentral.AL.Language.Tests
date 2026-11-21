// @expect AL0105 | Syntax error, identifier expected; 'extends' is a keyword
// The member Extends, unquoted, in an option variable's member list, `O: Option Zero,Extends;` (al-runner issue 8657).
// Quoted, as "Extends", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53567 "MNC KO3567"
{
    procedure P()
    var
        O: Option Zero,Extends;

    begin
    end;
}
