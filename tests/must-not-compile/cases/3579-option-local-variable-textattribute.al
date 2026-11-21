// @expect AL0105 | Syntax error, identifier expected; 'textattribute' is a keyword
// The member TextAttribute, unquoted, in an option variable's member list, `O: Option Zero,TextAttribute;` (al-runner issue 8657).
// Quoted, as "TextAttribute", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53579 "MNC KO3579"
{
    procedure P()
    var
        O: Option Zero,TextAttribute;

    begin
    end;
}
