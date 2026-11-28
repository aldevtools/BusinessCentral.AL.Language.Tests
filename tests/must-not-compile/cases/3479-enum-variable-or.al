// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// The name after `::` is an enum value through an enum variable, `K := K::Or;`, unquoted (al-runner issue 8649).
// Quoted, as "Or", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53479 "MNC KS3479"
{
    value(0; Zero)
    {
    }
    value(1; "Or")
    {
    }
}

codeunit 58479 "MNC KS3479 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3479";

    begin
        K := K::Or;
    end;
}
