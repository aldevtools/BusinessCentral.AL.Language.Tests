// Scope: in-scope
// Tables of the Y70 probes (runtime assumptions that had no corpus pin). Object ids 93740-93747.

table 93740 "LT Y70 Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; DF; DateFormula) { }
        field(3; Stamp; DateTime) { }
        field(4; Day; Date) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 93741 "LT Y70 Text Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Text[10]) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

table 93742 "LT Y70 Code Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Name; Code[10]) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Name) { Clustered = true; }
    }
}

table 93743 "LT Y70 Int Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93744 "LT Y70 Big Key"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; BigInteger) { }
        field(2; Note; Text[50]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93745 "LT Y70 Option Init"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Day; Option)
        {
            OptionMembers = Sunday,Monday,Tuesday,Wednesday,Thursday,Friday,Saturday;
            InitValue = 1;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 93746 "LT Y70 Pending Move"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Moving; Text[20])
        {
            ObsoleteState = PendingMove;
            ObsoleteReason = 'Moved to another app.';
            ObsoleteTag = '1.0';
            MovedTo = '5c6d7e8f-1a2b-4c3d-9e0f-a1b2c3d4e5f8';
        }
        field(3; Staying; Text[20]) { }
        field(4; Pending; Text[20])
        {
            ObsoleteState = Pending;
            ObsoleteReason = 'Going away.';
            ObsoleteTag = '1.0';
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
