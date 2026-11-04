// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160) and its table Probe Observer Entry, from the AL Language Coverage Tests app; self-contained codeunits 99300-99301
// Probe: writer BV (2026-10-19, Windows check 3 item AL, from writer AL's probe ALEventReceiver_OnPermissionCheckEvent). Measured on Windows BC 27.5 and 29.0
// (official containers) and on the Linux tiers: the same values everywhere.
// Facts: trigger EventReceiver::OnPermissionCheckEvent of a DotNet NavPermissionEventReceiver (the shape of Microsoft's codeunit 9802 "Log Activity Permissions"),
// registered for this session: a table read in the same session (FindFirst on Probe Observer Entry) delivers no event at all to the trigger.
// BC versions: 27, 28, 29
dotnet
{
    assembly("Microsoft.Dynamics.Nav.EtwListener")
    {
        type("Microsoft.Dynamics.Nav.EtwListener.NavPermissionEventReceiver"; LtBvNavPermissionEventReceiver) { }
        type("Microsoft.Dynamics.Nav.EtwListener.PermissionCheckEventArgs"; LtBvPermissionCheckEventArgs) { }
    }
}

codeunit 99300 "LT BV Permission Logger Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        EventReceiver: DotNet LtBvNavPermissionEventReceiver;
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

    trigger EventReceiver::OnPermissionCheckEvent(sender: Variant; e: DotNet LtBvPermissionCheckEventArgs)
    begin
        Hits += 1;
        if e.ObjectId = Database::"Probe Observer Entry" then
            TableHits += 1;
    end;
}

codeunit 99301 "LT BV Permission Check Event"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure BvEventReceiver_OnPermissionCheckEvent_NoEvents()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT BV Permission Logger Host";
        Entry: Record "Probe Observer Entry";
    begin
        Host.StartLogging();
        if Entry.FindFirst() then;
        Host.StopLogging();
        Host.Report(Observer);
        Observer.Expect('any_permission_event', 'No');
        Observer.Expect('own_table_permission_event', 'No');
        Observer.Verify();
    end;
}
