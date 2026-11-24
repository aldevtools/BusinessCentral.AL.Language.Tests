// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'key' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A table extension of Customer declares a field named Key, unquoted: `field(50100; Key; Integer)` (al-runner issue 8630).
// Quoted, as "Key", the name compiles. Case 3312 is the same name in a table.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the AL0107 text after the first sentence.
tableextension 53325 "MNC KF3325" extends Customer
{
    fields
    {
        field(50100; Key; Integer)
        {
            DataClassification = CustomerContent;
        }
    }
}
