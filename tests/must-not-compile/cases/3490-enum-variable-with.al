// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'do' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The name after `::` is an enum value through an enum variable, `K := K::With;`, unquoted (al-runner issue 8649).
// Quoted, as "With", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53490 "MNC KS3490"
{
    value(0; Zero)
    {
    }
    value(1; "With")
    {
    }
}

codeunit 58490 "MNC KS3490 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3490";

    begin
        K := K::With;
    end;
}
