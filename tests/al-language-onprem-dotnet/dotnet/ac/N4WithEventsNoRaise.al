// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99010 to 99013
// Probe: from al-runner issue 7832 (a [WithEvents] DotNet variable used in code that never makes the object raise an event).
// Area: a global [WithEvents] System.Timers.Timer variable of a helper codeunit:
//   - with an Elapsed trigger and no Disposed trigger (the report's shape), with no trigger at all, and with a Disposed trigger;
//   - assigned once by its constructor, assigned a second time, read with a property (Interval, Enabled), and cleared;
//   - the helper used through a local codeunit variable whose instance ends at the end of the procedure.
//   Each case observes the return values and the trigger counts the helpers keep in a SingleInstance codeunit.
// Already pinned elsewhere, not repeated: Disposed raised by Dispose() and by SuppressDispose (AcDnAttributes.al).
// Observation form: every test ends in Finish(); the values are what BC produced.
// BC versions: 27.5, 28.5, 29.0 (measured by the corpus CI)
dotnet
{
    assembly("System")
    {
        type("System.Timers.Timer"; N4WeTimer) { }
        type("System.Timers.ElapsedEventArgs"; N4WeElapsedArgs) { }
    }
    assembly("mscorlib")
    {
        type("System.EventArgs"; N4WeEventArgs) { }
    }
}

codeunit 99010 "N4 WE Counter"
{
    SingleInstance = true;

    var
        Elapsed: Integer;
        Disposed: Integer;

    procedure Reset()
    begin
        Elapsed := 0;
        Disposed := 0;
    end;

    procedure AddElapsed()
    begin
        Elapsed += 1;
    end;

    procedure AddDisposed()
    begin
        Disposed += 1;
    end;

    procedure Shown(): Text
    begin
        exit('elapsed=' + Format(Elapsed) + ';disposed=' + Format(Disposed));
    end;
}

codeunit 99011 "N4 WE Elapsed Only"
{
    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";

    procedure Touch(): Integer
    begin
        Timer := Timer.Timer(1000);
        exit(1);
    end;

    procedure Props(): Text
    begin
        exit(Format(Timer.Interval) + '|' + Format(Timer.Enabled));
    end;

    procedure Reassign()
    begin
        Timer := Timer.Timer(2000);
    end;

    procedure ClearIt()
    begin
        Clear(Timer);
    end;

    procedure IsNullNow(): Boolean
    begin
        exit(IsNull(Timer));
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet N4WeElapsedArgs)
    begin
        Counter.AddElapsed();
    end;
}

codeunit 99012 "N4 WE No Trigger"
{
    var
        [WithEvents]
        Timer: DotNet N4WeTimer;

    procedure Touch(): Integer
    begin
        Timer := Timer.Timer(1000);
        exit(1);
    end;

    procedure Props(): Text
    begin
        exit(Format(Timer.Interval) + '|' + Format(Timer.Enabled));
    end;

    procedure Reassign()
    begin
        Timer := Timer.Timer(2000);
    end;

    procedure ClearIt()
    begin
        Clear(Timer);
    end;

    procedure IsNullNow(): Boolean
    begin
        exit(IsNull(Timer));
    end;
}

codeunit 99013 "N4 WE With Disposed"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Timer: DotNet N4WeTimer;
        Counter: Codeunit "N4 WE Counter";
        Observer: Codeunit "Probe Observer";

    trigger Timer::Disposed(sender: Variant; e: DotNet N4WeEventArgs)
    begin
        Counter.AddDisposed();
    end;

    local procedure UseElapsedOnly(): Integer
    var
        H: Codeunit "N4 WE Elapsed Only";
    begin
        exit(H.Touch());
    end;

    local procedure UseNoTrigger(): Integer
    var
        H: Codeunit "N4 WE No Trigger";
    begin
        exit(H.Touch());
    end;

    [Test]
    procedure N4_WithEvents_ElapsedOnly_Helper()
    var
        H: Codeunit "N4 WE Elapsed Only";
    begin
        Counter.Reset();
        Observer.Observe('null_before', Format(H.IsNullNow()));
        Observer.Observe('touch', Format(H.Touch()));
        Observer.Observe('null_after', Format(H.IsNullNow()));
        Observer.Observe('props', H.Props());
        H.Reassign();
        Observer.Observe('props_reassigned', H.Props());
        H.ClearIt();
        Observer.Observe('null_cleared', Format(H.IsNullNow()));
        Observer.Observe('counts', Counter.Shown());
        Observer.Observe('local_instance', Format(UseElapsedOnly()));
        Observer.Observe('counts_after_local', Counter.Shown());
        Observer.Finish();
    end;

    [Test]
    procedure N4_WithEvents_NoTrigger_Helper()
    var
        H: Codeunit "N4 WE No Trigger";
    begin
        Counter.Reset();
        Observer.Observe('null_before', Format(H.IsNullNow()));
        Observer.Observe('touch', Format(H.Touch()));
        Observer.Observe('null_after', Format(H.IsNullNow()));
        Observer.Observe('props', H.Props());
        H.Reassign();
        Observer.Observe('props_reassigned', H.Props());
        H.ClearIt();
        Observer.Observe('null_cleared', Format(H.IsNullNow()));
        Observer.Observe('local_instance', Format(UseNoTrigger()));
        Observer.Observe('counts', Counter.Shown());
        Observer.Finish();
    end;

    [Test]
    procedure N4_WithEvents_DisposedTrigger_AssignReassignClear()
    begin
        Counter.Reset();
        Clear(Timer);
        Observer.Observe('after_first_clear', Counter.Shown());
        Timer := Timer.Timer(1000);
        Observer.Observe('after_assign', Counter.Shown());
        Observer.Observe('props', Format(Timer.Interval) + '|' + Format(Timer.Enabled));
        Timer := Timer.Timer(2000);
        Observer.Observe('after_reassign', Counter.Shown());
        Clear(Timer);
        Observer.Observe('after_clear', Counter.Shown());
        Observer.Observe('null_after_clear', Format(IsNull(Timer)));
        Observer.Finish();
    end;
}
