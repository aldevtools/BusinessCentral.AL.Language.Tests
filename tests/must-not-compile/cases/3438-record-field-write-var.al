// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The member is a record field written through a record variable, `Row.Var := 1;`, unquoted (al-runner issue 8635).
// Quoted, as "Var", the member compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
table 53438 "MNC KM3438"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Var"; Integer)
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

codeunit 58438 "MNC KM3438 Use"
{
    procedure P()
    var
        Row: Record "MNC KM3438";

    begin
        Row.Var := 1;
    end;
}
