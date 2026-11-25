// @expect AL0107 | Syntax error, identifier expected
// @expect AL0111 | Semicolon expected
// The member is a query column read, `V := Qry.This;`, unquoted (al-runner issue 8635).
// Quoted, as "This", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53453 "MNC KM3453"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "This"; Integer)
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

query 53453 "MNC KM3453 Query"
{
    elements
    {
        dataitem(Row; "MNC KM3453")
        {
            column("This"; "This")
            {
            }
        }
    }
}

codeunit 58453 "MNC KM3453 Use"
{
    procedure P()
    var
        Qry: Query "MNC KM3453 Query";
        V: Integer;

    begin
        Qry.Open();
        if Qry.Read() then
            V := Qry.This;
    end;
}
