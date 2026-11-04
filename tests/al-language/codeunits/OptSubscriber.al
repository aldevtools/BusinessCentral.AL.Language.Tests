/// <summary>
/// Subscribes to "Opt Publisher CEO".OnDoChoice with an Option-typed parameter.
/// Raises an error encoding the received option ordinal so the test can assert,
/// via asserterror, the exact value that was marshalled through the dispatcher.
/// </summary>
codeunit 60214 "Opt Subscriber CEO"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"Opt Publisher CEO", OnDoChoice, '', false, false)]
    local procedure OnDoChoice_Sub(Choice: Option First,Second,Third)
    begin
        Error('RECEIVED:%1', Choice);
    end;
}
