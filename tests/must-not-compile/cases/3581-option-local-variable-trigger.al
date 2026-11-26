// @expect AL0105 | Syntax error, identifier expected; 'trigger' is a keyword
// The member Trigger, unquoted, in an option variable's member list, `O: Option Zero,Trigger;` (al-runner issue 8657).
// Quoted, as "Trigger", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53581 "MNC KO3581"
{
    procedure P()
    var
        O: Option Zero,Trigger;

    begin
    end;
}
