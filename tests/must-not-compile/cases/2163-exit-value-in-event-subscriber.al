// @expect AL0139 | Since 'HandleSomething' doesn't have a return value, EXIT cannot be called with a value
// exit with a value in an event subscriber.
codeunit 50001 "MNC SH Publisher"
{
    [IntegrationEvent(false, false)]
    procedure OnSomething()
    begin
    end;
}

codeunit 50002 "MNC SH Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC SH Publisher", 'OnSomething', '', false, false)]
    local procedure HandleSomething()
    begin
        exit(1);
    end;
}
