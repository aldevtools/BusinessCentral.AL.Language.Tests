// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an enum value through an enum variable, `K := K::Then;`, unquoted (al-runner issue 8649).
// Quoted, as "Then", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53482 "MNC KS3482"
{
    value(0; Zero)
    {
    }
    value(1; "Then")
    {
    }
}

codeunit 58482 "MNC KS3482 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3482";

    begin
        K := K::Then;
    end;
}
