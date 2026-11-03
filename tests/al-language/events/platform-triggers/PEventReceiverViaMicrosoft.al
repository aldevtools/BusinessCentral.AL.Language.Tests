// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope
// Fixtures used: Probe Observer (69160); self-contained codeunits 67289-67290
// RISKY (runtime): codeunits 9804 "Log Recorded Events" and 9802 "Log Activity Permissions" register platform event receivers (DotNet, with the triggers EventReceiver::OnEventCheckEvent and EventReceiver::OnPermissionCheckEvent);
// whether the receivers deliver anything to a test session is observed, not assumed. OnRecordingErrorOccurred shows its message only when the recording breaks, which a test cannot cause.
//
// What a test sees from the event recorder (an integration event this session raises while recording) and from the permission logger (a table this session reads while logging).
// BC versions: 27, 28, 29
codeunit 67289 "LT P Recorded Publisher"
{
    procedure Raise()
    begin
        OnLtPRecordedEvent();
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLtPRecordedEvent()
    begin
    end;
}

codeunit 67290 "LT P Event Receiver Via MS"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRecord(var Buffer: Record "Recorded Event Buffer" temporary)
    var
        Recorder: Codeunit "Log Recorded Events";
        Publisher: Codeunit "LT P Recorded Publisher";
    begin
        Recorder.Start();
        Publisher.Raise();
        Recorder.Stop(Buffer);
    end;

    [TryFunction]
    local procedure TryLogPermissions(var Buffer: Record "Tenant Permission" temporary)
    var
        Logger: Codeunit "Log Activity Permissions";
        Entry: Record "Probe Observer Entry";
    begin
        Logger.Start();
        if Entry.FindFirst() then;
        Logger.Stop(Buffer);
    end;

    [Test]
    procedure PEventReceiver_RecordedEvents()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "Recorded Event Buffer" temporary;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRecord(Buffer);
        Observer.Observe('record_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('record_error');
        Buffer.SetRange("Event Name", 'OnLtPRecordedEvent');
        Observer.Observe('own_event_rows', Format(Buffer.Count()));
        if Buffer.FindFirst() then begin
            Observer.Observe('own_event_object_type', Format(Buffer."Object Type"));
            Observer.Observe('own_event_object_id', Format(Buffer."Object ID"));
            Observer.Observe('own_event_event_type', Format(Buffer."Event Type"));
            Observer.Observe('own_event_calling_method', Buffer."Calling Method");
            Observer.Observe('own_event_hit_count', Format(Buffer."Hit Count"));
            Observer.Observe('own_event_session_matches', Format(Buffer."Session ID" = SessionId()));
        end;
        Observer.Expect('record_ok', 'Yes');
        Observer.Expect('own_event_rows', '1');
        Observer.Expect('own_event_object_type', 'Codeunit');
        Observer.Expect('own_event_object_id', '67289');
        Observer.Expect('own_event_event_type', 'Custom Event');
        Observer.Expect('own_event_calling_method', 'Raise');
        Observer.Expect('own_event_hit_count', '1');
        Observer.Expect('own_event_session_matches', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PEventReceiver_PermissionLog()
    var
        Observer: Codeunit "Probe Observer";
        Buffer: Record "Tenant Permission" temporary;
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryLogPermissions(Buffer);
        Observer.Observe('log_ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('log_error');
        Buffer.SetRange("Object ID", Database::"Probe Observer Entry");
        Observer.Observe('own_table_rows', Format(Buffer.Count()));
        if Buffer.FindFirst() then begin
            Observer.Observe('own_table_object_type', Format(Buffer."Object Type"));
            Observer.Observe('own_table_read', Format(Buffer."Read Permission"));
        end;
        Observer.Expect('log_ok', 'Yes');
        Observer.Expect('own_table_rows', '0');
        Observer.Verify();
    end;
}
