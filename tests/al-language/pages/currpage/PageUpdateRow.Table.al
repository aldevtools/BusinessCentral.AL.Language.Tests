// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The one row the CurrPage.Update suite drives. Two fields only: a key and an integer the
// FactBox derives its displayed value from, so nothing about the table can absorb or explain
// a difference the suite measures.

table 60491 "ALT Page Update Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; Amount; Integer) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
