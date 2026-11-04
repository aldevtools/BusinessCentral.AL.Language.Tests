// Fixture for TestPageBlankKeyInsert.al: counts OnInsert runs of "TPBK Row" and records the
// Description the row carried when OnInsert ran.
table 60573 "TPBK Log"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Key"; Code[10]) { }
        field(2; Inserts; Integer) { }
        field(3; "Description At Insert"; Text[100]) { }
    }

    keys
    {
        key(PK; "Key") { Clustered = true; }
    }

    procedure Note(DescriptionAtInsert: Text[100])
    begin
        if not Get('INS') then begin
            Init();
            "Key" := 'INS';
            Insert();
        end;
        Inserts += 1;
        "Description At Insert" := DescriptionAtInsert;
        Modify();
    end;

    procedure InsertCount(): Integer
    begin
        if not Get('INS') then
            exit(0);
        exit(Inserts);
    end;
}
