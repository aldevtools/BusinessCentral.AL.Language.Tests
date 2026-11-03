// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-dotnet-interoperability-overview
// Scope: in-scope, but ONLY for a Target = OnPrem app (DotNet), AL compiler 18.0 or newer (see TestDotNetValueKindsContracts.al)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; self-contained codeunits 61490 to 61492 (the ids of this app are exhausted below 61490)
// Probe: the OnPrem-only variable attributes. WithEvents on a DotNet variable (a trigger Variable::Event runs when the object raises the event; System.ComponentModel.Component.Disposed is raised synchronously by Dispose()), SuppressDispose on a local DotNet variable (the object is not disposed at the end of the procedure) and RunOnClient on a global DotNet variable. Settles #629 items 11, 15 and 18 (WithEvents on a type without events: must-not-compile case 0992).
// BC versions: 27, 28, 29

dotnet
{
    assembly("mscorlib")
    {
        type("System.EventArgs"; AcEventArgs) { }
        type("System.Text.StringBuilder"; AcBuilder) { }
    }
    assembly("System")
    {
        type("System.Timers.Timer"; AcTimer) { }
    }
}

codeunit 61490 "LT AC Dn WithEvents"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Timer: DotNet AcTimer;
        Disposed: Integer;
        LastSender: Text;

    trigger Timer::Disposed(sender: Variant; e: DotNet AcEventArgs)
    begin
        Disposed += 1;
        LastSender := Format(sender);
    end;

    [Test]
    procedure AC_DnWithEvents_DisposedEvent()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Timer := Timer.Timer();
        Observer.Observe('before_dispose', Format(Disposed));
        Timer.Dispose();
        Observer.Observe('after_dispose', Format(Disposed));
        Observer.Observe('sender_is_timer', Format(LastSender = Format(Timer)));
        Timer.Dispose();
        Observer.Observe('after_second_dispose', Format(Disposed));
        Observer.Expect('before_dispose', '0');
        Observer.Expect('after_dispose', '1');
        Observer.Expect('sender_is_timer', 'Yes');
        Observer.Expect('after_second_dispose', '2');
        Observer.Verify();
    end;
}

codeunit 61491 "LT AC Dn SuppressDispose"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [WithEvents]
        Kept: DotNet AcTimer;
        Disposed: Integer;

    trigger Kept::Disposed(sender: Variant; e: DotNet AcEventArgs)
    begin
        Disposed += 1;
    end;

    [Test]
    procedure AC_DnSuppressDispose_Default()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Kept);
        Clear(Disposed);
        Observer.Observe('after_clear', Format(Disposed));
        WithDefaultDispose();
        Observer.Observe('after_call', Format(Disposed));
        WithDefaultDispose();
        Observer.Observe('after_second_call', Format(Disposed));
        Observer.Expect('after_clear', '0');
        Observer.Expect('after_call', '0');
        Observer.Expect('after_second_call', '1');
        Observer.Verify();
    end;

    [Test]
    procedure AC_DnSuppressDispose_Suppressed()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clear(Kept);
        Clear(Disposed);
        Observer.Observe('after_clear', Format(Disposed));
        WithSuppressedDispose();
        Observer.Observe('after_call', Format(Disposed));
        WithSuppressedDispose();
        Observer.Observe('after_second_call', Format(Disposed));
        Observer.Expect('after_clear', '0');
        Observer.Expect('after_call', '0');
        Observer.Expect('after_second_call', '0');
        Observer.Verify();
    end;

    local procedure WithDefaultDispose()
    var
        Scoped: DotNet AcTimer;
    begin
        Scoped := Scoped.Timer();
        Kept := Scoped;
    end;

    local procedure WithSuppressedDispose()
    var
        [SuppressDispose]
        Scoped: DotNet AcTimer;
    begin
        Scoped := Scoped.Timer();
        Kept := Scoped;
    end;
}

codeunit 61492 "LT AC Dn RunOnClient"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        [RunOnClient]
        ClientBuilder: DotNet AcBuilder;

    [Test]
    procedure AC_DnRunOnClient_GlobalVariable()
    var
        Observer: Codeunit "Probe Observer";
        Text1: Text;
    begin
        if TryBuild(Text1) then
            Observer.Observe('built', Text1)
        else
            Observer.ObserveError('built');
        Observer.Expect('built|text', 'The operation cannot complete because it uses a feature that is not supported (.NET Framework Interoperability.)');
        Observer.Expect('built|code', 'DotNetFromAlNotSupported:DotNetFromAlNotSupported');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryBuild(var Result: Text)
    begin
        ClientBuilder := ClientBuilder.StringBuilder();
        ClientBuilder.Append('client');
        Result := ClientBuilder.ToString();
    end;
}
