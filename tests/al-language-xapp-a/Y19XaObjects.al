// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-permissions-property
// Scope: in-scope
// Fixtures used: none.
// Writer Y19, ADR-062 probes P5 and P9: a table of xapp-a that xapp-b code reads and inserts under a lowered permission set
// (tests/al-language/permissions/lt-y19-perm-probes/Y19PermCrossApp.al), and the table the two "LT Y19 Dup" sets of xapp-b and
// xapp-d grant differently.

table 61184 "LT Y19 XA Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
