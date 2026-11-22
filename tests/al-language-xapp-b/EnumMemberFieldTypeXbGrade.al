// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none.
// The enum of LT EMF Graded Line.Grade (EnumMemberFieldTypeXbGradeTable.al), for
// tests/al-language/types/enum-option/EnumMemberFieldTypeShapes_Tests.al. XApp A declares an enum of the same name in the
// global namespace (EnumMemberFieldTypeXaGlobalEnum.al), with Production at ordinal 8.

namespace ALLanguage.Coverage.EmfGrades;

enum 61111 "LT EMF Grade"
{
    value(0; " ") { }
    value(1; Production) { }
}
