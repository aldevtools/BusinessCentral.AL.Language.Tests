// Fixture for TestQueryDataItemLinkMultiField.al. A TWO-field primary key, so a child row can
// only be matched to the right parent by honouring both halves of the DataItemLink.
table 60498 "QDTF Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Variant Code"; Code[20]) { DataClassification = CustomerContent; }
        field(3; Descr; Text[50]) { DataClassification = CustomerContent; }
    }

    keys { key(PK; "No.", "Variant Code") { Clustered = true; } }
}
