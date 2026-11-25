// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an enum value through an enum variable, `K := K::This;`, unquoted (al-runner issue 8649).
// Quoted, as "This", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53483 "MNC KS3483"
{
    value(0; Zero)
    {
    }
    value(1; "This")
    {
    }
}

codeunit 58483 "MNC KS3483 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3483";

    begin
        K := K::This;
    end;
}
