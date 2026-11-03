// Objects of writer QY's Rename probes (tests in BwCrossAppTests.al).
//   87620 "LT QY Own Blob": a table of this app with a Blob field of its own.
//   tableextension 87620: this app's Blob field on cross-app fixture A's table "LT QY XA Rename Blobs", which has a Blob field of its own
//   ("XA Blob") and one from cross-app fixture B ("QY XB Blob").

table 87620 "LT QY Own Blob"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
        field(3; Data; Blob) { }
    }

    keys { key(PK; "No.") { Clustered = true; } }
}

tableextension 87620 "LT QY Rename Blobs Ext M" extends "LT QY XA Rename Blobs"
{
    fields
    {
        field(87620; "QY M Blob"; Blob)
        {
            DataClassification = SystemMetadata;
        }
    }
}
