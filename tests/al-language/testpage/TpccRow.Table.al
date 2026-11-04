// Fixture for TestPageCaptionClass.al — see that file's header.
table 60981 "TPCC Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Amount; Decimal) { Caption = 'Amount Field Caption'; }
        field(3; Quantity; Decimal) { Caption = 'Quantity Field Caption'; }
        field(4; Description; Text[50]) { Caption = 'Description Field Caption'; }
        field(5; Remark; Text[50]) { Caption = 'Remark Field Caption'; }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
