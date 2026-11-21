// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none.
// The enum of LT EMF Line.Kind (EnumMemberFieldTypeXaTable.al), for tests/al-language/types/enum-option/
// EnumMemberFieldType_Tests.al. The coverage app declares an enum of the same name in another namespace
// (EnumMemberFieldType_Twin.al); two enums of one name cannot be in one app (AL0197), so this one lives here.

namespace ALLanguage.Coverage.EmfEnums;

enum 97997 "LT EMF Kind"
{
    Extensible = true;

    value(0; " ") { }
    value(1; Production) { }
    value(2; Transfer) { }
}
