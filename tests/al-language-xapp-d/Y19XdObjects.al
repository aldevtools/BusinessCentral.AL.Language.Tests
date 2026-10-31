// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none.
// Writer Y19, ADR-062 probe P9 (tests/al-language/permissions/lt-y19-perm-probes/Y19PermCrossApp.al): the role id "LT Y19 Dup" that
// xapp-b declares too, here with read and insert on the xapp-a table.

permissionset 61191 "LT Y19 Dup"
{
    Assignable = true;
    Permissions = tabledata "LT Y19 XA Row" = RI;
}
