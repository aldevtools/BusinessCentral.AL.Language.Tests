// Fixture for "Test Isolated Event Sub Error" (67103). Two publishers with one shape:
// OnIsolatedWork is declared Isolated = true, OnSharedWork is not.
codeunit 67101 "ISO Event Publisher"
{
    procedure RaiseIsolated()
    begin
        OnIsolatedWork();
    end;

    procedure RaiseShared()
    begin
        OnSharedWork();
    end;

    [IntegrationEvent(false, false, true)]
    local procedure OnIsolatedWork()
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnSharedWork()
    begin
    end;
}
