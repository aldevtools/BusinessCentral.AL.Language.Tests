// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-creating-tables
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), table 73036 (shared by the other P84 files)
// Probe: written against BC 29 ...; observed values are added by the lead after measuring (tag P84, GitHub issue #84)
// Facts: own row table used by the P84 reports and pages
// BC versions: 29

table 73036 "LT P84 Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { Caption = 'Id'; }
        field(2; Name; Text[30]) { Caption = 'Name'; }
    }
    keys { key(PK; Id) { Clustered = true; } }
}
