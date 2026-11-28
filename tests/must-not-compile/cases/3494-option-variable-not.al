// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an option variable's member, `O := O::Not;`, unquoted (al-runner issue 8649).
// Quoted, as "Not", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
codeunit 58494 "MNC KS3494 Use"
{
    procedure P()
    var
        O: Option Zero,"Not";

    begin
        O := O::Not;
    end;
}
