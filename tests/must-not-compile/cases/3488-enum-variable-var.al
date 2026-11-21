// @expect AL0107 | Syntax error, identifier expected
// @expect AL0104 | Syntax error, 'end' expected
// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The name after `::` is an enum value through an enum variable, `K := K::Var;`, unquoted (al-runner issue 8649).
// Quoted, as "Var", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each; AL0107 at the name first for each of the 32 words.
enum 53488 "MNC KS3488"
{
    value(0; Zero)
    {
    }
    value(1; "Var")
    {
    }
}

codeunit 58488 "MNC KS3488 Use"
{
    procedure P()
    var
        K: Enum "MNC KS3488";

    begin
        K := K::Var;
    end;
}
