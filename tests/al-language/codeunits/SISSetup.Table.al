// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: none
//
// Backing table for the SingleInstance-codeunit-lifetime fixtures.

table 60607 "SIS Setup"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Primary Key"; Code[10]) { }
        field(2; "Currency Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Primary Key") { Clustered = true; }
    }
}
