table 81591 "LT WB P5 Row"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Note; Text[30]) { }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnDelete()
    var
        Trace: Codeunit "LT WB P5 Trace";
    begin
        Trace.Add('OnDelete', "No.", Note);
    end;
}

table 81592 "LT WB P5 Log"
{
    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
