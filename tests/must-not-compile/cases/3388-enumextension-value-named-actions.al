// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// An enum extension value is named Actions, unquoted: `value(50000; Actions)` (al-runner issue 8634).
// Quoted, as "Actions", the name compiles, and so does an ordinary name in its place.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 24 words.
enum 53388 "MNC KS3388"
{
    Extensible = true;

    value(0; Zero)
    {
    }
}

enumextension 53388 "MNC KS3388 Ext" extends "MNC KS3388"
{
    value(50000; Actions)
    {
    }
}
