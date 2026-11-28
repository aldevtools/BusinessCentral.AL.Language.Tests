// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// Of, unquoted after `.`, in a report extension column's source expression (al-runner issue 8650).
// Quoted, as "Of", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words, after `.` and after `::`.
table 53548 "MNC KP3548"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; "Of"; Integer)
        {
        }
        field(3; Opt; Option)
        {
            OptionMembers = Zero,"Of";
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

report 53548 "MNC KP3548 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KP3548")
        {
            column(No; "No.")
            {
            }
        }
    }
}

reportextension 53548 "MNC KP3548 Ext" extends "MNC KP3548 Report"
{
    dataset
    {
        add(Row)
        {
            column(C; Row.Of)
            {
            }
        }
    }
}
