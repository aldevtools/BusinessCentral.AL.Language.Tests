// Manual subscriber fixture for "Test Event Quoted Name" (67046): each handler appends its
// own tag to Log, so a test sees exactly which subscribers ran.
codeunit 67044 "QEvt Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'On Before Quoted', '', false, false)]
    local procedure HandleSpaced(var Handled: Boolean; var Log: Text)
    begin
        Handled := true;
        Log += 'Spaced;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'On-Check.Value (Qty) & Amt', '', false, false)]
    local procedure HandlePunctuated(var Log: Text)
    begin
        Log += 'Punctuated;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'On Bestätigt Evt', '', false, false)]
    local procedure HandleUmlaut(var Log: Text)
    begin
        Log += 'Umlaut;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'OnQuotedPlain', '', false, false)]
    local procedure HandleQuotedPlain(var Log: Text)
    begin
        Log += 'QuotedPlain;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"QEvt Publisher", 'On Strict Check', '', false, false)]
    local procedure HandleStrict(Value: Integer)
    begin
        Error('Quoted strict subscriber rejected %1', Value);
    end;

    [EventSubscriber(ObjectType::Table, Database::"QEvt Publisher Table", 'On Table Quoted', '', false, false)]
    local procedure HandleTableSpaced(var Log: Text)
    begin
        Log += 'Table;';
    end;
}
