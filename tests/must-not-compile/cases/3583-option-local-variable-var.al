// @expect AL0104 | Syntax error, ';' expected
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The member Var, unquoted, in an option variable's member list, `O: Option Zero,Var;` (al-runner issue 8657).
// Quoted, as "Var", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53583 "MNC KO3583"
{
    procedure P()
    var
        O: Option Zero,Var;

    begin
    end;
}
