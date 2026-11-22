// @expect AL0310 | An instance is required for the non-static member 'Contains(Text)'
// A procedure of a TableNo codeunit whose table has a field named Text (Code[20]): without the implicit Rec, Text is the Text type, and Text.Contains is not a static method.
// al-runner issue 7962 left this shape open (L2).
table 53156 "MNC TN3156 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53157 "MNC TN3156 C"
{
    TableNo = "MNC TN3156 T";

    trigger OnRun()
    begin
    end;

    procedure HasA(): Boolean
    begin
        exit(Text.Contains('a'));
    end;
}
