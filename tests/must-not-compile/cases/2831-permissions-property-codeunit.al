// @expect AL0104 | Syntax error, 'tabledata' expected
// The Permissions property of an object takes table data only; a codeunit permission, even with a name and no wildcard, is a syntax error.
codeunit 50000 "MNC Y93 Perm Codeunit"
{
    Permissions = codeunit "MNC Y93 Perm Codeunit" = X;
}
