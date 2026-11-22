// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0105 | Syntax error, identifier expected; 'key' is a keyword
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ':' expected
// @expect AL0107 | Syntax error, identifier expected
// The OnRun trigger of a codeunit declares `Other, Key: Integer;`: Key, unquoted, as the second name of a list (al-runner issue 8539).
// After a comma the compiler also rejects begin, end, of, procedure, trigger and var (AL0107 at the word); `Other, Local: Integer;` compiles: tests/al-language/language/Bn3Labels.al.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53259 "MNC KV3259"
{
    trigger OnRun()
    var
        Other, Key: Integer;
    begin
    end;
}
