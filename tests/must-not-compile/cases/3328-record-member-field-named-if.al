// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'then' expected
// A table declares a field named If, unquoted, which compiles; a codeunit assigns it through a record variable, unquoted: `Row.If := 1;` (al-runner issue 8630).
// The quoted member `Row."If" := 1;` compiles: tests/al-language/table-objects/field-names/KeywordFieldNames.al.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the texts after the first sentence.
table 53328 "MNC KF3328"
{
    fields
    {
        field(1; Id; Integer)
        {
        }
        field(2; If; Integer)
        {
        }
    }
}

codeunit 53328 "MNC KF3328 Use"
{
    procedure P()
    var
        Row: Record "MNC KF3328";
    begin
        Row.If := 1;
    end;
}
