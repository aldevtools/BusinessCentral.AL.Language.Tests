// @expect AL0519 | 'PageExtension' is not valid value in this context.
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// The OnRun trigger of a codeunit declares a variable named PageExtension, unquoted, after another declaration of its var section (al-runner issue 8539).
// Quoted, as "PageExtension", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53254 "MNC KV3254"
{
    trigger OnRun()
    var
        Other: Integer;
        PageExtension: Integer;
    begin
    end;
}
