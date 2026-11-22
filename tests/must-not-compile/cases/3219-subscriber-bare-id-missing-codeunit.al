// @expect AL0185 | Codeunit '50099' is missing
// An event subscriber names its publisher by a bare codeunit id that no codeunit has (al-runner issue 8470). The bare id of a codeunit
// that exists compiles: tests/al-language/events/subscriber-by-id/SbiSubscriberByIdTests.al.
codeunit 50001 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Codeunit, 50099, 'OnX', '', false, false)]
    local procedure S()
    begin
    end;
}
