// Fixture for TestPageFailedInsert.al: a plain Code key and one Text field. No triggers, so the
// only way a page-driven insert of this row can fail is the platform's own duplicate-key refusal.
table 60039 "IPF Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; Description; Text[50]) { DataClassification = CustomerContent; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
