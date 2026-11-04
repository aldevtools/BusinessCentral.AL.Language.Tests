// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: none
//
// What the app's own Subtype=Install codeunit (Install Seeder, 60618) could SEE of the
// environment while OnInstallAppPerCompany ran. An install trigger runs inside a company that
// already exists and under a session that already has its permissions, so the two questions
// below have answers before any of this app's code exists; the tests in
// TestInstallEnvVisible_Tests read them back.
//
// Per-company, like "Install Seed" next to it: OnInstallAppPerCompany fires once per existing
// company, so a shared key would collide in a sandbox with more than one company.

table 60588 "Install Env Observation"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Company Row Existed"; Boolean) { }
        field(3; "Company Row Name"; Text[30]) { }
        field(4; "Other Company Row Existed"; Boolean) { }
        field(5; "Session User Was Super"; Boolean) { }
        field(6; "Observed Company Name"; Text[30]) { }
        field(7; "Exec Ctx Was Install"; Boolean) { }
        field(8; "Exec Ctx Text"; Text[30]) { }
        field(9; "Module Exec Ctx Was Install"; Boolean) { }
        field(10; "Module Exec Ctx Text"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
