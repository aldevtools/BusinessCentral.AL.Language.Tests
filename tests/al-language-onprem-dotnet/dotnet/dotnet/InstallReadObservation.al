// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-extension-install-code
// local object: observations must survive installation and later test sessions.
table 99464 "INST Read Observation"
{
    DataPerCompany = false;
    fields
    {
        field(1; Company; Text[30]) { }
        field(2; Probe; Code[20]) { }
        field(3; Result; Text[250]) { }
        field(4; Failure; Text[250]) { }
    }
    keys { key(PK; Company, Probe) { Clustered = true; } }
}
