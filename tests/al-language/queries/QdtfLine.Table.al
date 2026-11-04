// Fixture for TestQueryDataItemLinkMultiField.al — the child of "QDTF Header".
table 60499 "QDTF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { DataClassification = CustomerContent; }
        field(2; "Variant Code"; Code[20]) { DataClassification = CustomerContent; }
        field(3; "Line No."; Integer) { DataClassification = CustomerContent; }
        field(4; Tag; Text[50]) { DataClassification = CustomerContent; }
    }

    keys { key(PK; "Header No.", "Variant Code", "Line No.") { Clustered = true; } }
}
