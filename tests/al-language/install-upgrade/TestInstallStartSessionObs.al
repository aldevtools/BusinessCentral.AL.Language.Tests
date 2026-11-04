// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-installation-codeunit
// Scope: in-scope
// Fixtures used: none
//
// What "Install StartSession Probe" (60445) observed when it called StartSession from inside
// OnInstallAppPerCompany. Per-company, like "Install Env Observation": the trigger fires once
// per existing company, so a shared key would collide in a sandbox with more than one company.

table 60446 "Install StartSession Obs"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Returned"; Boolean) { }
        field(3; "Session Id After"; Integer) { }
        field(4; "Reached After Plain Call"; Boolean) { }
        field(5; "Plain Session Id After"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
