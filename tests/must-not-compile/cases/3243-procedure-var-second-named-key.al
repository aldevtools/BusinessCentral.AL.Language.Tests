// @expect AL0519 | 'Key' is not valid value in this context.
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// A codeunit procedure declares a variable named Key, unquoted, after another declaration of its var section (al-runner issue 8539).
// Quoted, as "Key", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53243 "MNC KV3243"
{
    procedure P()
    var
        Other: Integer;
        Key: Integer;
    begin
    end;
}
