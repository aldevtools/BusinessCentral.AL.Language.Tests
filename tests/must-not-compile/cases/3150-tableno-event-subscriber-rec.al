// @expect AL0118 | The name 'Rec' does not exist in the current context.
// An event subscriber of a TableNo codeunit has no implicit Rec: Rec does not exist there.
table 53150 "MNC TN3150 T"
{
    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Version; Text[30]) { }
        field(3; Text; Code[20]) { }
    }
    keys { key(PK; "Entry No.") { Clustered = true; } }
}

codeunit 53151 "MNC TN3150 C"
{
    TableNo = "MNC TN3150 T";

    trigger OnRun()
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC TN3150 C", 'OnSomething', '', false, false)]
    local procedure HandleSomething()
    begin
        Rec."Entry No." := 3;
    end;

    [IntegrationEvent(false, false)]
    procedure OnSomething()
    begin
    end;
}
