// @expect AL0104 | Syntax error, '}' expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'extends' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A codeunit procedure declares a variable named ProfileExtension, unquoted, as the first declaration of its var section (al-runner issue 8539).
// Quoted, as "ProfileExtension", the name compiles.
// Measured with the AL compilers of BC 27.4, 28.5 and 29.1 (AL 16.4, 17.0, 18.1): same codes on each; AL 16 ends the AL0107 text after the first sentence.
codeunit 53234 "MNC KV3234"
{
    procedure P()
    var
        ProfileExtension: Integer;
    begin
    end;
}
