// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope (Cloud-compatible)
// Objects for the PYD_ tests in tableextension/TestTableExtFieldTableRelation.al (writer PY-D, 2026-10-20): modify(<field>) { TableRelation }
// combinations the runtime did not understand: a conditional base relation with an unconditional extension relation, a base relation with an
// else arm, and two tableextensions that both modify one field. Targets are LT BS Target A (83151) and LT BS Target B (83152).
// Object ids 85220-85222. Not a test codeunit file.

table 85220 "LT PYD Rel Base"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Kind; Option) { OptionMembers = X,Y,Z; }
        // base conditional; LT PYD Rel Ext One adds an unconditional relation
        field(3; MixCond; Code[20]) { TableRelation = if (Kind = const(X)) "LT BS Target A"; }
        // base with an else arm; LT PYD Rel Ext One adds a conditional relation for Z
        field(4; ElseArm; Code[20]) { TableRelation = if (Kind = const(X)) "LT BS Target A" else "LT BS Target B"; }
        // base conditional; both extensions add a conditional relation for Y (Ext One: B, Ext Two: A) and Ext Two one for Z
        field(5; TwoExtCond; Code[20]) { TableRelation = if (Kind = const(X)) "LT BS Target A"; }
        // base conditional; both extensions add an unconditional relation (Ext One: B, Ext Two: A)
        field(6; TwoExtUncond; Code[20]) { TableRelation = if (Kind = const(X)) "LT BS Target A"; }
        // base unconditional A; Ext One adds a conditional relation with an else arm
        field(7; UncondThenElse; Code[20]) { TableRelation = "LT BS Target A"; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

tableextension 85221 "LT PYD Rel Ext One" extends "LT PYD Rel Base"
{
    fields
    {
        modify(MixCond) { TableRelation = "LT BS Target B"; }
        modify(ElseArm) { TableRelation = if (Kind = const(Z)) "LT BS Target A"; }
        modify(TwoExtCond) { TableRelation = if (Kind = const(Y)) "LT BS Target B"; }
        modify(TwoExtUncond) { TableRelation = "LT BS Target B"; }
        modify(UncondThenElse) { TableRelation = if (Kind = const(Y)) "LT BS Target B" else "LT BS Target B"; }
    }
}

tableextension 85222 "LT PYD Rel Ext Two" extends "LT PYD Rel Base"
{
    fields
    {
        modify(TwoExtCond) { TableRelation = if (Kind = const(Y)) "LT BS Target A" else if (Kind = const(Z)) "LT BS Target A"; }
        modify(TwoExtUncond) { TableRelation = "LT BS Target A"; }
    }
}
