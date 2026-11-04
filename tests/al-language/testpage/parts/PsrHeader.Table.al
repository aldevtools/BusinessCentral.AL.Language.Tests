// Fixture for "PSR Page Saved Row Tests" (60412): a header whose OnInsert counts its own runs,
// so a second insert attempt on a row that already exists is visible in the saved row.
table 60412 "PSR Header"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Descr; Text[30]) { }
        field(3; "Insert Runs"; Integer) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }

    trigger OnInsert()
    begin
        "Insert Runs" += 1;
    end;
}
