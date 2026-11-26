// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'textattribute' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A table declares a field named TextAttribute, unquoted: `field(2; TextAttribute; Integer)` (al-runner issue 8630).
// Quoted, as "TextAttribute", the name compiles. The same diagnostics come when the field follows another field (case 3327 for Key).
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the AL0107 text after the first sentence.
table 53319 "MNC KF3319"
{
    fields
    {
        field(2; TextAttribute; Integer)
        {
        }
    }
}
