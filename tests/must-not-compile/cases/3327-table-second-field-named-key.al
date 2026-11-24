// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'key' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A table declares a field named Key, unquoted, as its second field, after a field "No." that holds the primary key (al-runner issue 8630).
// The diagnostics are those of the field as the only field of a table (case 3312).
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the AL0107 text after the first sentence.
table 53327 "MNC KF3327"
{
    fields
    {
        field(1; "No."; Code[20])
        {
        }
        field(2; Key; Integer)
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
