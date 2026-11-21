// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: none (the objects of ExtRelationEnumNamespace_Tests.al)
//
// Namespace ErnTargets. The related tables of the relations in ExtRelationEnumNamespace_Table.al
// and ExtRelationEnumNamespace_Ext.al. "LT ERN Order" has the key Status, "No." with an Enum
// Status, as Base Application's "Production Order"; the others have one key field.
// local object: the related tables of the probe, in their own namespace.

namespace ALLanguage.Coverage.ErnTargets;

using ALLanguage.Coverage.ErnEnums;

table 97044 "LT ERN Order"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Status; Enum "LT ERN Order Status") { }
        field(2; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; Status, "No.") { Clustered = true; }
    }
}

table 97045 "LT ERN Item"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97046 "LT ERN Resource"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97047 "LT ERN Work Center"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

table 97048 "LT ERN Machine Center"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[20]) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}
