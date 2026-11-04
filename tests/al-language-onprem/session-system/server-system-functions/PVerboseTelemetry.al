// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/session/session-enableverbosetelemetry-method
// Scope: in-scope (OnPrem app only: Session.EnableVerboseTelemetry)
// Fixtures used: Probe Observer (69160), from the AL Language Coverage Tests app; codeunit 61250
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// RISKY: changes the telemetry mode of the own session; every test ends with EnableVerboseTelemetry(false, 0)
//
// EnableVerboseTelemetry(Enable, Duration): turning it on with several durations, and always reset with (false, 0). Outcome and error text only.
// BC versions: 29 (27 and 28 by CI)
codeunit 61250 "LT P109 VerboseTelemetry"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryEnable(Enable: Boolean; Milliseconds: Integer)
    var
        Dur: Duration;
    begin
        Dur := Milliseconds;
        Session.EnableVerboseTelemetry(Enable, Dur);
    end;

    local procedure Outcome(Enable: Boolean; Milliseconds: Integer): Text
    begin
        if TryEnable(Enable, Milliseconds) then
            exit('ok');
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P109_EnableVerboseTelemetry_Durations()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('on_1000', Outcome(true, 1000));
        Observer.Observe('reset_1', Outcome(false, 0));
        Observer.Observe('on_0', Outcome(true, 0));
        Observer.Observe('reset_2', Outcome(false, 0));
        Observer.Observe('on_negative', Outcome(true, -1));
        Observer.Observe('reset_3', Outcome(false, 0));
        Observer.Observe('on_one_minute', Outcome(true, 60000));
        Observer.Observe('reset_4', Outcome(false, 0));
        Observer.Observe('on_one_day', Outcome(true, 86400000));
        Observer.Observe('reset_5', Outcome(false, 0));
        Observer.Observe('off_with_duration', Outcome(false, 1000));
        Observer.Observe('reset_6', Outcome(false, 0));
        Observer.Expect('on_1000', 'ok');
        Observer.Expect('reset_1', 'ok');
        Observer.Expect('on_0', 'ok');
        Observer.Expect('reset_2', 'ok');
        Observer.Expect('on_negative', 'ok');
        Observer.Expect('reset_3', 'ok');
        Observer.Expect('on_one_minute', 'ok');
        Observer.Expect('reset_4', 'ok');
        Observer.Expect('on_one_day', 'ok');
        Observer.Expect('reset_5', 'ok');
        Observer.Expect('off_with_duration', 'ok');
        Observer.Expect('reset_6', 'ok');
        Observer.Verify();
    end;
}
