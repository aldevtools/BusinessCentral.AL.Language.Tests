// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: LT EMF Kind (97997, EnumMemberFieldTypeXaEnum.al).
// The table whose Enum field Kind the tests in tests/al-language/types/enum-option/EnumMemberFieldType_Tests.al name a
// member through (`Line.Kind::Production`).

namespace ALLanguage.Coverage.EmfData;

using ALLanguage.Coverage.EmfEnums;

table 97997 "LT EMF Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT EMF Kind") { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
