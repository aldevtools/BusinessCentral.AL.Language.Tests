/// <summary>
/// The ISV subscriber at the bottom of the chain. Raising an error here is the AL
/// author's way of reporting that the work could not be done; it must reach the
/// caller, never be discarded.
/// </summary>
codeunit 60222 "EASE Leaf"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"EASE Relay", 'OnLevel2', '', true, true)]
    local procedure OnLevel2(Tag: Text; var Handled: Boolean)
    begin
        if Tag = 'raise' then
            Error('LEAF-RAISED-THIS');
        Handled := true;
    end;
}
