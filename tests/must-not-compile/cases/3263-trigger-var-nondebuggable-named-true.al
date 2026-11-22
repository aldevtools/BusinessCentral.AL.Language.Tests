// @expect AL0303 | Attributes can only be defined on variables and methods.
// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The OnRun trigger of a codeunit declares `[NonDebuggable] True: Text;` (al-runner issue 8539).
// With [NonDebuggable] the other 15 words of this list (Key, Area, TextElement, ...) compile as variable names; event, true and false do not: tests/al-language/language/Bn3Labels.al.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53263 "MNC KV3263"
{
    trigger OnRun()
    var
        [NonDebuggable]
        True: Text;
    begin
    end;
}
