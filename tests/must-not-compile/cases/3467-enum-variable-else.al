// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0110 | Orphaned ELSE statement
// The name after `::` is an enum value through an enum variable, `K := K::Else;`, unquoted (al-runner issue 8649).
// Quoted, as "Else", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53467 "MNC KS3467"
{
    value(0; Zero)
    {
    }
    value(1; "Else")
    {
    }
}

codeunit 58467 "MNC KS3467 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3467";

    begin
        K := K::Else;
    end;
}
