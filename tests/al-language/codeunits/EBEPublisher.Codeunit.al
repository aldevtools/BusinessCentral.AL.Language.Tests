// Fixture for "Test External Business Event" (68611). Each procedure counts a step,
// raises an [ExternalBusinessEvent], and counts again, so a test can tell whether the
// statement after the raise ran.
using System.Integration;

codeunit 68610 "EBE Publisher"
{
    var
        StepCount: Integer;

    procedure Steps(): Integer
    begin
        exit(StepCount);
    end;

    procedure RaiseBetweenSteps()
    begin
        StepCount += 1;
        OnEbeCreated(CreateGuid());
        StepCount += 1;
    end;

    procedure RaiseWithPayload()
    begin
        StepCount += 1;
        OnEbePayload('payload text', 12.5, 7, true, Today());
        StepCount += 1;
    end;

    procedure RaiseThenFail()
    begin
        StepCount += 1;
        OnEbeCreated(CreateGuid());
        StepCount += 1;
        Error('EBE unrelated failure after the raise');
    end;

    [ExternalBusinessEvent('ebe_created', 'EBE created', 'An example record was created.', EventCategory::"EBE Example", '1.0')]
    local procedure OnEbeCreated(EntityId: Guid)
    begin
    end;

    [ExternalBusinessEvent('ebe_payload', 'EBE payload', 'Carries a Text, Decimal, Integer, Boolean and Date payload.', EventCategory::"EBE Example", '2.0')]
    local procedure OnEbePayload(Description: Text[250]; Amount: Decimal; Quantity: Integer; Flag: Boolean; PostingDate: Date)
    begin
    end;
}
