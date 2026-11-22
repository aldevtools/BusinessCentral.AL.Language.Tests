// Publisher name resolution of event subscribers (al-runner issue 8171): codeunit "LT SN Shared" is declared twice, in two namespaces of
// two apps. This one is in namespace LT.SN.Beta of AL Language XApp B; its twin 77150 is in namespace LT.SN.Alpha of AL Language XApp A
// (tests/al-language-xapp-a/SnXaShared.al). An app may not declare two objects of one name, even in two namespaces (AL0197), so
// the twins live in two apps. Tests: tests/al-language/events/subscriber-namespace/. Must-not-compile: cases 3171 to 3173.
namespace LT.SN.Beta;

codeunit 77151 "LT SN Shared"
{
    procedure Ping(var Log: Text)
    begin
        OnPing(Log);
    end;

    [IntegrationEvent(false, false)]
    local procedure OnPing(var Log: Text)
    begin
    end;
}
