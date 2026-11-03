// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-using-directive
// Scope: in-scope
// Fixtures used: none (declares the namespaced enum used by the two next PnC namespace files)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles probes-needed row: Namespaces "Enum::Ns.Sub.\"Name\".FromInteger(n) / .Names(), Ns.Sub.\"Name\"::Value and Enum::Ns.Sub.\"Name\"::Value resolve the enum through its namespace" (fixture)
// BC versions: 29 (27 and 28 by CI)

namespace LTPnC.Enums;

enum 71092 "LT PnC NsEnum"
{
    Extensible = true;

    value(0; First) { }
    value(3; "Third Value") { Caption = 'Third Caption'; }
}
