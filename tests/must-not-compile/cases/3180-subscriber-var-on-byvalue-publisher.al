// An event subscriber declares its Record parameter var, but the publisher's parameter is by value: AL0288. The other direction
// (a var publisher parameter, a by-value subscriber parameter) compiles: tests/al-language/record/filters/ByValueSubscriberView.al
// (al-runner pull request 8314).
// @expect AL0288 | Parameter 'R' is only allowed to be 'var' if the publisher parameter is 'var'.

table 50000 "MNC BVS Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
    }

    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 50001 "MNC BVS Publisher"
{
    [IntegrationEvent(false, false)]
    local procedure OnThing(R: Record "MNC BVS Row")
    begin
    end;
}

codeunit 50002 "MNC BVS Var Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"MNC BVS Publisher", 'OnThing', '', false, false)]
    local procedure HandleThing(var R: Record "MNC BVS Row")
    begin
    end;
}
