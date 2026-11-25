// @expect AL0105 | Syntax error, identifier expected; 'textelement' is a keyword
// The member TextElement, unquoted, in an option variable's member list, `O: Option Zero,TextElement;` (al-runner issue 8657).
// Quoted, as "TextElement", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53580 "MNC KO3580"
{
    procedure P()
    var
        O: Option Zero,TextElement;

    begin
    end;
}
