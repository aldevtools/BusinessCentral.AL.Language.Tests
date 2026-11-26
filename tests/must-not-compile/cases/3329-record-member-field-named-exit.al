// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// A table declares a field named Exit, unquoted, which compiles; a codeunit assigns it through a record variable, unquoted: `Row.Exit := 1;` (al-runner issue 8630).
// The quoted member `Row."Exit" := 1;` compiles: tests/al-language/table-objects/field-names/KeywordFieldNames.al.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the texts after the first sentence.
table 53329 "MNC KF3329"
{
    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; Exit; Integer)
        {
        }
    }
}

codeunit 53329 "MNC KF3329 Use"
{
    procedure P()
    var
        Row: Record "MNC KF3329";
    begin
        Row.Exit := 1;
    end;
}
