// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The member Begin, unquoted, in the first member of a table's global option variable, `Option Begin,Zero` (al-runner issue 8657, PR 8663 review).
// Quoted, as "Begin", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
table 53611 "MNC KO3611"
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

    var
        O: Option Begin,Zero;
}
