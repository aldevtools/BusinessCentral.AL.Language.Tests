// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// A field name of a table used in a codeunit without TableNo: the bare quoted name does not resolve, and the text shows it with its quotes.
table 53163 "MNC TN3163 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53164 "MNC TN3163 C"
{
    procedure GetNo(): Integer
    begin
        exit("Entry No.");
    end;
}
