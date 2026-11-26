// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// ForEach, unquoted after `.`, in a report column's source expression, `column(C; Row.ForEach)` (al-runner issue 8650).
// Quoted, as "ForEach", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53547 "MNC KP3547"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "ForEach"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"ForEach";
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

report 53547 "MNC KP3547 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KP3547")
        {
            column(C; Row.ForEach)
            {
            }
        }
    }
}
