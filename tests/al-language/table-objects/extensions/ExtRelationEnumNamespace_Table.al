// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: none (the objects of ExtRelationEnumNamespace_Tests.al)
//
// Namespace ErnJournal. The table whose fields the extension in ExtRelationEnumNamespace_Ext.al
// relates: "Order No." has no TableRelation of its own (as Base Application's Item Journal
// Line."Order No."), "No." relates Item and Resource by Type (as Standard Cost Worksheet."No.").
// This file uses ErnEnums, so it names the enums of "Order Type" and Type.
// local object: the table the probe's table extension changes.

namespace ALLanguage.Coverage.ErnJournal;

using ALLanguage.Coverage.ErnEnums;
using ALLanguage.Coverage.ErnTargets;

table 97049 "LT ERN Line"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; "Order Type"; Enum "LT ERN Order Type") { }
        field(3; "Order No."; Code[20]) { }
        field(4; Type; Enum "LT ERN Source Type") { }
        field(5; "No."; Code[20])
        {
            TableRelation = if (Type = const(Item)) "LT ERN Item"
            else
            if (Type = const(Resource)) "LT ERN Resource";
        }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}
