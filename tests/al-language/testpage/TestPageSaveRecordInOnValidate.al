// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/page/page-saverecord-method
// Scope: in-scope
// Fixtures used: Save Record Row (60250)
//
// Backing table for the SaveRecord-in-OnValidate suite. Description is the field
// the page's controls edit; the suite's claims are about which WRITE the save path
// issues for a row that already exists (Modify, never a duplicate-key Insert).

table 60250 "Save Record Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[100]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
