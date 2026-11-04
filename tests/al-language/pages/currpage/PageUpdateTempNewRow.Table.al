// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The row "ALT Page Update Temp New Card" shows, always through a temporary source. A Guid key
// the page assigns in OnInsertRecord, so an unsaved new row has a null key.

table 60963 "ALT Page Update Temp New Row"
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
