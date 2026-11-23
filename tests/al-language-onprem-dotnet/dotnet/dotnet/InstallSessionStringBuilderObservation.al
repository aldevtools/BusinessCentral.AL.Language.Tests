// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: OnPrem DotNet, installation and test-session object lifetime
// BC versions: 27.5, 28.5, 29.0
// local object: dedicated installation observation and SingleInstance owner keep this probe isolated.
// Related: AL Runner issue 8954. Native results pending.

table 99451 "LT Install Builder Obs"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Local Text"; Text[100]) { }
        field(3; "Session Text"; Text[100]) { }
        field(4; "Probe Error"; Text[250]) { }
    }

    keys { key(PK; "Code") { Clustered = true; } }
}
