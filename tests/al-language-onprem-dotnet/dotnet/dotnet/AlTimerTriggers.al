// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 99110-99112
// RISKY (runtime): a timer interval that elapses while a test sleeps; the count of Elapsed calls is not asserted, only whether any arrived.
//
// Trigger Timer::Elapsed and Timer::ExceptionOccurred of a DotNet LtAlTimer variable (the shape Microsoft's code coverage backup uses): when each fires during a test, with what arguments, and what happens without a handler.
// BC versions: 27, 28, 29
dotnet
{
    assembly("mscorlib")
    {
        type("System.EventArgs"; LtAlEventArgs) { }
    }

    assembly("Microsoft.Dynamics.Nav.Timer")
    {
        type("Microsoft.Dynamics.Nav.Timer"; LtAlTimer) { }
        type("Microsoft.Dynamics.Nav.ExceptionOccurredEventArgs"; LtAlExceptionOccurredEventArgs) { }
    }
}

codeunit 99110 "LT AL Timer Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        Timer: DotNet LtAlTimer;
        ElapsedCount: Integer;
        ExceptionCount: Integer;
        ExceptionMessage: Text;
        SenderKind: Text;
        ArgsKind: Text;
        FailInElapsed: Boolean;

    procedure Reset()
    begin
        ElapsedCount := 0;
        ExceptionCount := 0;
        ExceptionMessage := '';
        SenderKind := '';
        ArgsKind := '';
        FailInElapsed := false;
    end;

    procedure StartTimer(IntervalMs: Integer; Fail: Boolean)
    begin
        FailInElapsed := Fail;
        if IsNull(Timer) then
            Timer := Timer.Timer();
        Timer.Stop();
        Timer.Interval := IntervalMs;
        Timer.Start();
    end;

    procedure StopTimer()
    begin
        if not IsNull(Timer) then
            Timer.Stop();
    end;

    procedure GetElapsedCount(): Integer
    begin
        exit(ElapsedCount);
    end;

    procedure GetExceptionCount(): Integer
    begin
        exit(ExceptionCount);
    end;

    procedure GetExceptionMessage(): Text
    begin
        exit(ExceptionMessage);
    end;

    procedure GetSenderKind(): Text
    begin
        exit(SenderKind);
    end;

    procedure GetArgsKind(): Text
    begin
        exit(ArgsKind);
    end;

    trigger Timer::Elapsed(sender: Variant; e: DotNet LtAlEventArgs)
    begin
        ElapsedCount += 1;
        SenderKind := Format(sender.IsDotNet());
        ArgsKind := Format(IsNull(e));
        if FailInElapsed then
            Error('LT P timer handler failed');
    end;

    trigger Timer::ExceptionOccurred(sender: Variant; e: DotNet LtAlExceptionOccurredEventArgs)
    begin
        ExceptionCount += 1;
        ExceptionMessage := e.Exception.Message;
    end;
}

codeunit 99111 "LT AL Timer NoHandler Host"
{
    SingleInstance = true;

    var
        [WithEvents]
        Timer: DotNet LtAlTimer;

    procedure StartTimer(IntervalMs: Integer)
    begin
        if IsNull(Timer) then
            Timer := Timer.Timer();
        Timer.Stop();
        Timer.Interval := IntervalMs;
        Timer.Start();
    end;

    procedure StopTimer()
    begin
        if not IsNull(Timer) then
            Timer.Stop();
    end;
}

codeunit 99112 "LT AL Timer Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure ALTimer_Elapsed()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT AL Timer Host";
    begin
        Host.Reset();
        Host.StartTimer(100, false);
        Sleep(1500);
        Host.StopTimer();
        Observer.Observe('elapsed_fired', Format(Host.GetElapsedCount() > 0));
        Observer.Observe('exception_fired', Format(Host.GetExceptionCount() > 0));
        Observer.Observe('sender_is_dotnet', Host.GetSenderKind());
        Observer.Observe('args_null', Host.GetArgsKind());
        Observer.Expect('elapsed_fired', 'Yes');
        Observer.Expect('exception_fired', 'No');
        Observer.Expect('sender_is_dotnet', 'Yes');
        Observer.Expect('args_null', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure ALTimer_NoHandler()
    var
        Observer: Codeunit "Probe Observer";
        Host: Codeunit "LT AL Timer NoHandler Host";
    begin
        Host.StartTimer(100);
        Sleep(500);
        Host.StopTimer();
        Observer.Observe('survived', 'yes');
        Observer.Expect('survived', 'yes');
        Observer.Verify();
    end;
}
