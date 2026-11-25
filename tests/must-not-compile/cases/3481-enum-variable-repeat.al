// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0104 | Syntax error, 'until' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The name after `::` is an enum value through an enum variable, `K := K::Repeat;`, unquoted (al-runner issue 8649).
// Quoted, as "Repeat", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53481 "MNC KS3481"
{
    value(0; Zero)
    {
    }
    value(1; "Repeat")
    {
    }
}

codeunit 58481 "MNC KS3481 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3481";

    begin
        K := K::Repeat;
    end;
}
