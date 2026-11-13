// @expect AL0161 | 'xRec' is inaccessible due to its protection level
// In OnRun of a TableNo codeunit Rec and its fields resolve, but xRec is inaccessible.
table 53153 "MNC TN3153 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53154 "MNC TN3153 C"
{
    TableNo = "MNC TN3153 T";

    trigger OnRun()
    begin
        "Entry No." := 1;
        Rec."Entry No." := 2;
        if xRec."Entry No." = 0 then;
    end;

}
