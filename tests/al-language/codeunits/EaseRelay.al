/// <summary>
/// Level 2 publisher — stands in for the System App's ReportManagement, which is
/// itself a SUBSCRIBER (to level 1) whose body RAISES ANOTHER EVENT. That second
/// raise is what forces BC to emit this subscriber as an async state machine, and
/// the state machine is what captures any exception raised underneath it.
/// </summary>
codeunit 60221 "EASE Relay"
{
    [IntegrationEvent(false, false)]
    local procedure OnLevel2(Tag: Text; var Handled: Boolean)
    begin
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EASE Level1 Publisher", 'OnLevel1', '', true, true)]
    local procedure OnLevel1(Tag: Text; var Handled: Boolean)
    begin
        OnLevel2(Tag, Handled);
    end;
}
