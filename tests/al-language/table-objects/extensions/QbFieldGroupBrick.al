// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-field-groups
// Scope: in-scope
// Fixtures of TestTableExtKeysAndInitValue.al (writer QB, corpus issue #664 item 97): a base table with a DropDown field group and no Brick
// field group, and a tableextension that adds a field and runs addlast(Brick; ...) and addlast(DropDown; ...) in fieldgroups. The lead says
// addlast(Brick) fails with "The FieldGroup 'Brick' is not found in the target."; if it did, this app would not compile or publish.

table 86391 "LT QB Fg Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[20]) { }
        field(2; Description; Text[50]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }

    fieldgroups
    {
        fieldgroup(DropDown; "No.", Description) { }
    }
}

tableextension 86392 "LT QB Fg Base Ext" extends "LT QB Fg Base"
{
    fields
    {
        field(86393; "QB Extra"; Text[30]) { DataClassification = SystemMetadata; }
    }

    fieldgroups
    {
        addlast(Brick; Description, "QB Extra") { }
        addlast(DropDown; "QB Extra") { }
    }
}
