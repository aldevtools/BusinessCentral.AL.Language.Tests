// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// The name after `::` is an enum value through an enum variable, `K := K::And;`, unquoted (al-runner issue 8649).
// Quoted, as "And", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53460 "MNC KS3460"
{
    value(0; Zero)
    {
    }
    value(1; "And")
    {
    }
}

codeunit 58460 "MNC KS3460 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3460";

    begin
        K := K::And;
    end;
}
