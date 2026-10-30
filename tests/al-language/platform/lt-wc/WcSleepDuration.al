// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system/system-sleep-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained codeunit 90641
// Probe: written against al-runner issue 6301 (Sleep with a Duration); every value asserted below is what the BC service tier produced.
// Facts: Sleep takes a Duration (it converts to the Integer parameter, in milliseconds): zero, a positive Duration, a Duration changed in the
//        callee through a var parameter, and a negative Duration.
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
        Observer.Finish();
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
        Observer.Finish();
    end;

    [Test]
    procedure WC_Sleep_Duration_Negative()
    var
        Observer: Codeunit "Probe Observer";
        Delay: Duration;
    begin
        Delay := -5;
        asserterror Sleep(Delay);
        Observer.ObserveError('negative duration');
        asserterror Sleep(-5);
        Observer.ObserveError('negative integer');
        Observer.Finish();
    end;
}
