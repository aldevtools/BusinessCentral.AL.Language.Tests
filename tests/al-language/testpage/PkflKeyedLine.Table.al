// Fixture line table for TestPageSubpagePartFieldLink.al, identical in shape to "PKFL Line"
// (60642) EXCEPT that "Header No." IS part of the primary key. Paired with that table so the
// two directions of the New() stamping rule are pinned separately: a runner that stamped
// nothing, or stamped everything, would satisfy only one of them.
table 60643 "PKFL Keyed Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "Line No."; Integer) { }
        field(2; "Header No."; Code[20]) { }
        field(3; Name; Text[50]) { }
    }

    keys
    {
        key(PK; "Header No.", "Line No.") { Clustered = true; }
    }
}
