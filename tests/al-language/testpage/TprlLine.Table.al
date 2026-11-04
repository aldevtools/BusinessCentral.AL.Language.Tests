// Fixture line table for TestPageActionRunPageLink.al. "Head No." is the field every
// RunPageLink in that suite filters on, and it is part of the primary key so the rowset a
// filtered target shows has one deterministic order across every BC version.
table 60463 "TPRL Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Head No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Head No.", "Line No.") { Clustered = true; }
    }
}
