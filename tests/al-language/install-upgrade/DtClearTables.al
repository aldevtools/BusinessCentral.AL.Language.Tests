// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: none
// Facts: destination tables of the Clear(DataTransfer) scenarios C1-C3 that run in install code (codeunit 79938 "LT AS DT Installer", source
//   table 79932 "LT AS DT Src"); read back by codeunit 79939 "LT AS DT Install Read". Writer P6924 (al-runtime-rs triage of issue 6924, row 1f).
// local object: the test must install (DataTransfer is only usable in install and upgrade code), so the rows are written at install time.
// BC versions: 27.5+

// C1: target of the first SetTables, before Clear.
table 95260 "INS DT Clear First"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// C1: target of the SetTables after Clear, then CopyRows.
table 95261 "INS DT Clear Second"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// C2 (control, no Clear): target of the first SetTables.
table 95262 "INS DT Twice First"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// C2 (control, no Clear): target of the second SetTables, then CopyRows.
table 95263 "INS DT Twice Second"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// C3: target of SetTables, then Clear and CopyRows.
table 95264 "INS DT Clear Only"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
