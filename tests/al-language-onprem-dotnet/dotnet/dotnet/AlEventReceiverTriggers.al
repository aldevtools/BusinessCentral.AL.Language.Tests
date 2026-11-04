// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99120-99122
// RISKY (runtime): the event recorder and permission logger receivers (the shapes of Microsoft's codeunits 9804 and 9802); what they deliver to a test session is observed, not assumed.
//
// Triggers EventReceiver::OnEventCheckEvent, EventReceiver::OnPermissionCheckEvent and EventReceiver::OnRecordingErrorOccurred of the platform event receivers: whether they fire for events this session raises, and what a receiver without handler does.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.EventArgs"; LtAlEventArgs2) { }
    }

    assembly("Microsoft.Dynamics.Nav.EtwListener")
    {
        type("Microsoft.Dynamics.Nav.EtwListener.EventCheckEventArgs"; LtAlEventCheckEventArgs) { }
        type("Microsoft.Dynamics.Nav.EtwListener.NavEventEventReceiver"; LtAlNavEventEventReceiver) { }
        type("Microsoft.Dynamics.Nav.EtwListener.NavPermissionEventReceiver"; LtAlNavPermissionEventReceiver) { }
        type("Microsoft.Dynamics.Nav.EtwListener.PermissionCheckEventArgs"; LtAlPermissionCheckEventArgs) { }
    }
}

codeunit 99120 "LT AL Event Recorder Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        EventReceiver: DotNet LtAlNavEventEventReceiver;
        Hits: Integer;
        ForeignSession: Integer;
        ObjectTypeText: Text;
        ObjectIdText: Text;
        EventTypeText: Text;
        CallingMethodText: Text;
        SessionMatches: Text;
        ErrorCount: Integer;

    procedure StartRecording()
    begin
        Hits := 0;
        ForeignSession := 0;
        ErrorCount := 0;
        ObjectTypeText := '';
        ObjectIdText := '';
        EventTypeText := '';
        CallingMethodText := '';
        SessionMatches := '';
        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavEventEventReceiver();
        EventReceiver.RegisterForEvents();
    end;

    procedure StopRecording()
    begin
        EventReceiver.UnregisterEvents();
    end;

    procedure RaiseOwnEvent()
    begin
        OnLtAlRecorded();
    end;

    procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('own_event_hits', Format(Hits));
        Observer.Observe('own_event_object_type', ObjectTypeText);
        Observer.Observe('own_event_object_id', ObjectIdText);
        Observer.Observe('own_event_event_type', EventTypeText);
        Observer.Observe('own_event_calling_method', CallingMethodText);
        Observer.Observe('own_event_session_matches', SessionMatches);
        Observer.Observe('recording_errors', Format(ErrorCount));
    end;

    [IntegrationEvent(false, false)]
    local procedure OnLtAlRecorded()
    begin
    end;

    trigger EventReceiver::OnEventCheckEvent(sender: Variant; e: DotNet LtAlEventCheckEventArgs)
    begin
        if e.EventName <> 'OnLtAlRecorded' then
            exit;
        Hits += 1;
        ObjectTypeText := Format(e.ObjectType);
        ObjectIdText := Format(e.ObjectId);
        EventTypeText := Format(e.EventType);
        CallingMethodText := e.CallingMethodName;
        SessionMatches := Format(e.SessionId = SessionId());
    end;

    trigger EventReceiver::OnRecordingErrorOccurred(sender: Variant; e: DotNet LtAlEventArgs2)
    begin
        ErrorCount += 1;
    end;
}

codeunit 99121 "LT AL Permission Logger Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        EventReceiver: DotNet LtAlNavPermissionEventReceiver;
        Hits: Integer;
        TableHits: Integer;

    procedure StartLogging()
    begin
        Hits := 0;
        TableHits := 0;
        if IsNull(EventReceiver) then
            EventReceiver := EventReceiver.NavPermissionEventReceiver(SessionId());
        EventReceiver.RegisterForEvents();
    end;

    procedure StopLogging()
    begin
        EventReceiver.UnregisterEvents();
    end;

    procedure Report(var Observer: Codeunit "Probe Observer")
    begin
        Observer.Observe('any_permission_event', Format(Hits > 0));
        Observer.Observe('own_table_permission_event', Format(TableHits > 0));
    end;

    trigger EventReceiver::OnPermissionCheckEvent(sender: Variant; e: DotNet LtAlPermissionCheckEventArgs)
    begin
        Hits += 1;
        if e.ObjectId = Database::"Probe Observer Entry" then
            TableHits += 1;
    end;
}

codeunit 99122 "LT AL Event Receiver Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ALEventReceiver_OnEventCheckEvent()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT AL Event Recorder Host";
    begin
        Host.StartRecording();
        Host.RaiseOwnEvent();
        Host.StopRecording();
        Host.Report(Observer);
        Observer.Expect('own_event_hits', '1');
        Observer.Expect('own_event_object_type', '5');
        Observer.Expect('own_event_object_id', '99120');
        Observer.Expect('own_event_event_type', '1');
        Observer.Expect('own_event_calling_method', 'RaiseOwnEvent');
        Observer.Expect('own_event_session_matches', 'Yes');
        Observer.Expect('recording_errors', '0');
        Observer.Verify();
    end;
}
