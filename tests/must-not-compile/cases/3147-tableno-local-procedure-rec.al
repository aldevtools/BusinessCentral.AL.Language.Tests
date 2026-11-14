// @expect AL0118 | The name 'Rec' does not exist in the current context.
// A local procedure of a TableNo codeunit has no implicit Rec.
table 53147 "MNC TN3147 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53148 "MNC TN3147 C"
{
    TableNo = "MNC TN3147 T";

    trigger OnRun()
    begin
    end;

    local procedure GetNo(): Integer
    begin
        exit(Rec."Entry No.");
    end;
}
