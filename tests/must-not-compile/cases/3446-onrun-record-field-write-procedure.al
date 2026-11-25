// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, '(' expected
// @expect AL0104 | Syntax error, ')' expected
// The member is a record field written in OnRun, unquoted (al-runner issue 8635).
// Quoted, as "Procedure", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53446 "MNC KM3446"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Procedure"; Integer)
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

codeunit 58446 "MNC KM3446 Use"
{
    trigger OnRun()
    var
        Row: Record "MNC KM3446";

    begin
        Row.Procedure := 1;
    end;
}
