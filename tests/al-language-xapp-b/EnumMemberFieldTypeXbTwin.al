// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none.
// A second enum named like the enum of XApp A's LT EMF Line.Kind, in namespace EmfTwinB, with Production at ordinal 7, for
// tests/al-language/types/enum-option/EnumMemberFieldTypeShapes_Usings.al: a file with a `using` of this namespace and of
// the coverage app's EmfTwin finds two enums of that name, neither of them the field's. Two enums of one name cannot be in
// one app (AL0197), so this one lives here.

namespace ALLanguage.Coverage.EmfTwinB;

enum 61110 "LT EMF Kind"
{
    value(0; " ") { }
    value(7; Production) { }
}
