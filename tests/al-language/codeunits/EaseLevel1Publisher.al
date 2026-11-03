/// <summary>
/// Level 1 publisher — stands in for BC's platform trigger codeunit
/// (Codeunit 2000000005 ReportingTriggers), which raises the event the System
/// App subscribes to.
/// </summary>
codeunit 60220 "EASE Level1 Publisher"
{
    [IntegrationEvent(false, false)]
    local procedure OnLevel1(Tag: Text; var Handled: Boolean)
    begin
    end;

    procedure Publish(Tag: Text) Handled: Boolean
    begin
        OnLevel1(Tag, Handled);
    end;
}
