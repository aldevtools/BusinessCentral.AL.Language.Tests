codeunit 67022 "UndEvt Publisher"
{
    // Publisher fixture for TestEventUnderscoreName (67024): integration events whose names
    // contain underscores, beside one whose name is the prefix of another.

    procedure RaiseUnderscored(var Log: Text): Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeHandle_State(Handled, Log);
        exit(Handled);
    end;

    procedure RaisePlain(var Log: Text): Boolean
    var
        Handled: Boolean;
    begin
        OnBeforeHandle(Handled, Log);
        exit(Handled);
    end;

    procedure RaiseScopeLooking(var Log: Text)
    begin
        OnCheck_Scope_Value(Log);
    end;

    procedure RaiseEndsWithScope(var Log: Text)
    begin
        OnCheck_Scope(Log);
    end;

    procedure RaiseStrict(Value: Integer)
    begin
        OnValidate_Strict(Value);
    end;

    procedure RaiseRelayOuter(var Log: Text)
    begin
        OnRelay_Outer(Log);
    end;

    procedure RaiseRelayInner(var Log: Text)
    begin
        OnRelay_Inner(Log);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandle_State(var Handled: Boolean; var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnBeforeHandle(var Handled: Boolean; var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheck_Scope_Value(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnCheck_Scope(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnValidate_Strict(Value: Integer)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRelay_Outer(var Log: Text)
    begin
    end;

    [IntegrationEvent(false, false)]
    local procedure OnRelay_Inner(var Log: Text)
    begin
    end;
}
