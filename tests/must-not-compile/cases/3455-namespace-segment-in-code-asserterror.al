// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0111 | Semicolon expected
// @expect AL0224 | Expression expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0111 | Semicolon expected
// A namespace segment that is a keyword, unquoted, in code: `Database::MNCKM3455.AssertError."MNC KM3455"` (al-runner issue 8635).
// The namespace declaration `namespace MNCKM3455.AssertError;` compiles, and so does the same name in a variable's type
// (`Row: Record MNCKM3455.AssertError."MNC KM3455"`); only the use in code gives AL0107, at the segment.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
namespace MNCKM3455.AssertError;

table 53455 "MNC KM3455"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "AssertError"; Integer)
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

codeunit 58455 "MNC KM3455 Use"
{
    procedure P(): Integer
    begin
        exit(Database::MNCKM3455.AssertError."MNC KM3455");
    end;
}
