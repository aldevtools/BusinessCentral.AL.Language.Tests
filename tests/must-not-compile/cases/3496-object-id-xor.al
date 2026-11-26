// @expect AL0107 | Syntax error, identifier expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, ')' expected
// The name after `::` is a table's id, `Database::Xor`, unquoted (al-runner issue 8649).
// Quoted, as "Xor", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53496 "Xor"
{
    fields
    {
        field(1; "No."; Code[20])
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

codeunit 58496 "MNC KS3496 Use"
{
    procedure P(): Integer
    begin
        exit(Database::Xor);
    end;
}
