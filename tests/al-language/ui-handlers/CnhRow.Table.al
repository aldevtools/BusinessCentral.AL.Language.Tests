/// <summary>Source table for the two "CNH Confirm" cards. Temporary on both pages, so
/// OpenNew() never writes to the database.</summary>
table 60362 "CNH Row"
{
    Caption = 'CNH Row';
    DataClassification = CustomerContent;
    TableType = Normal;

    fields
    {
        field(1; "No."; Code[20])
        {
            Caption = 'No.';
        }
        field(2; Descr; Text[100])
        {
            Caption = 'Descr';
        }
    }

    keys
    {
        key(PK; "No.")
        {
            Clustered = true;
        }
    }
}
