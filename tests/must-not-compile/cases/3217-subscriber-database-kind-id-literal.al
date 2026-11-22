// @expect AL0104 | Syntax error, ',' expected
// A table event subscriber names its table as Database::<id> (al-runner issue 8470). The bare id (ObjectType::Table, 50000) compiles
// and runs: tests/al-language/events/subscriber-by-id/SbiSubscriberByIdTests.al.
table 50000 "MNC SBI Row"
{
    fields
    {
        field(1; Id; Integer) { }
    }
}

codeunit 50001 "MNC SBI Sub"
{
    [EventSubscriber(ObjectType::Table, Database::50000, 'OnAfterInsertEvent', '', false, false)]
    local procedure S(var Rec: Record "MNC SBI Row"; RunTrigger: Boolean)
    begin
    end;
}
