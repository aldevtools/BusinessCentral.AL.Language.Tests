// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The name after `::` is an enum value through an enum variable, `K := K::Begin;`, unquoted (al-runner issue 8649).
// Quoted, as "Begin", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53462 "MNC KS3462"
{
    value(0; Zero)
    {
    }
    value(1; "Begin")
    {
    }
}

codeunit 58462 "MNC KS3462 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3462";

    begin
        K := K::Begin;
    end;
}
