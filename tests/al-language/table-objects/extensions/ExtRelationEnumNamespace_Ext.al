// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-modify-table-fields
// Scope: in-scope
// Fixtures used: none (the objects of ExtRelationEnumNamespace_Tests.al)
//
// Namespace ErnMfg, with no `using` of ErnEnums. The extension sets TableRelations whose
// conditions name members of the enums of "Order Type" and Type, and whose where() names a
// member of the enum of "LT ERN Order".Status, though this file cannot name those enums: the
// members are those of the fields' own types. Shaped like Base Application's "Mfg. Item Journal
// Line" (modify("Order No.") and its own fields) and "Mfg. Standard Cost Worksheet" (modify("No.")
// with members of an enumextension). "Order Ref Q" names the member qualified with the field.
// local object: the table extension under test.

namespace ALLanguage.Coverage.ErnMfg;

using ALLanguage.Coverage.ErnJournal;
using ALLanguage.Coverage.ErnTargets;

tableextension 97044 "LT ERN Line Ext" extends "LT ERN Line"
{
    fields
    {
        field(97044; "Order Ref"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = if ("Order Type" = const(Production)) "LT ERN Order"."No." where(Status = const(Released));
        }
        field(97045; "Order Ref Q"; Code[20])
        {
            DataClassification = CustomerContent;
            TableRelation = if ("Order Type" = const("Order Type"::Production)) "LT ERN Order"."No." where(Status = const(Released));
        }
        modify("Order No.")
        {
            TableRelation = if ("Order Type" = const(Production)) "LT ERN Order"."No." where(Status = const(Released));
        }
        modify("No.")
        {
            TableRelation = if (Type = const("Machine Center")) "LT ERN Machine Center"
            else
            if (Type = const("Work Center")) "LT ERN Work Center";
        }
    }
}
