// @expect AL0105 | Syntax error, identifier expected; 'key' is a keyword
// The member Key, unquoted, in an option variable's member list, `O: Option Zero,Key;` (al-runner issue 8657).
// Quoted, as "Key", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53572 "MNC KO3572"
{
    procedure P()
    var
        O: Option Zero,Key;

    begin
    end;
}
