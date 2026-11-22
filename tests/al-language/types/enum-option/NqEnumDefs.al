// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-namespaces-overview
// Scope: in-scope
// Fixtures used: none; the enum of the namespace-qualified receiver probe (NqReceiverNoUsing.al, NqReceiverUsing.al).
// local object: the enum's namespace is under test (the callers sit in other namespaces).
// BC versions: 27, 28, 29
namespace XYZ.Probe.Kinds;

enum 70021 "NQ Probe Kind"
{
    Extensible = true;
    value(0; Zero) { }
    value(1; One) { }
    value(2; Two) { }
    value(3; Three) { }
}
