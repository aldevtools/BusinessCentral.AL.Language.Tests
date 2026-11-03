// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpagefieldtestpage-drilldown-method
// Scope: in-scope
// Fixtures used: Test Page DrillDown Row (60972)
//
// Backing table for the TestPage field-drilldown suite. Reused both for the seeded data rows
// and for the marker rows an OnDrillDown trigger writes — the same convention
// TestPageActionInvoke uses for its OnAction markers.

table 60972 "Test Page DrillDown Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
