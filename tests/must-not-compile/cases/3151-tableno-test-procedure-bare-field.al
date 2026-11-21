// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// A [Test] procedure of a test codeunit with TableNo has no implicit Rec: a bare field name does not resolve (OnRun of the same codeunit compiles it).
table 53151 "MNC TN3151 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53152 "MNC TN3151 C"
{
    TableNo = "MNC TN3151 T";
    Subtype = Test;

    trigger OnRun()
    begin
        "Entry No." := 1;
    end;

    [Test]
    procedure TestNo()
    begin
        "Entry No." := 1;
    end;
}
