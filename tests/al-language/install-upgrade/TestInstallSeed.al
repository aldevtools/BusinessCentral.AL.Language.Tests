// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-triggers
// Scope: in-scope
// Fixtures used: none
//
// Target table for per-COMPANY install-trigger seeding. The Subtype=Install
// codeunit (Install Seeder, 60618) inserts rows here from OnInstallAppPerCompany,
// which fires once per existing company — a per-company table (the AL default)
// keeps each company's 'COMPANY1'/'COMPANY2' rows isolated instead of colliding
// on a shared key when the sandbox has more than one company.

table 60617 "Install Seed"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Value"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
