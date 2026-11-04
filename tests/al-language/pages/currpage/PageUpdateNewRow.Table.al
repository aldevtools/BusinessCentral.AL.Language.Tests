// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The row "ALT Page Update New Row Card" creates. A Guid key the page assigns in OnInsertRecord,
// as Base Application's "User Card" does for a User, so an unsaved new row is recognisable by
// its null key and a saved one by a real one.

table 60998 "ALT Page Update New Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Guid) { DataClassification = CustomerContent; }
        field(2; Name; Code[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
