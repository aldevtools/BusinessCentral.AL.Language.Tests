// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '[' expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ']' expected
// The name after `::` is an enum value through an enum variable, `K := K::In;`, unquoted (al-runner issue 8649).
// Quoted, as "In", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53475 "MNC KS3475"
{
    value(0; Zero)
    {
    }
    value(1; "In")
    {
    }
}

codeunit 58475 "MNC KS3475 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3475";

    begin
        K := K::In;
    end;
}
