// @expect AL0118 | The name 'xRec' does not exist in the current context.
// A procedure of a TableNo codeunit has no xRec.
// A global variable named xRec in the same codeunit compiles in the procedure (AL 16, 17, 18 and 30).
table 53142 "MNC TN3142 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53143 "MNC TN3142 C"
{
    TableNo = "MNC TN3142 T";

    trigger OnRun()
    begin
    end;

    procedure GetNo(): Integer
    begin
        exit(xRec."Entry No.");
    end;
}
