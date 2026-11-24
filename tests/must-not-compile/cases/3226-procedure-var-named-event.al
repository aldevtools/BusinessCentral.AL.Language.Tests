// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0301 | A list must end with a member; not a separator ;.
// @expect AL0104 | Syntax error, ')' expected
// A codeunit procedure declares a variable named Event, unquoted, as the first declaration of its var section (al-runner issue 8539).
// Quoted, as "Event", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53226 "MNC KV3226"
{
    procedure P()
    var
        Event: Integer;
    begin
    end;
}
