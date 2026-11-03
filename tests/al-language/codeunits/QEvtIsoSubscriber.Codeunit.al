// Fixture for "Test Event Quoted Name" (67046): an automatic subscriber to the isolated
// event "On Isolated Quoted" that notes the call on "QEvt Iso Witness" (67047) and then
// always raises. Only RaiseIsolated raises that event.
codeunit 67045 "QEvt Iso Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'On Isolated Quoted', '', false, false)]
    local procedure FailOnIsolatedQuoted()
    var
        Witness: Codeunit "QEvt Iso Witness";
    begin
        Witness.Note();
        Error('QEVT-ISOLATED-SUBSCRIBER-FAILED');
    end;
}
