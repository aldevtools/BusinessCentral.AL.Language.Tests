// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The OnRun trigger of a codeunit declares a variable named Event, unquoted, after another declaration of its var section (al-runner issue 8539).
// Quoted, as "Event", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53255 "MNC KV3255"
{
    trigger OnRun()
    var
        Other: Integer;
        Event: Integer;
    begin
    end;
}
