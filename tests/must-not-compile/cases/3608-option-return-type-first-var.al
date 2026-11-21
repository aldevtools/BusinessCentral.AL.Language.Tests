// @expect AL0519 | ',' is not valid value in this context
// @expect AL0104 | Syntax error, '}' expected
// @expect AL0198 | Expected one of the application object keywords (table, tableextension, page, pageextension, pagecustomization, profile, profileextension, codeunit, report, reportextension, xmlport, query, controladdin, dotnet, enum, enumextension, interface, permissionset, permissionsetextension, entitlement)
// The member Var, unquoted, in the first member of an option return type, `procedure P(): Option Var,Zero` (al-runner issue 8657).
// Quoted, as "Var", it compiles.
// Measured with the AL compilers 16.4, 17.0 and 18.1 on the symbols of BC 27, 28 and 29: the same diagnostics on each.
codeunit 53608 "MNC KO3608"
{
    procedure P(): Option Var,Zero
    begin
    end;
}
