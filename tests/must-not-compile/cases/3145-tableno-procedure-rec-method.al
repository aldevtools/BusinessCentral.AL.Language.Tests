// @expect AL0118 | The name 'Rec' does not exist in the current context.
// A procedure of a TableNo codeunit has no implicit Rec: Rec.Find() does not resolve.
table 53145 "MNC TN3145 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53146 "MNC TN3145 C"
{
    TableNo = "MNC TN3145 T";

    trigger OnRun()
    begin
    end;

    procedure DoFind()
    begin
        Rec.Find();
    end;
}
