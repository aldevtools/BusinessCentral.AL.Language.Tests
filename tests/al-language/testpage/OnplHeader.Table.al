// Fixture for codeunit 60868 "ONPL Tests". A document header whose "No." is assigned by its
// own OnInsert when blank -- the shape a No. Series gives Purchase Header, without the series.
table 60868 "ONPL Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if "No." = '' then
            "No." := 'AUTO1';
    end;
}
