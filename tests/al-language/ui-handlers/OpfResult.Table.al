// Fixture for "Opf Ok Part Flush Tests" (60663): what "Opf Outer Card" (60659) saw in its part
// at the moment OnQueryClosePage ran. Written by the trigger, read by the test AFTER the modal
// round trip has finished -- an assertion inside the trigger could not tell "the trigger never
// ran" from "the trigger ran and saw nothing".
table 60638 "Opf Result"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line Count"; Integer) { }
        field(3; "Value Seen"; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
