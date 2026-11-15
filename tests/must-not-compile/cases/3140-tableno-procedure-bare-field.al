// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// A procedure of a TableNo codeunit has no implicit Rec: a bare field name does not resolve (only OnRun has the implicit Rec; a quoted name keeps its quotes in the text).
table 53140 "MNC TN3140 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53141 "MNC TN3140 C"
{
    TableNo = "MNC TN3140 T";

    trigger OnRun()
    begin
    end;

    procedure GetNo(): Integer
    begin
        exit("Entry No.");
    end;
}
