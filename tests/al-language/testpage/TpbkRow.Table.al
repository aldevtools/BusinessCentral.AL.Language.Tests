// Fixture for TestPageBlankKeyInsert.al: a table whose OnInsert assigns the primary key when it
// is blank (AUTO1, AUTO2, ... — the No. Series pattern, without Base Application).
table 60572 "TPBK Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[100]) { }
        field(3; Note; Text[100]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Record "TPBK Log";
        Existing: Record "TPBK Row";
    begin
        if "No." = '' then
            "No." := 'AUTO' + Format(Existing.Count() + 1);
        Log.Note(Description);
    end;
}
