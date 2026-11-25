// @expect AL0224 | Expression expected
// A table declares a field named If, unquoted, which compiles; a codeunit names it, unquoted, as the field argument of SetRange: `Row.SetRange(If, 1);` (al-runner issue 8630).
// Unquoted Local, Keys, Fields and Layout work as members: tests/al-language/table-objects/field-names/KeywordFieldNames.al.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the texts after the first sentence.
table 53330 "MNC KF3330"
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

codeunit 53330 "MNC KF3330 Use"
{
    procedure P()
    var
        Row: Record "MNC KF3330";
    begin
        Row.SetRange(If, 1);
    end;
}
