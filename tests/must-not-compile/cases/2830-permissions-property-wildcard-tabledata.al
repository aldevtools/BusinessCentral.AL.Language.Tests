// @expect AL0107 | Syntax error, identifier expected. Provide a valid name (letters, digits, and underscores only).
// @expect AL0104 | Syntax error, '=' expected
// @expect AL0104 | Syntax error, ',' expected
// The Permissions property of an object names table data of an object; a wildcard (as a permission set may use) is a syntax error.
codeunit 50000 "MNC Y93 Perm Wild Tabledata"
{
    Permissions = tabledata * = i;
}
