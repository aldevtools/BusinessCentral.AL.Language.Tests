// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// A procedure of a TableNo codeunit with a parameter named Rec: Rec is the parameter (Rec."Entry No." compiles), a bare field name still does not resolve.
table 53152 "MNC TN3152 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53153 "MNC TN3152 C"
{
    TableNo = "MNC TN3152 T";

    trigger OnRun()
    begin
    end;

    procedure SetNo(var Rec: Record "MNC TN3152 T")
    begin
        Rec."Entry No." := 1;
        "Entry No." := 2;
    end;
}
