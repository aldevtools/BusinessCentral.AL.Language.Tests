// @expect AL0104 | Syntax error, 'tabledata' expected
// The Permissions property of an object takes only tabledata entries: an Execute grant on a codeunit (codeunit X = x or = X) does not
// compile. Report, page, table and system entries fail the same way (2361). Execute grants exist only in permission sets
// (tests/al-language/permissions/lt-y19-perm-probes/Y24PermObjects.al, set "LT Y24 TD Granter"). al-runtime-rs ADR-062 probe P20, writer Y24.
codeunit 59360 "MNC Y24 Exec Target 2360"
{
}

codeunit 59361 "MNC Y24 Exec Granter 2360"
{
    Permissions = codeunit "MNC Y24 Exec Target 2360" = x;
}
