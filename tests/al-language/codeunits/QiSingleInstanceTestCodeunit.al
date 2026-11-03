// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-singleinstance-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (LT QI SI *)
// Probe: written against a local BC 29.0 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: a test codeunit with SingleInstance = true: does a variable of its own type (a procedure called through it, a manual
//   BindSubscription of it) and its own event subscriber (EventSubscriberInstance = Manual) see and set the globals the test method
//   uses; does the second test method of the codeunit see what the first one left. A subscriber in a test codeunit must be Manual
//   (StaticAutomatic is AL0501 at compile: tests/must-not-compile/cases/1960, 1961).
// Settles al-runtime-rs docs/probes-needed.md row "A test codeunit with SingleInstance = true" (Tests-ERM 139844 Cost Adj. Sch. Notif. Tests).
// BC versions: 29 (27 and 28 by CI)

codeunit 86840 "LT QI SI Publisher"
{
    procedure Ping(Value: Text)
    begin
        OnPing(Value);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(Value: Text)
    begin
    end;
}

codeunit 86841 "LT QI SI Manual Test"
{
    Subtype = Test;
    TestPermissions = Disabled;
    SingleInstance = true;
    EventSubscriberInstance = Manual;

    var
        Marker: Text;
        SubscriberCalls: Integer;
        Observer: Codeunit "Probe Observer";

    procedure SetMarker(Value: Text)
    begin
        Marker := Value;
    end;

    procedure GetMarker(): Text
    begin
        exit(Marker);
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT QI SI Publisher", 'OnPing', '', false, false)]
    local procedure HandlePing(Value: Text)
    begin
        SubscriberCalls += 1;
        Marker := 'sub saw [' + Marker + '] got ' + Value;
    end;

    [Test]
    procedure QI_SI_1_OwnTypeVariableAndManualSubscriber()
    var
        Other: Codeunit "LT QI SI Manual Test";
        Publisher: Codeunit "LT QI SI Publisher";
    begin
        Observer.Observe('start-marker', Marker);
        Observer.Observe('start-calls', Format(SubscriberCalls));
        Marker := 'm1';
        Observer.Observe('other-get', Other.GetMarker());
        Other.SetMarker('m2');
        Observer.Observe('own-after-other-set', Marker);
        Publisher.Ping('unbound');
        Observer.Observe('own-after-unbound-ping', Marker);
        Observer.Observe('calls-after-unbound-ping', Format(SubscriberCalls));
        Observer.Observe('bind', Format(BindSubscription(Other)));
        Publisher.Ping('bound');
        Observer.Observe('own-after-bound-ping', Marker);
        Observer.Observe('other-after-bound-ping', Other.GetMarker());
        Observer.Observe('calls-after-bound-ping', Format(SubscriberCalls));
        Observer.Observe('unbind', Format(UnbindSubscription(Other)));
        Publisher.Ping('after unbind');
        Observer.Observe('own-after-unbind-ping', Marker);
        Marker := 'left by test 1';
        Observer.Expect('start-marker', '');
        Observer.Expect('start-calls', '0');
        Observer.Expect('other-get', 'm1');
        Observer.Expect('own-after-other-set', 'm2');
        Observer.Expect('own-after-unbound-ping', 'm2');
        Observer.Expect('calls-after-unbound-ping', '0');
        Observer.Expect('bind', 'Yes');
        Observer.Expect('own-after-bound-ping', 'sub saw [m2] got bound');
        Observer.Expect('other-after-bound-ping', 'sub saw [m2] got bound');
        Observer.Expect('calls-after-bound-ping', '1');
        Observer.Expect('unbind', 'Yes');
        Observer.Expect('own-after-unbind-ping', 'sub saw [m2] got bound');
        Observer.Verify();
    end;

    [Test]
    procedure QI_SI_2_SecondTestSeesTheFirst()
    var
        Other: Codeunit "LT QI SI Manual Test";
    begin
        Observer.Observe('start-marker', Marker);
        Observer.Observe('start-calls', Format(SubscriberCalls));
        Observer.Observe('other-get', Other.GetMarker());
        Observer.Expect('start-marker', 'left by test 1');
        Observer.Expect('start-calls', '1');
        Observer.Expect('other-get', 'left by test 1');
        Observer.Verify();
    end;
}
