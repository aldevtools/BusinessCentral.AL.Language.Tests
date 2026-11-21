// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none.
// Two enums of the global namespace for tests/al-language/types/enum-option/EnumMemberFieldTypeShapes_Tests.al:
// - LT EMF GKind, the enum of LT EMF Line."G Kind" (EnumMemberFieldTypeXaTable.al). The coverage app declares an enum of
//   the same name in namespace EmfTwin (EnumMemberFieldTypeShapes_Twin.al), with Production at ordinal 5.
// - LT EMF Grade, named like the enum of XApp B's LT EMF Graded Line.Grade (namespace EmfGrades, Production at ordinal 1),
//   with Production at ordinal 8: a file without a `using` of EmfGrades finds this one by the name. It lives in XApp A
//   because an app cannot declare an enum in the global namespace with the name of a namespaced enum of a dependency
//   (AL0197 on Business Central 29.1); the other way round compiles.

enum 97990 "LT EMF GKind"
{
    Extensible = true;

    value(0; " ") { }
    value(1; Production) { }
}

enum 97991 "LT EMF Grade"
{
    value(0; " ") { }
    value(8; Production) { }
}
