// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The var section of a report extension's request page declares a variable named Key, unquoted (al-runner issue 8539).
// Quoted, as "Key", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
reportextension 53276 "MNC KV3276" extends "Customer - List"
{
    requestpage
    {
        var
            Key: Integer;
    }
}
