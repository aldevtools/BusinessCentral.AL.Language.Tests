// @expect AL0132 | 'Version' does not contain a definition for 'ToUpper'
// A procedure of a TableNo codeunit whose table has a field Version: without the implicit Rec, Version is the Version type, which has no ToUpper.
table 53154 "MNC TN3154 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53155 "MNC TN3154 C"
{
    TableNo = "MNC TN3154 T";

    trigger OnRun()
    begin
    end;

    local procedure GetVersion(): Text
    begin
        exit(Version.ToUpper());
    end;
}
