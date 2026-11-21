// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0162 | '' is not a valid trigger
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, 'begin' expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// The name after `::` is an enum value through an enum variable, `K := K::Trigger;`, unquoted (al-runner issue 8649).
// Quoted, as "Trigger", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53485 "MNC KS3485"
{
    value(0; Zero)
    {
    }
    value(1; "Trigger")
    {
    }
}

codeunit 58485 "MNC KS3485 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3485";

    begin
        K := K::Trigger;
    end;
}
