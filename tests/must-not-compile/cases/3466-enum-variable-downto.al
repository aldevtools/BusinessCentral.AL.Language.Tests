// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an enum value through an enum variable, `K := K::DownTo;`, unquoted (al-runner issue 8649).
// Quoted, as "DownTo", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53466 "MNC KS3466"
{
    value(0; Zero)
    {
    }
    value(1; "DownTo")
    {
    }
}

codeunit 58466 "MNC KS3466 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3466";

    begin
        K := K::DownTo;
    end;
}
