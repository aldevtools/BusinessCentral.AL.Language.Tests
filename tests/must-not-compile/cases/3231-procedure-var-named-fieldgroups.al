// @expect AL0519 | 'FieldGroups' is not valid value in this context.
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A codeunit procedure declares a variable named FieldGroups, unquoted, as the first declaration of its var section (al-runner issue 8539).
// Quoted, as "FieldGroups", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53231 "MNC KV3231"
{
    procedure P()
    var
        FieldGroups: Integer;
    begin
    end;
}
