// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A codeunit procedure declares a variable named Actions, unquoted, as the first declaration of its var section (al-runner issue 8539).
// Quoted, as "Actions", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53222 "MNC KV3222"
{
    procedure P()
    var
        Actions: Integer;
    begin
    end;
}
