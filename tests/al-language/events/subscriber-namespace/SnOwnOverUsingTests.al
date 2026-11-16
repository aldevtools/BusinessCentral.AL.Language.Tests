// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer"; codeunit 77150 "LT SN Shared" (namespace LT.SN.Alpha, AL Language XApp A) and its twin
//   codeunit 77151 "LT SN Shared" (namespace LT.SN.Beta, AL Language XApp B).
// Probe: written for aldevtools/BusinessCentral.AL.Runner#8171.
// Lead: al-runner issue 8171 (an event subscriber names a codeunit that two namespaces declare; which one does it subscribe to).
//
// This file is in namespace LT.SN.Alpha, the namespace of twin 77150, and has `using LT.SN.Beta;`, the namespace of twin 77151.
// Each test binds this codeunit, calls Ping of one twin (named by its qualified name) and records the log the subscribers wrote.
// The subscriber that names the publisher by its plain name writes 'plain;'.
// Measured on BC 27.5, 28.5 and 29.0 (observe run 43805337922): the results are the same on all three majors.
// Compiled with the AL compilers of BC 28 and 29: the file compiles without a diagnostic.
namespace LT.SN.Alpha;
using LT.SN.Beta;

codeunit 77154 "LT SN Own Using Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Log: Text;

    [Test]
    procedure SubscriberOwnNamespaceAndUsing_PingAlpha()
    var
        Observer: Codeunit "Probe Observer";
        Shared: Codeunit LT.SN.Alpha."LT SN Shared";
    begin
        Log := '';
        BindSubscription(this);
        Shared.Ping(Log);
        UnbindSubscription(this);
        Observer.Observe('log', Log);
        Observer.Expect('log', 'plain;');
        Observer.Verify();
    end;

    [Test]
    procedure SubscriberOwnNamespaceAndUsing_PingBeta()
    var
        Observer: Codeunit "Probe Observer";
        Shared: Codeunit LT.SN.Beta."LT SN Shared";
    begin
        Log := '';
        BindSubscription(this);
        Shared.Ping(Log);
        UnbindSubscription(this);
        Observer.Observe('log', Log);
        Observer.Expect('log', '');
        Observer.Verify();
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SN Shared", 'OnPing', '', false, false)]
    local procedure OnPingPlain(var Log: Text)
    begin
        Log += 'plain;';
    end;
}
