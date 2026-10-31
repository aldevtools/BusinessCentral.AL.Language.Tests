// @expect AL0104 | Syntax error, 'tabledata' expected
// The Permissions property of an object takes only tabledata entries: a report Execute grant (report X = X) does not compile; page, table
// and system entries give the same diagnostic. al-runtime-rs ADR-062 probe P20, writer Y24.
report 59362 "MNC Y24 Exec Report 2361"
{
    ProcessingOnly = true;
}

codeunit 59363 "MNC Y24 Exec Granter 2361"
{
    Permissions = report "MNC Y24 Exec Report 2361" = X;
}
