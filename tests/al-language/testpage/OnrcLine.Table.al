// Fixture line table for TestPagePartOnNewRecordCount.al.
//
// "Header No." is the first field of the primary key, the same shape as "TPDL Line" (60997) and
// every Base Application document line: it is the set BC's
// RecordImplementation.InitRecordFromFilters copies a single-valued filter onto, so the page's
// link value reaches a row the page starts.
//
// Descr has NO OnValidate. That is deliberate and it is what separates this fixture from
// "TPDL Line", which uses its OnValidate to prove the link value arrives before the trigger
// runs. Here the question is only how many times OnNewRecord fires, and a validate that can
// raise would turn an over-firing count into an error message instead of a number.
table 60355 "ONRC Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Header No."; Code[20]) { }
        field(2; "Line No."; Integer) { }
        field(3; Descr; Text[50]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}
