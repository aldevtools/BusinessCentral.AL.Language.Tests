// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0105 | Syntax error, identifier expected; 'tableextension' is a keyword
// @expect AL0104 | Syntax error, ')' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0114 | Syntax error, integer literal expected
// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'extends' expected
// @expect AL0104 | Syntax error, '{' expected
// @expect AL0124 | The property 'Integer' cannot be used in this context
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// A table declares a field named TableExtension, unquoted: `field(2; TableExtension; Integer)` (al-runner issue 8630).
// Quoted, as "TableExtension", the name compiles. The same diagnostics come when the field follows another field (case 3327 for Key).
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL 16 ends the AL0107 text after the first sentence.
table 53318 "MNC KF3318"
{
    fields
    {
        field(2; TableExtension; Integer)
        {
        }
    }
}
