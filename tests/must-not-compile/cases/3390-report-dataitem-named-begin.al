// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// @until 28
// A report data item is named Begin, unquoted: `dataitem(Begin; "MNC KS3390")` (al-runner issue 8634).
// Quoted, as "Begin", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compiler of BC 27 and 28 (AL 16.4 and 17.0): AL0107 at the name first, for each of the 24 words; the recovery after it differs between the majors (case 3407 holds the other).
table 53390 "MNC KS3390"
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

report 53390 "MNC KS3390 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Begin; "MNC KS3390")
        {
        }
    }
}
