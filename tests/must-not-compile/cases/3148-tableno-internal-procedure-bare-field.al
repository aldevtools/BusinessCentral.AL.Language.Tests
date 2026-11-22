// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// An internal procedure of a TableNo codeunit has no implicit Rec: a bare field name does not resolve.
table 53148 "MNC TN3148 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53149 "MNC TN3148 C"
{
    TableNo = "MNC TN3148 T";

    trigger OnRun()
    begin
    end;

    internal procedure GetNo(): Integer
    begin
        exit("Entry No.");
    end;
}
