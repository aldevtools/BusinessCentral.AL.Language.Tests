// An event subscriber names codeunit "LT SN Shared" by its plain name. Two corpus dependency apps declare a codeunit of that name: 77150 in
// namespace LT.SN.Alpha of AL Language XApp A (tests/al-language-xapp-a/SnXaShared.al) and 77151 in namespace LT.SN.Beta of AL Language
// XApp B (tests/al-language-xapp-b/SnXbShared.al). This file has a namespace and no `using`: AL0118, neither twin is
// found (no search of other namespaces).
// The tests that compile: tests/al-language/events/subscriber-namespace/ (al-runner issue 8171).
// @depends AL Language XApp A,AL Language XApp B,Base Application,System Application
// @expect AL0118 | The name '"LT SN Shared"' does not exist in the current context
namespace MNC.Probe;
codeunit 50000 "MNC SN Plain Twin Subscriber"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Codeunit, Codeunit::"LT SN Shared", 'OnPing', '', false, false)]
    local procedure OnPing(var Log: Text)
    begin
        Log += 'plain;';
    end;
}
