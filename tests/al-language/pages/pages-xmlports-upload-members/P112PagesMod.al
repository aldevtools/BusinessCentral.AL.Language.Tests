// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: P112Pages.al (tables 71860-71861, pages 71863-71864, log 71862 is NOT used here), Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: OnAfterAfterLookup and OnDrillDown in modify() blocks of a second page extension on the same base page; values read through TestPage
// BC versions: 29 (27 and 28 by CI)

table 71867 "LT P112 Mod Log"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Entry; Text[250]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 71868 "LT P112 Mod Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Grp; Code[10]) { TableRelation = "LT P112 Group"."Code"; }
        field(3; Qty; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 71869 "LT P112 Mod Card"
{
    PageType = Card;
    SourceTable = "LT P112 Mod Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(GrpCtl; Rec.Grp) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty) { ApplicationArea = All; }
        }
    }
}

pageextension 71874 "LT P112 Mod Ext" extends "LT P112 Mod Card"
{
    layout
    {
        modify(GrpCtl)
        {
            trigger OnAfterAfterLookup(Selected: RecordRef)
            var
                Entry: Record "LT P112 Mod Log";
            begin
                Entry.Id := 1;
                Entry.Entry := 'modify afterAfterLookup sel=' + Format(Selected.Field(1).Value);
                if not Entry.Insert() then
                    Entry.Modify();
            end;
        }
        modify(QtyCtl)
        {
            trigger OnDrillDown()
            var
                Entry: Record "LT P112 Mod Log";
            begin
                Entry.Id := 2;
                Entry.Entry := 'modify drill qty=' + Format(Rec.Qty);
                if not Entry.Insert() then
                    Entry.Modify();
            end;
        }
    }
}

codeunit 71870 "LT P112 PgMod Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Grp: Record "LT P112 Group";
        Row: Record "LT P112 Mod Row";
        Entry: Record "LT P112 Mod Log";
    begin
        Grp.DeleteAll();
        Row.DeleteAll();
        Entry.DeleteAll();
        Grp.Code := 'A';
        Grp.Insert();
        Grp.Code := 'B';
        Grp.Insert();
        Row."No." := 'M1';
        Row.Qty := 3;
        Row.Insert();
    end;

    local procedure LogText(): Text
    var
        Entry: Record "LT P112 Mod Log";
        Result: Text;
    begin
        if Entry.FindSet() then
            repeat
                Result += Entry.Entry + ';';
            until Entry.Next() = 0;
        exit(Result);
    end;

    [ModalPageHandler]
    procedure PickB(var P: TestPage "LT P112 Grp List")
    begin
        P.GoToKey('B');
        P.OK().Invoke();
    end;

    [Test]
    [HandlerFunctions('PickB')]
    procedure P112_Modify_AfterAfterLookup()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Mod Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('M1');
        Card.GrpCtl.Lookup();
        Observer.Observe('log', LogText());
        Observer.Observe('value', Card.GrpCtl.Value());
        Card.Close();
        Observer.Expect('log', 'modify afterAfterLookup sel=B;');
        Observer.Expect('value', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Modify_DrillDown()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Mod Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('M1');
        Card.QtyCtl.DrillDown();
        Observer.Observe('log', LogText());
        Card.Close();
        Observer.Expect('log', 'modify drill qty=3;');
        Observer.Verify();
    end;
}
