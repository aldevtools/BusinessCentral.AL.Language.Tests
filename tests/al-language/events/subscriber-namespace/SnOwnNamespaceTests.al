// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer"; codeunit 77150 "LT SN Shared" (namespace LT.SN.Alpha, AL Language XApp A) and its twin
//   codeunit 77151 "LT SN Shared" (namespace LT.SN.Beta, AL Language XApp B).
// Probe: written for aldevtools/BusinessCentral.AL.Runner#8171.
// Lead: al-runner issue 8171 (an event subscriber names a codeunit that two namespaces declare; which one does it subscribe to).
//
// This file is in namespace LT.SN.Alpha, the namespace of twin 77150, and has no `using`.
// Each test binds this codeunit, calls Ping of one twin (named by its qualified name) and records the log the subscribers wrote.
// The subscriber that names the publisher by its plain name writes 'plain;'.
// Compiled with the AL compilers of BC 28 and 29: the file compiles without a diagnostic.
namespace LT.SN.Alpha;

codeunit 77153 "LT SN Own Ns Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Log: Text;

    [Test]
    procedure SubscriberViaOwnNamespace_PingAlpha()
    var
        Observer: Codeunit "Probe Observer";
        Shared: Codeunit LT.SN.Alpha."LT SN Shared";
    begin
        Log := '';
        BindSubscription(this);
        Shared.Ping(Log);
        UnbindSubscription(this);
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [Test]
    procedure SubscriberViaOwnNamespace_PingBeta()
    var
        Observer: Codeunit "Probe Observer";
        Shared: Codeunit LT.SN.Beta."LT SN Shared";
    begin
        Log := '';
        BindSubscription(this);
        Shared.Ping(Log);
        UnbindSubscription(this);
        Observer.Observe('log', Log);
        Observer.Finish();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SN Shared", 'OnPing', '', false, false)]
    local procedure OnPingPlain(var Log: Text)
    begin
        Log += 'plain;';
    end;
}
