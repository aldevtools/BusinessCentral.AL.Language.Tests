// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// @from 29
// A report data item is named Begin, unquoted: `dataitem(Begin; "MNC KS3407")` (al-runner issue 8634).
// Quoted, as "Begin", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compiler of BC 29 (AL 18.1): AL0107 at the name first, for each of the 24 words; the recovery after it differs between the majors (case 3390 holds the other).
table 53407 "MNC KS3407"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Amount; Integer)
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

report 53407 "MNC KS3407 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Begin; "MNC KS3407")
        {
        }
    }
}
