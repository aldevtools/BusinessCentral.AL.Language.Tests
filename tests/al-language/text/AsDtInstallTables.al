// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope
// Fixtures used: none
// Facts: tables for DataTransfer run from install code (codeunit 79938 "LT AS DT Installer"); read back by codeunit 79939 (corpus issue 644, item 15).
// BC versions: 27.5+

table 79932 "LT AS DT Src"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Qty; Decimal) { }
        field(5; Kind; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Destination of CopyRows (scenario S1).
table 79933 "LT AS DT Rows"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; Name; Text[30]) { }
        field(4; Note; Text[30]) { }
        field(5; Qty; Decimal) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Destination of CopyFields with AddJoin (scenario S2), seeded before the copy.
table 79934 "LT AS DT Fields"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Integer) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Source and destination of a same-table CopyFields (scenario S3).
table 79935 "LT AS DT Self"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Amount; Integer) { }
        field(3; "Copy"; Integer) { }
        field(4; Note; Text[30]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// Destination of CopyFields with AddDestinationFilter (scenario S4, BC 28+), seeded before the copy.
table 79936 "LT AS DT DestF"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[30]) { }
        field(3; Kind; Integer) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

// What each scenario returned inside the install trigger: 'ok' or 'error text|error code'.
table 79937 "LT AS DT Obs"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Outcome; Text[250]) { }
    }
    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}
