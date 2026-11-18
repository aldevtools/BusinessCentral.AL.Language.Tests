// @expect AL0118 | The name 'Modify' does not exist in the current context.
// A procedure of a TableNo codeunit has no implicit Rec: a bare Modify() does not resolve.
table 53144 "MNC TN3144 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53145 "MNC TN3144 C"
{
    TableNo = "MNC TN3144 T";

    trigger OnRun()
    begin
    end;

    procedure DoModify()
    begin
        Modify();
    end;
}
