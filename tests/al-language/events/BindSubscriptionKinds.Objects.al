// Objects of the BSK probes (tests BSK_* in codeunit 69811 "PA Event Contracts", TestProbeEventContracts.al).
// local object: the EventSubscriberInstance and SingleInstance properties of these subscribers are what the tests check.
// Ids 95390 - 95393. The publisher is only raised by the BSK tests, so the automatic subscriber runs nowhere else.

codeunit 95390 "LT BSK Pub"
{
    procedure Ping(): Text
    var
        Hits: Text;
    begin
        OnPing(Hits);
        exit(Hits);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(var Hits: Text)
    begin
    end;
}

codeunit 95391 "LT BSK Manual SI"
{
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BSK Pub", 'OnPing', '', false, false)]
    local procedure OnPing(var Hits: Text)
    begin
        Hits += 'S';
    end;
}

codeunit 95392 "LT BSK Static Explicit"
{
    EventSubscriberInstance = StaticAutomatic;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BSK Pub", 'OnPing', '', false, false)]
    local procedure OnPing(var Hits: Text)
    begin
        Hits += 'A';
    end;
}

codeunit 95393 "LT BSK Manual"
{
    EventSubscriberInstance = Manual;

    var
        Tag: Text;

    procedure SetTag(NewTag: Text)
    begin
        Tag := NewTag;
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT BSK Pub", 'OnPing', '', false, false)]
    local procedure OnPing(var Hits: Text)
    begin
        Hits += 'M' + Tag;
    end;
}
