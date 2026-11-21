// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modify-table-fields
// Scope: in-scope
// Fixtures used: LT ERN XA Line (97996) and LT ERN XA Kind (97996) of AL Language XApp A
//   (tests/al-language-xapp-a/table-objects/ExtRelationEnumNamespaceXaEnum.al and _XaTable.al); LT ERN Order (97044)
//
// Namespace ErnXa, the namespace of the table it extends, which lives in another app (XApp A), as
// a partner extension of a Base Application table does. No `using` of ErnXaEnums, the namespace of
// the enum of the condition field Kind.
// local object: the table extension of the dependent-app cell of ExtRelationEnumNamespace_Tests.al.

namespace ALLanguage.Coverage.ErnXa;

using ALLanguage.Coverage.ErnTargets;

tableextension 97045 "LT ERN XA Line Ext" extends "LT ERN XA Line"
{
    fields
    {
        modify("Order No.")
        {
            TableRelation = if (Kind = const(Production)) "LT ERN Order"."No." where(Status = const(Released));
        }
    }
}
