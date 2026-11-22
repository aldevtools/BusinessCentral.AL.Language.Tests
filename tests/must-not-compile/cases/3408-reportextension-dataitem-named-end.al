// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// @from 29
// A report extension data item is named End, unquoted: `dataitem(End; "MNC KS3408")` (al-runner issue 8634).
// Quoted, as "End", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compiler of BC 29 (AL 18.1): AL0107 at the name first, for each of the 24 words; the recovery after it differs between the majors (case 3393 holds the other).
table 53408 "MNC KS3408"
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

report 53408 "MNC KS3408 Report"
{
    ProcessingOnly = true;

    dataset
    {
        dataitem(Row; "MNC KS3408")
        {
            column(No; "No.")
            {
            }
        }
    }
    requestpage
    {
        layout
        {
            area(Content)
            {
            }
        }
    }
}

reportextension 53408 "MNC KS3408 Ext" extends "MNC KS3408 Report"
{
    dataset
    {
        addlast(Row)
        {
            dataitem(End; "MNC KS3408")
            {
            }
        }
    }
}
