// Fixture for "Opc Close Part Flush Tests" (60438): what "Opc Close Card" (60423) saw in its
// part at the moment OnQueryClosePage ran. Written by the trigger, read by the test AFTER the
// close has finished -- an assertion inside the trigger could not tell "the trigger never ran"
// from "the trigger ran and saw nothing".
//
// "Close Action" records what the platform passed the trigger on the TestPage.Close() route.
// It is recorded rather than asserted: this suite is about WHEN the part is flushed, and the
// identity of the close action on that route is a separate question no arm here measures.
table 60422 "Opc Result"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; "Line Count"; Integer) { }
        field(3; "Value Seen"; Text[30]) { }
        field(4; "Close Action"; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
