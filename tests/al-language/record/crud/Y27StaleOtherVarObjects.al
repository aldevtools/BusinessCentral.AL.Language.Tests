// Objects of the Y27 stale own-Insert tests (Y27StaleOtherVarTests.al): a row table whose triggers count themselves into the row,
// and the codeunit that writes the row through its own record variables (al-runner issue 6522).

table 92250 "LT Y27 Stale Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50])
        {
            trigger OnValidate()
            begin
                "Validate Count" += 1;
            end;
        }
        field(3; "Remaining Quantity"; Decimal) { }
        field(4; "Validate Count"; Integer) { }
        field(5; "Modify Count"; Integer) { }
        field(6; "xRec Remaining Quantity"; Decimal) { }
        field(7; "xRec Description"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    trigger OnModify()
    begin
        "Modify Count" += 1;
        "xRec Remaining Quantity" := xRec."Remaining Quantity";
        "xRec Description" := xRec.Description;
    end;
}

// Writes row "No." through a record variable of its own, as the reporter's posting codeunit does.
codeunit 92251 "LT Y27 Stale Row Poster"
{
    procedure PostAndCommit(No: Code[20]; Quantity: Decimal)
    begin
        Post(No, Quantity);
        Commit();
    end;

    procedure Post(No: Code[20]; Quantity: Decimal)
    var
        StaleRow: Record "LT Y27 Stale Row";
    begin
        StaleRow.Get(No);
        StaleRow."Remaining Quantity" -= Quantity;
        StaleRow.Modify();
    end;

    procedure PostDescription(No: Code[20]; NewDescription: Text[50])
    var
        StaleRow: Record "LT Y27 Stale Row";
    begin
        StaleRow.Get(No);
        StaleRow.Description := NewDescription;
        StaleRow.Modify();
    end;

    procedure DeleteRow(No: Code[20])
    var
        StaleRow: Record "LT Y27 Stale Row";
    begin
        StaleRow.Get(No);
        StaleRow.Delete();
    end;

    procedure InsertAnotherRow(No: Code[20])
    var
        StaleRow: Record "LT Y27 Stale Row";
    begin
        StaleRow."No." := No;
        StaleRow.Description := 'Another row';
        StaleRow.Insert();
    end;
}
