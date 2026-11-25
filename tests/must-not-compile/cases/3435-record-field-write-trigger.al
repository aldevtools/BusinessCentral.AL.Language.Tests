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
// The member is a record field written through a record variable, `Row.Trigger := 1;`, unquoted (al-runner issue 8635).
// Quoted, as "Trigger", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53435 "MNC KM3435"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Trigger"; Integer)
        {
        }
    }
    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}

codeunit 58435 "MNC KM3435 Use"
{
    procedure P()
    var
        Row: Record "MNC KM3435";

    begin
        Row.Trigger := 1;
    end;
}
