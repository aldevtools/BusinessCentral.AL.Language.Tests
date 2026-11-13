// @expect AL0118 | The name 'Find' does not exist in the current context.
// A procedure of a TableNo codeunit has no implicit Rec: a bare Record method (Find) does not resolve.
table 53143 "MNC TN3143 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53144 "MNC TN3143 C"
{
    TableNo = "MNC TN3143 T";

    trigger OnRun()
    begin
    end;

    procedure DoFind()
    begin
        Find();
    end;
}
