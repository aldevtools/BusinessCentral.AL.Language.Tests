// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0301 | A list must end with a member; not a separator ;.
// @expect AL0104 | Syntax error, ')' expected
// A codeunit global var section declares `[NonDebuggable] Event: Text;` (al-runner issue 8539).
// With [NonDebuggable] the other 15 words of this list (Key, Area, TextElement, ...) compile as variable names; event, true and false do not: tests/al-language/language/Bn3Labels.al.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53260 "MNC KV3260"
{
    var
        [NonDebuggable]
        Event: Text;

    procedure P()
    begin
    end;
}
