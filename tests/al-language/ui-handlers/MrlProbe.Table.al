// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/triggers-auto/page/devenv-triggers-auto-page-onaftergetrecord
// Scope: in-scope
//
// What page 60402's OnAfterGetRecord saw. One row per distinct "MRL Row" the page loaded, so
// the count answers WHICH rows were loaded, not merely how many times the trigger fired.
table 60401 "MRL Probe"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Marker"; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Seen"; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "Marker") { Clustered = true; }
    }
}
