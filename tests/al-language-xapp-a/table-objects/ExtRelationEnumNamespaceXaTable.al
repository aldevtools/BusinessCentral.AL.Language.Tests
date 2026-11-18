// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: none.
// The table of the dependent-app cells of tests/al-language/table-objects/extensions/
// ExtRelationEnumNamespace_Tests.al: the AL Language Coverage Tests app extends LT ERN XA Line in
// ExtRelationEnumNamespace_XaExt.al and _XaTwin.al. "Order No." has no TableRelation of its own.

namespace ALLanguage.Coverage.ErnXa;

using ALLanguage.Coverage.ErnXaEnums;

table 97996 "LT ERN XA Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Enum "LT ERN XA Kind") { }
        field(3; "Order No."; Code[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
