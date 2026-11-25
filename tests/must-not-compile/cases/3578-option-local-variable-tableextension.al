// @expect AL0105 | Syntax error, identifier expected; 'tableextension' is a keyword
// The member TableExtension, unquoted, in an option variable's member list, `O: Option Zero,TableExtension;` (al-runner issue 8657).
// Quoted, as "TableExtension", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53578 "MNC KO3578"
{
    procedure P()
    var
        O: Option Zero,TableExtension;

    begin
    end;
}
