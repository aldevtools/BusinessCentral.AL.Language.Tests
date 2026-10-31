// Scope: in-scope
// Fixtures used: none (see the fixture file of this folder)

table 90566 "LT WB P4 Row"
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
}

// Stands in for Item: rows of another table that the new transaction Modifies and Inserts
table 90567 "LT WB P4 Other"
{
    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Qty; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

// Stands in for No. Series Line: read under ReadIsolation UpdLock and Modified, as codeunit "No. Series - Stateless Impl." does
table 90568 "LT WB P4 Series"
{
    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Last No. Used"; Code[20]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
