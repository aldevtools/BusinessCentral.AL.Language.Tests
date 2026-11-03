// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-properties
// Scope: in-scope
// Fixtures used: 00-fixtures.al (own tables, Log and Helper codeunits)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

permissionset 72183 "LT P121 PermSet A"
{
    Assignable = true;
    Caption = 'LT P121 A';
    Permissions = tabledata "LT P121 Row" = R;
}

permissionset 72184 "LT P121 PermSet B"
{
    Assignable = true;
    Caption = 'LT P121 B';
    Permissions = tabledata "LT P121 Line" = R;
}

permissionsetextension 72185 "LT P121 PermSet Ext" extends "LT P121 PermSet A"
{
    IncludedPermissionSets = "LT P121 PermSet B";
}
