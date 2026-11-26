// @expect AL0105 | Syntax error, identifier expected; 'profileextension' is a keyword
// The member ProfileExtension, unquoted, in an option variable's member list, `O: Option Zero,ProfileExtension;` (al-runner issue 8657).
// Quoted, as "ProfileExtension", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53576 "MNC KO3576"
{
    procedure P()
    var
        O: Option Zero,ProfileExtension;

    begin
    end;
}
