// Shared shape tables (corpus restructure, standing rule 2 "Fixture first").
// One plain table per frequent exact field shape: field types, lengths and names in field-number order, primary key on field 1,
// no triggers, no other keys, no properties besides DataClassification. A test whose table has exactly one of these shapes uses
// the shape table instead of its own table. Codeunit isolation (test runner 130450) gives each test codeunit an empty table.
// Frozen once merged: never change a field, a key or a property; add a new table in 50000..50999 instead.
// ALTFixtureCleanup.Initialize clears every shape table.

table 50000 "ALT Shape 00"
{
    // shape: Integer Id
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50001 "ALT Shape 01"
{
    // shape: Integer Id; Text[30] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Name"; Text[30]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50002 "ALT Shape 02"
{
    // shape: Code[20] No.; Text[50] Descr
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Descr"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50003 "ALT Shape 03"
{
    // shape: Integer Id; Blob Data
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Data"; Blob) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50004 "ALT Shape 04"
{
    // shape: Code[20] No.; Text[50] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50005 "ALT Shape 05"
{
    // shape: Code[20] No.
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50006 "ALT Shape 06"
{
    // shape: Integer Id; Text[20] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Name"; Text[20]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50007 "ALT Shape 07"
{
    // shape: Code[10] Code
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 50008 "ALT Shape 08"
{
    // shape: Code[20] Code; Text[50] Descr
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; "Descr"; Text[50]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 50009 "ALT Shape 09"
{
    // shape: Code[20] Code
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 50010 "ALT Shape 10"
{
    // shape: Integer Id; Text[20] Info
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Info"; Text[20]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50011 "ALT Shape 11"
{
    // shape: Integer Id; Text[30] Txt
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Txt"; Text[30]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50012 "ALT Shape 12"
{
    // shape: Integer Id; Boolean Flag
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Flag"; Boolean) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50013 "ALT Shape 13"
{
    // shape: Integer Id; Text[100] Txt
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Txt"; Text[100]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50014 "ALT Shape 14"
{
    // shape: Code[10] Code; Text[20] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Name"; Text[20]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 50015 "ALT Shape 15"
{
    // shape: Integer Id; Code[10] Grp
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Grp"; Code[10]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50016 "ALT Shape 16"
{
    // shape: Integer Id; Integer Amount
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Amount"; Integer) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50017 "ALT Shape 17"
{
    // shape: Integer Id; Text[250] Txt
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Txt"; Text[250]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50018 "ALT Shape 18"
{
    // shape: Integer Id; Text[50] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50019 "ALT Shape 19"
{
    // shape: Integer Entry No.; Code[20] Header No.; Decimal Amount; Date Posting Date
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; "Amount"; Decimal) { }
        field(4; "Posting Date"; Date) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 50020 "ALT Shape 20"
{
    // shape: Code[10] Code; Text[30] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; "Name"; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 50021 "ALT Shape 21"
{
    // shape: Integer Entry No.; Text[50] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 50022 "ALT Shape 22"
{
    // shape: Code[20] No.; Decimal Amount
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Amount"; Decimal) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50023 "ALT Shape 23"
{
    // shape: Integer Id; Integer ParentId
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "ParentId"; Integer) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50024 "ALT Shape 24"
{
    // shape: Integer Id; Text[30] Note
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Note"; Text[30]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50025 "ALT Shape 25"
{
    // shape: Integer Id; Text[50] Note
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Id"; Integer) { }
        field(2; "Note"; Text[50]) { }
    }

    keys
    {
        key(PK; "Id") { Clustered = true; }
    }
}

table 50026 "ALT Shape 26"
{
    // shape: Code[20] No.; Integer Qty
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Qty"; Integer) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50027 "ALT Shape 27"
{
    // shape: Code[20] No.; Text[30] Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Name"; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 50028 "ALT Shape 28"
{
    // shape: Integer Entry No.
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 50029 "ALT Shape 29"
{
    // shape: Integer Entry No.; Text[50] Trigger Name
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; "Trigger Name"; Text[50]) { }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}
