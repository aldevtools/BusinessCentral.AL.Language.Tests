// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-sleep-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90641
// Probe: written against al-runner issue 6301 (Sleep with a Duration); every value asserted below is what the BC service tier produced.
// Facts: Sleep takes a Duration (it converts to the Integer parameter, in milliseconds): zero, a positive Duration, a Duration changed in the
//        callee through a var parameter, and the time it takes. A negative Duration raises an uncatchable CLR exception (ArgumentOutOfRangeException), not pinned.
// BC versions: 27, 28, 29

codeunit 90641 "LT WC Sleep Duration"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Wait(var Delay: Duration)
    begin
        Sleep(Delay);
        Delay := 10;
    end;

    [Test]
    procedure WC_Sleep_Duration_ZeroAndBackoff()
    var
        Observer: Codeunit "Probe Observer";
        Delay: Duration;
    begin
        Wait(Delay);
        Observer.Observe('after zero', Format(Delay, 0, 9));
        Wait(Delay);
        Observer.Observe('after ten', Format(Delay, 0, 9));
        Delay := Round(Delay * 2, 1, '>');
        Sleep(Delay);
        Observer.Observe('after backoff', Format(Delay, 0, 9));
        Observer.Expect('after zero', 'P0DT0H0M0.01S');
        Observer.Expect('after ten', 'P0DT0H0M0.01S');
        Observer.Expect('after backoff', 'P0DT0H0M0.02S');
        Observer.Verify();
    end;

    [Test]
    procedure WC_Sleep_Duration_Elapsed()
    var
        Observer: Codeunit "Probe Observer";
        Delay: Duration;
        Started: DateTime;
        Elapsed: Duration;
    begin
        Delay := 100;
        Started := CurrentDateTime();
        Sleep(Delay);
        Elapsed := CurrentDateTime() - Started;
        Observer.Observe('at least 50 ms', Format(Elapsed >= 50));
        Observer.Expect('at least 50 ms', 'Yes');
        Observer.Verify();
    end;
}
