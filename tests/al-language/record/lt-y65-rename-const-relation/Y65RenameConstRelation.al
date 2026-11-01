// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-rename-method
// Scope: in-scope (Cloud)
// Fixtures used: Probe Observer (codeunit 69160); enum 93348, tables 93348-93350, test codeunit 93348; Base Application tables Item and
//   "Item Attribute"
// Probe (al-runner issue 6677; conditional relations with the unqualified const(X) are record/TestRenamePropagationConditional.al): Rename of a
//   parent row when a child table relates to it through `if (Field = const(...))` with the QUALIFIED value form (const(Type::Parent) on an
//   Enum field, const(Kind::Parent) on an Option field), next to the unqualified form, and a conditional relation to a NON-key field of the
//   parent (the reporter's "Item Attribute".Name). Which child fields follow the rename, for a child row whose condition matches and one
//   whose condition does not. And the reporter's shape: Rename of an Item with such a child table.
// BC versions: 27, 28, 29

enum 93348 "LT Y65 RN Type"
{
    Extensible = true;

    value(0; Parent) { }
    value(1; Other) { }
}

table 93348 "LT Y65 RN Parent"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Code"; Code[20]) { }
        field(2; Name; Text[100]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 93349 "LT Y65 RN Link"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Entry No."; Integer) { }
        field(2; Type; Enum "LT Y65 RN Type") { }
        field(3; Kind; Option)
        {
            OptionMembers = " ",Parent,Other;
        }
        field(4; RefQualified; Code[20])
        {
            TableRelation = if (Type = const(Type::Parent)) "LT Y65 RN Parent";
        }
        field(5; RefUnqualified; Code[20])
        {
            TableRelation = if (Type = const(Parent)) "LT Y65 RN Parent";
        }
        field(6; RefOption; Code[20])
        {
            TableRelation = if (Kind = const(Parent)) "LT Y65 RN Parent";
        }
        field(7; RefOptionQualified; Code[20])
        {
            TableRelation = if (Kind = const(Kind::Parent)) "LT Y65 RN Parent";
        }
        field(8; RefName; Text[100])
        {
            TableRelation = if (Type = const(Type::Parent)) "LT Y65 RN Parent".Name;
            ValidateTableRelation = false;
        }
        field(9; RefElse; Code[20])
        {
            TableRelation = if (Type = const(Type::Other)) "LT Y65 RN Parent" where(Name = const('other'))
            else
            "LT Y65 RN Parent";
        }
        field(10; RefFilter; Code[20])
        {
            TableRelation = if (Type = filter(Type::Parent)) "LT Y65 RN Parent";
        }
    }

    keys
    {
        key(PK; "Entry No.") { Clustered = true; }
    }
}

table 93350 "LT Y65 RN Item Link"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "Item No."; Code[20])
        {
            TableRelation = Item;
        }
        field(2; Type; Enum "LT Y65 RN Type") { }
        field(4; "Attribute Name"; Text[250])
        {
            TableRelation = if (Type = const(Type::Parent)) "Item Attribute".Name;
            ValidateTableRelation = false;
        }
    }

    keys
    {
        key(PK; "Item No.", "Attribute Name") { Clustered = true; }
    }
}

codeunit 93348 "LT Y65 Rename Const Relation"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Observer: Codeunit "Probe Observer";

    local procedure AddLink(EntryNo: Integer; NewType: Enum "LT Y65 RN Type"; NewKind: Option)
    var
        Link: Record "LT Y65 RN Link";
    begin
        Link."Entry No." := EntryNo;
        Link.Type := NewType;
        Link.Kind := NewKind;
        Link.RefQualified := 'OLD';
        Link.RefUnqualified := 'OLD';
        Link.RefOption := 'OLD';
        Link.RefOptionQualified := 'OLD';
        Link.RefName := 'OLD';
        Link.RefElse := 'OLD';
        Link.RefFilter := 'OLD';
        Link.Insert();
    end;

    local procedure Row(EntryNo: Integer): Text
    var
        Link: Record "LT Y65 RN Link";
    begin
        Link.Get(EntryNo);
        exit('q=' + Link.RefQualified + ' u=' + Link.RefUnqualified + ' o=' + Link.RefOption + ' oq=' + Link.RefOptionQualified +
            ' name=' + Link.RefName + ' else=' + Link.RefElse + ' filter=' + Link.RefFilter);
    end;

    [Test]
    procedure Y65_Rename_QualifiedConstConditions()
    var
        Parent: Record "LT Y65 RN Parent";
        Link: Record "LT Y65 RN Link";
    begin
        Link.DeleteAll();
        Parent.DeleteAll();
        Parent."Code" := 'OLD';
        Parent.Name := 'OLD';
        Parent.Insert();
        AddLink(1, "LT Y65 RN Type"::Parent, Link.Kind::Parent);
        AddLink(2, "LT Y65 RN Type"::Other, Link.Kind::Other);
        Parent.Rename('NEW');
        Observer.Observe('matching row', Row(1));
        Observer.Observe('other row', Row(2));
        Observer.Observe('parent', Parent."Code" + ' ' + Parent.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Y65_Rename_Reporter_Item()
    var
        Item: Record Item;
        ReproValue: Record "LT Y65 RN Item Link";
    begin
        // al-runner issue 6677, the reporter's shape.
        Item."No." := 'LTY65-OLD';
        Item.Insert();
        ReproValue."Item No." := 'LTY65-OLD';
        ReproValue."Attribute Name" := 'Colour';
        ReproValue.Insert();
        Item.Rename('LTY65-NEW');
        Observer.Observe('renamed link', Format(ReproValue.Get('LTY65-NEW', 'Colour')));
        Observer.Observe('old link', Format(ReproValue.Get('LTY65-OLD', 'Colour')));
        Observer.Finish();
    end;
}
