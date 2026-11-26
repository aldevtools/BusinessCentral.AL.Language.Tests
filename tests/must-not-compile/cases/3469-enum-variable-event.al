// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// The name after `::` is an enum value through an enum variable, `K := K::Event;`, unquoted (al-runner issue 8649).
// Quoted, as "Event", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53469 "MNC KS3469"
{
    value(0; Zero)
    {
    }
    value(1; "Event")
    {
    }
}

codeunit 58469 "MNC KS3469 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3469";

    begin
        K := K::Event;
    end;
}
