// @expect AL0118 | The name 'Rec' does not exist in the current context.
// A procedure of a TableNo codeunit has no implicit Rec: Rec does not exist there (only in OnRun).
// A global variable named Rec in the same codeunit compiles in the procedure (AL 16, 17, 18 and 30).
table 53141 "MNC TN3141 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53142 "MNC TN3141 C"
{
    TableNo = "MNC TN3141 T";

    trigger OnRun()
    begin
    end;

    procedure GetNo(): Integer
    begin
        exit(Rec."Entry No.");
    end;
}
