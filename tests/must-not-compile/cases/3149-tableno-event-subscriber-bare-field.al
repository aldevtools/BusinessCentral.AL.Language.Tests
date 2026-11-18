// @expect AL0118 | The name '"Entry No."' does not exist in the current context.
// An event subscriber of a TableNo codeunit has no implicit Rec: a bare field name does not resolve.
table 53149 "MNC TN3149 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53150 "MNC TN3149 C"
{
    TableNo = "MNC TN3149 T";

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC TN3149 C", 'OnSomething', '', false, false)]
    local procedure HandleSomething()
    begin
        "Entry No." := 3;
    end;

    [IntegrationEvent(false, false)]
    procedure OnSomething()
    begin
    end;
}
