namespace ALLanguage.IsolationProbe;

// Probe P4 (ADR-066 of al-runtime-rs): an event subscriber that the runner's OnBeforeTestRun
// and OnAfterTestRun reach. It inserts "S" + the key the trigger inserted, so the reader can
// tell whether a subscriber's writes share the fate of the trigger's own writes.
codeunit 61334 "LT RP Subscriber"
{
    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT RP Log", 'OnTriggerWrite', '', false, false)]
    local procedure InsertSubscriberRow(RowKey: Code[50])
    var
        Row: Record "LT RP Row";
    begin
        Row."Key" := CopyStr('S' + RowKey, 1, MaxStrLen(Row."Key"));
        if Row.Insert() then;
    end;
}
