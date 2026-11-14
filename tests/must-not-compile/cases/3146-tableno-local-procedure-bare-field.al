// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// A local procedure of a TableNo codeunit has no implicit Rec: a bare field name does not resolve.
table 53146 "MNC TN3146 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53147 "MNC TN3146 C"
{
    TableNo = "MNC TN3146 T";

    trigger OnRun()
    begin
    end;

    local procedure GetNo(): Integer
    begin
        exit("Entry No.");
    end;
}
