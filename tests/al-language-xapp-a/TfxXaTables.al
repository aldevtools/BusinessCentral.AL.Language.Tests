// Objects of cross-app fixture A for the TransferFields probe between fields of different apps (al-runner issue 6982).
// Tests: tests/al-language/record/transferfields-cross-app/TransferFieldsFieldApps.al.
//   95830 source and 95831 target: both owned by this app. Fixtures B, C and D extend them with fields of the same numbers and other
//   (or the same) types; 95831 also has a field of its own (95835) whose number a field of fixture B on the source uses.
//   95832 source and 95833 target: fixture B extends both with field 95830 of two types (two fields of one app).
// local object: the owner app of each field is under test.

table 95830 "REC TFX Source"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95831 "REC TFX Target"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(95835; "Owner Code"; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95832 "REC TFX Source 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 95833 "REC TFX Target 2"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
