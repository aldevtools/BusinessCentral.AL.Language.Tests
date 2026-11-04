// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-code-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: own tables with a Code[20] key, a Text[20] key and Code/Text fields for the P145 comparison probes (issue 145)
// BC versions: 29 (final facts are added after the measurement)

table 74900 "LT P145 Key"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Alt; Code[20]) { }
        field(3; Txt; Text[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
        key(K2; Alt) { }
    }
}

table 74915 "LT P145 Text Key"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Text[20]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
