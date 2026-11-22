// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: none.
// The enum of the dependent-app cells of tests/al-language/table-objects/extensions/
// ExtRelationEnumNamespace_Tests.al: the AL Language Coverage Tests app extends LT ERN XA Line in
// ExtRelationEnumNamespace_XaExt.al and _XaTwin.al. "Order No." has no TableRelation of its own.

namespace ALLanguage.Coverage.ErnXaEnums;

enum 97996 "LT ERN XA Kind"
{
    Extensible = true;

    value(0; " ") { }
    value(1; Production) { }
    value(2; Transfer) { }
}
