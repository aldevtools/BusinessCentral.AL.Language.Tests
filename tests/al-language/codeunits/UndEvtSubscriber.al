codeunit 67023 "UndEvt Subscriber"
{
    // Manual subscriber fixture for TestEventUnderscoreName (67024): each handler appends its
    // own tag to Log, so a test can see exactly which events reached which handler.
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnBeforeHandle_State', '', false, false)]
    local procedure HandleState(var Handled: Boolean; var Log: Text)
    begin
        Handled := true;
        Log += 'State;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnBeforeHandle', '', false, false)]
    local procedure HandlePlain(var Handled: Boolean; var Log: Text)
    begin
        Handled := true;
        Log += 'Plain;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnCheck_Scope_Value', '', false, false)]
    local procedure HandleScopeValue(var Log: Text)
    begin
        Log += 'ScopeValue;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnCheck_Scope', '', false, false)]
    local procedure HandleScope(var Log: Text)
    begin
        Log += 'Scope;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnValidate_Strict', '', false, false)]
    local procedure HandleStrict(Value: Integer)
    begin
        Error('Strict subscriber rejected %1', Value);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnRelay_Outer', '', false, false)]
    local procedure HandleRelayOuter(var Log: Text)
    var
        Publisher: Codeunit "UndEvt Publisher";
    begin
        Log += 'Outer;';
        Publisher.RaiseRelayInner(Log);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"UndEvt Publisher", 'OnRelay_Inner', '', false, false)]
    local procedure HandleRelayInner(var Log: Text)
    begin
        Log += 'Inner;';
    end;
}
