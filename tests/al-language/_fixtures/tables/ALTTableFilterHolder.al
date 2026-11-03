// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-evaluate-method
// Shared fixture for TableFilter Evaluate contracts. Synthetic data only.
table 67020 "ALT TableFilter Holder"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Filter Value"; TableFilter) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}
