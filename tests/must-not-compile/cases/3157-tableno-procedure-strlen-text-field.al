// @expect AL0133 | Argument 1: cannot convert from 'Text' to 'Text'
// A procedure of a TableNo codeunit whose table has a field named Text: without the implicit Rec, StrLen(Text) gets the type name Text, not a value.
// al-runner issue 7962 left this shape open (L2).
table 53157 "MNC TN3157 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53158 "MNC TN3157 C"
{
    TableNo = "MNC TN3157 T";

    trigger OnRun()
    begin
    end;

    procedure Len(): Integer
    begin
        exit(StrLen(Text));
    end;
}
