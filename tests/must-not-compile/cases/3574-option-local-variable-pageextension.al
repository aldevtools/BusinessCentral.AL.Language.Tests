// @expect AL0105 | Syntax error, identifier expected; 'pageextension' is a keyword
// The member PageExtension, unquoted, in an option variable's member list, `O: Option Zero,PageExtension;` (al-runner issue 8657).
// Quoted, as "PageExtension", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53574 "MNC KO3574"
{
    procedure P()
    var
        O: Option Zero,PageExtension;

    begin
    end;
}
