// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-extensible-enums
// Scope: in-scope
// Fixtures used: none (the objects of ExtRelationEnumNamespace_Tests.al)
//
// Namespace ErnEnums. The enums of the Enum fields "LT ERN Line"."Order Type" and Type, and of
// "LT ERN Order".Status. The table extension in ExtRelationEnumNamespace_Ext.al names members of
// them in its TableRelation conditions and where() without a `using` of this namespace, as Base
// Application's "Mfg. Item Journal Line" names "Inventory Order Type"::Production. "Work Center"
// and "Machine Center" come from an enumextension, as in Base Application's "Mfg. Standard Cost
// Source Type".
// local object: the enums must live in a namespace the table extension does not use.

namespace ALLanguage.Coverage.ErnEnums;

enum 97044 "LT ERN Order Type"
{
    Extensible = true;

    value(0; " ") { }
    value(1; Production) { }
    value(2; Transfer) { }
}

enum 97046 "LT ERN Order Status"
{
    Extensible = true;

    value(0; Planned) { }
    value(1; Released) { }
}

enum 97045 "LT ERN Source Type"
{
    Extensible = true;

    value(0; Item) { }
    value(3; Resource) { }
}

enumextension 97044 "LT ERN Source Type Ext" extends "LT ERN Source Type"
{
    value(1; "Work Center") { }
    value(2; "Machine Center") { }
}
