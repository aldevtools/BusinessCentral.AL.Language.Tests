// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
// Scope: in-scope
// Fixtures used: codeunit 69160 "Probe Observer"; codeunit 77150 "LT SN Shared" (namespace LT.SN.Alpha, AL Language XApp A) and its twin
//   codeunit 77151 "LT SN Shared" (namespace LT.SN.Beta, AL Language XApp B).
// Probe: written for aldevtools/BusinessCentral.AL.Runner#8171.
// Lead: al-runner issue 8171 (an event subscriber names a codeunit that two namespaces declare; which one does it subscribe to).
//
// This file is in namespace LT.SN.Tests and has `using LT.SN.Beta;`: the plain name is found through the `using`.
// Each test binds this codeunit, calls Ping of one twin (named by its qualified name) and records the log the subscribers wrote.
// The subscriber that names the publisher by its plain name writes 'plain;'.
// Two more subscribers name each twin by its qualified name (Codeunit::LT.SN.Alpha."LT SN Shared" writes 'qualified alpha;', the Beta
// one 'qualified beta;').
// Compiled with the AL compilers of BC 28 and 29: the file compiles without a diagnostic.
namespace LT.SN.Tests;
using LT.SN.Beta;

codeunit 77152 "LT SN Using Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;
    EventSubscriberInstance = Manual;

    var
        Log: Text;

    [Test]
    procedure SubscriberViaUsing_PingAlpha()
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
    procedure SubscriberViaUsing_PingBeta()
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

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LT.SN.Alpha."LT SN Shared", 'OnPing', '', false, false)]
    local procedure OnPingQualifiedAlpha(var Log: Text)
    begin
        Log += 'qualified alpha;';
    end;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::LT.SN.Beta."LT SN Shared", 'OnPing', '', false, false)]
    local procedure OnPingQualifiedBeta(var Log: Text)
    begin
        Log += 'qualified beta;';
    end;
}
