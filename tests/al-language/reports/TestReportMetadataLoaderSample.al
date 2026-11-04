// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/report/report-defaultlayout-method
// Scope: in-scope
// Fixtures used: none
//
// Fixture table for the metadata-loader report's data item.

table 60547 "Test Rpt MetaLoader Sample"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Description"; Text[100]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
