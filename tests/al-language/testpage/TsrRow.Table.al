// Migrated from AL Runner tests/runner-extras/testpage-setrecord (TsrSrc.al).
table 60845 "TSR Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Note; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
