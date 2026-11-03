// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-update-method
// Scope: in-scope
//
// The row "ALT Page Update Gone Card" shows. A Code key the test chooses, so the trace can name
// the row each trigger ran for.

table 67300 "ALT Page Update Gone Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Code; Code[20]) { DataClassification = CustomerContent; }
        field(2; Name; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}
