// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// The member is a record field written through a record variable, `Row.True := 1;`, unquoted (al-runner issue 8635).
// Quoted, as "True", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53436 "MNC KM3436"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "True"; Integer)
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

codeunit 58436 "MNC KM3436 Use"
{
    procedure P()
    var
        Row: Record "MNC KM3436";

    begin
        Row.True := 1;
    end;
}
