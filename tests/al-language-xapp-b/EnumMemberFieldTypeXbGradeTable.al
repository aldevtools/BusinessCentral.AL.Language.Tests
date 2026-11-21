// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Grade (61111, EnumMemberFieldTypeXbGrade.al).
// The table whose Enum field Grade tests/al-language/types/enum-option/EnumMemberFieldTypeShapes_Tests.al names a member
// through (`Line.Grade::Production`), in a namespace other than its enum's.

namespace ALLanguage.Coverage.EmfGradeData;

using ALLanguage.Coverage.EmfGrades;

table 61111 "LT EMF Graded Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Grade; Enum "LT EMF Grade") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
