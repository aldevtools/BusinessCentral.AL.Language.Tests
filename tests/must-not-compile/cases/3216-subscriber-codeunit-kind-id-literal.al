// @expect AL0104 | Syntax error, ',' expected
// An event subscriber names its publisher codeunit as Codeunit::<id> (al-runner issue 8470). The bare id (ObjectType::Codeunit, 50000)
// compiles and runs: tests/al-language/events/subscriber-by-id/SbiSubscriberByIdTests.al.
codeunit 50000 "MNC SBI Pub"
{
    [IntegrationEvent(false, false)]
    procedure OnX()
    begin
    end;
}

codeunit 50001 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::50000, 'OnX', '', false, false)]
    local procedure S()
    begin
    end;
}
