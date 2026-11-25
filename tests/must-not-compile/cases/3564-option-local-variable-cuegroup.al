// @expect AL0105 | Syntax error, identifier expected; 'cuegroup' is a keyword
// The member CueGroup, unquoted, in an option variable's member list, `O: Option Zero,CueGroup;` (al-runner issue 8657).
// Quoted, as "CueGroup", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53564 "MNC KO3564"
{
    procedure P()
    var
        O: Option Zero,CueGroup;

    begin
    end;
}
