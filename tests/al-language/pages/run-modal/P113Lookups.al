// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-tablerelation-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); own fixtures declared in this file (P113 LK)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: page-level TableRelation on a page control (field without a table relation on the table), DrillDownPageID and LookupPageID on page controls: TestPage Lookup / Drilldown open the page (modal handler picks a row), SetValue validates against the page-level relation (error text and code), conditional page relation
// BC versions: 29 (27 and 28 by CI)

table 73091 "LT P113 Grp"
{
    DataClassification = CustomerContent;
    LookupPageId = "LT P113 Grp List";

    fields
    {
        field(1; "Code"; Code[10]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; "Code") { Clustered = true; }
    }
}

table 73092 "LT P113 Itm"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Name; Text[30]) { }
        field(3; Grp; Code[10]) { }
        field(4; Qty; Integer) { }
        field(5; Ref; Code[10]) { }
        field(6; Grp2; Code[10]) { }
        field(7; Txt; Text[30]) { }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 73093 "LT P113 Grp List"
{
    PageType = List;
    SourceTable = "LT P113 Grp";
    ApplicationArea = All;
    Editable = false;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(CodeCtl; Rec."Code") { ApplicationArea = All; }
                field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 73094 "LT P113 Itm Card"
{
    PageType = Card;
    SourceTable = "LT P113 Itm";
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            group(General)
            {
                field(NoCtl; Rec."No.") { ApplicationArea = All; }
                field(NameCtl; Rec.Name) { ApplicationArea = All; }
                field(GrpCtl; Rec.Grp) { ApplicationArea = All; TableRelation = "LT P113 Grp".Code; }
                field(Grp2Ctl; Rec.Grp2) { ApplicationArea = All; TableRelation = "LT P113 Grp".Code where (Descr = const('Open')); }
                field(DrillCtl; Rec.Qty) { ApplicationArea = All; DrillDownPageId = "LT P113 Grp List"; }
                field(LookCtl; Rec.Ref) { ApplicationArea = All; LookupPageId = "LT P113 Grp List"; }
                field(BothCtl; Rec.Txt) { ApplicationArea = All; DrillDownPageId = "LT P113 Grp List"; LookupPageId = "LT P113 Grp List"; }
            }
        }
    }
}

codeunit 73095 "LT P113 Lookups"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Itm: Record "LT P113 Itm";
        Grp: Record "LT P113 Grp";
    begin
        Itm.DeleteAll();
        Grp.DeleteAll();
        Grp.Code := 'G1';
        Grp.Descr := 'Open';
        Grp.Insert();
        Grp.Code := 'G2';
        Grp.Descr := 'Closed';
        Grp.Insert();
        Itm."No." := 'I1';
        Itm.Name := 'Item one';
        Itm.Insert();
    end;

    [ModalPageHandler]
    procedure PickG2(var P: TestPage "LT P113 Grp List")
    begin
        P.GoToKey('G2');
        P.OK().Invoke();
    end;

    [Test]
    procedure P113_LK_ValidValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.GrpCtl.SetValue('G1');
        Observer.Observe('shown', Card.GrpCtl.Value());
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp);
        Observer.Expect('shown', 'G1');
        Observer.Expect('stored', 'G1');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_BlankValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Itm.Get('I1');
        Itm.Grp := 'G1';
        Itm.Modify();
        Card.OpenEdit();
        Card.GrpCtl.SetValue('');
        Observer.Observe('shown', Card.GrpCtl.Value());
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp);
        Observer.Expect('shown', '');
        Observer.Expect('stored', '');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_UnknownValue()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.GrpCtl.SetValue('NOPE');
        Observer.Observe('unknown', 'no error');
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp);
        Observer.Expect('unknown', 'no error');
        Observer.Expect('stored', 'NOPE');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_CaseInsensitive()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.GrpCtl.SetValue('g2');
        Observer.Observe('shown', Card.GrpCtl.Value());
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp);
        Observer.Expect('shown', 'G2');
        Observer.Expect('stored', 'G2');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_NoRelationOnTheTable()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        // Ref has neither a table relation nor a page relation: any value is accepted
        Seed();
        Card.OpenEdit();
        Card.LookCtl.SetValue('ANY');
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Ref);
        Observer.Expect('stored', 'ANY');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_ConditionalRelation_Match()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.Grp2Ctl.SetValue('G1');
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp2);
        Observer.Expect('stored', 'G1');
        Observer.Verify();
    end;

    [Test]
    procedure P113_LK_ConditionalRelation_Filtered()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.Grp2Ctl.SetValue('G2');
        Observer.Observe('filtered-out', 'no error');
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp2);
        Observer.Expect('filtered-out', 'no error');
        Observer.Expect('stored', 'G2');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickG2')]
    procedure P113_LK_LookupWithPageRelation()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
        Itm: Record "LT P113 Itm";
    begin
        Seed();
        Card.OpenEdit();
        Card.GrpCtl.Lookup();
        Observer.Observe('shown', Card.GrpCtl.Value());
        Card.Close();
        Itm.Get('I1');
        Observer.Observe('stored', Itm.Grp);
        Observer.Expect('shown', 'G2');
        Observer.Expect('stored', 'G2');
        Observer.Verify();
    end;
}

codeunit 73096 "LT P113 Lookups Page"
{
    Subtype = Test;
    TestPermissions = Disabled;

    // DrillDownPageId opens a non-modal page: the same drilldown with a PageHandler (the other variant fails and is dropped by the lead)
    local procedure Seed()
    var
        Itm: Record "LT P113 Itm";
        Grp: Record "LT P113 Grp";
    begin
        Itm.DeleteAll();
        Grp.DeleteAll();
        Grp.Code := 'G1';
        Grp.Descr := 'Open';
        Grp.Insert();
        Itm."No." := 'I1';
        Itm.Insert();
    end;

    [PageHandler]
    procedure SeeList(var P: TestPage "LT P113 Grp List")
    begin
        P.First();
    end;

    [Test]
    [HandlerFunctions('SeeList')]
    procedure P113_LK_DrilldownNonModal()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P113 Itm Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.DrillCtl.Drilldown();
        Observer.Observe('after', Card.DrillCtl.Value());
        Card.Close();
        Observer.Expect('after', '0');
        Observer.Verify();
    end;
}
