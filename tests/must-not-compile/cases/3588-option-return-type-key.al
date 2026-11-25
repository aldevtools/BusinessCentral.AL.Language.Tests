// @expect AL0105 | Syntax error, identifier expected; 'key' is a keyword
// The member Key, unquoted, in an option return type, `procedure P(): Option Zero,Key` (al-runner issue 8657).
// Quoted, as "Key", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53588 "MNC KO3588"
{
    procedure P(): Option Zero,Key
    begin
    end;
}
