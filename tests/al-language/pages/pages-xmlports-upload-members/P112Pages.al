// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Scope: in-scope
// Fixtures used: own tables 71860-71861, SingleInstance log 71862 (used only by test codeunit 71866), pages 71863-71864, page extension 71865, Probe Observer 69160
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: OnAfterLookup, OnLookup, OnAssistEdit and OnDrillDown of fields on a page and of fields ADDED by a page extension, through TestPage field Lookup(), AssistEdit() and DrillDown() with a modal handler for the lookup page: which trigger runs, what it sees, and the value afterwards
// BC versions: 29 (27 and 28 by CI)

table 71860 "LT P112 Group"
{
    DataClassification = SystemMetadata;
    LookupPageId = "LT P112 Grp List";

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

table 71861 "LT P112 Card Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; Grp; Code[10]) { TableRelation = "LT P112 Group"."Code"; }
        field(3; Descr; Text[30]) { }
        field(4; Qty; Integer) { }
    }
    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

codeunit 71862 "LT P112 Pg Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take(): Text
    var
        Result: Text;
    begin
        Result := Entries;
        Entries := '';
        exit(Result);
    end;
}

page 71863 "LT P112 Grp List"
{
    PageType = List;
    SourceTable = "LT P112 Group";
    ApplicationArea = All;
    UsageCategory = None;

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

page 71864 "LT P112 Card"
{
    PageType = Card;
    SourceTable = "LT P112 Card Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(NoCtl; Rec."No.") { ApplicationArea = All; }
            field(GrpCtl; Rec.Grp)
            {
                ApplicationArea = All;

                trigger OnAfterLookup(Selected: RecordRef)
                begin
                    Log.Add('base afterLookup sel=' + Format(Selected.Field(1).Value) + ' rec=[' + Rec.Grp + ']');
                end;
            }
            field(DescrCtl; Rec.Descr) { ApplicationArea = All; }
            field(QtyCtl; Rec.Qty)
            {
                ApplicationArea = All;

                trigger OnDrillDown()
                begin
                    Log.Add('base drill qty=' + Format(Rec.Qty));
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P112 Pg Log";
}

pageextension 71865 "LT P112 Card Ext" extends "LT P112 Card"
{
    layout
    {
        addafter(DescrCtl)
        {
            field(GrpExtCtl; Rec.Grp)
            {
                ApplicationArea = All;

                trigger OnAfterLookup(Selected: RecordRef)
                begin
                    Log.Add('ext afterLookup sel=' + Format(Selected.Field(1).Value) + ' rec=[' + Rec.Grp + ']');
                end;
            }
            field(QtyExtCtl; Rec.Qty)
            {
                ApplicationArea = All;

                trigger OnDrillDown()
                begin
                    Log.Add('ext drill qty=' + Format(Rec.Qty));
                end;
            }
            field(DescrExtCtl; Rec.Descr)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                begin
                    Log.Add('ext lookup text=[' + Text + ']');
                    Text := 'extlooked';
                    exit(true);
                end;

                trigger OnAssistEdit()
                begin
                    Log.Add('ext assist descr=[' + Rec.Descr + ']');
                end;
            }
        }
    }

    var
        Log: Codeunit "LT P112 Pg Log";
}

codeunit 71866 "LT P112 Pg Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P112 Pg Log";

    local procedure Seed()
    var
        Grp: Record "LT P112 Group";
        Row: Record "LT P112 Card Row";
    begin
        Grp.DeleteAll();
        Row.DeleteAll();
        Grp.Code := 'A';
        Grp.Descr := 'Group A';
        Grp.Insert();
        Grp.Code := 'B';
        Grp.Descr := 'Group B';
        Grp.Insert();
        Row."No." := 'R1';
        Row.Descr := 'Row one';
        Row.Qty := 5;
        Row.Insert();
        Log.Take();
    end;

    [ModalPageHandler]
    procedure PickB(var P: TestPage "LT P112 Grp List")
    begin
        Log.Add('handler opened');
        P.GoToKey('B');
        P.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure CancelB(var P: TestPage "LT P112 Grp List")
    begin
        Log.Add('handler opened');
        P.GoToKey('B');
        P.Cancel().Invoke();
    end;

    [Test]
    [HandlerFunctions('PickB')]
    procedure P112_Lookup_BasePageField_OK()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.GrpCtl.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('base value', Card.GrpCtl.Value());
        Observer.Observe('ext value', Card.GrpExtCtl.Value());
        Card.Close();
        Observer.Expect('log', 'handler opened;base afterLookup sel=B rec=[];');
        Observer.Expect('base value', 'B');
        Observer.Expect('ext value', 'B');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickB')]
    procedure P112_Lookup_ExtensionField_OK()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.GrpExtCtl.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('base value', Card.GrpCtl.Value());
        Observer.Observe('ext value', Card.GrpExtCtl.Value());
        Card.Close();
        Observer.Expect('log', 'handler opened;ext afterLookup sel=B rec=[];');
        Observer.Expect('base value', 'B');
        Observer.Expect('ext value', 'B');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelB')]
    procedure P112_Lookup_ExtensionField_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.GrpExtCtl.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('ext value', Card.GrpExtCtl.Value());
        Card.Close();
        Observer.Expect('log', 'handler opened;');
        Observer.Expect('ext value', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('CancelB')]
    procedure P112_Lookup_BasePageField_Cancel()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.GrpCtl.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('base value', Card.GrpCtl.Value());
        Card.Close();
        Observer.Expect('log', 'handler opened;');
        Observer.Expect('base value', '');
        Observer.Verify();
    end;

    [Test]
    [HandlerFunctions('PickB')]
    procedure P112_Lookup_ViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('R1');
        Card.GrpExtCtl.Lookup();
        Observer.Observe('log', Log.Take());
        Observer.Observe('ext value', Card.GrpExtCtl.Value());
        Card.Close();
        Observer.Expect('log', 'handler opened;ext afterLookup sel=B rec=[];');
        Observer.Expect('ext value', 'B');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Drill_ExtensionField()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.QtyExtCtl.DrillDown();
        Observer.Observe('log ext', Log.Take());
        Card.QtyCtl.DrillDown();
        Observer.Observe('log base', Log.Take());
        Card.Close();
        Observer.Expect('log ext', 'ext drill qty=5;');
        Observer.Expect('log base', 'base drill qty=5;');
        Observer.Verify();
    end;

    [Test]
    procedure P112_Drill_ExtensionField_ViewMode()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenView();
        Card.GoToKey('R1');
        Card.QtyExtCtl.DrillDown();
        Observer.Observe('log', Log.Take());
        Card.Close();
        Observer.Expect('log', 'ext drill qty=5;');
        Observer.Verify();
    end;

    [Test]
    procedure P112_ExtensionField_LookupAndAssistEdit()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.DescrExtCtl.Lookup();
        Observer.Observe('log lookup', Log.Take());
        Observer.Observe('value after lookup', Card.DescrExtCtl.Value());
        Observer.Observe('base descr control', Card.DescrCtl.Value());
        Card.DescrExtCtl.AssistEdit();
        Observer.Observe('log assist', Log.Take());
        Card.DescrExtCtl.SetValue('typed');
        Card.DescrExtCtl.Lookup();
        Observer.Observe('log lookup typed', Log.Take());
        Card.Close();
        Observer.Expect('log lookup', 'ext lookup text=[Row one];');
        Observer.Expect('value after lookup', 'extlooked');
        Observer.Expect('base descr control', 'extlooked');
        Observer.Expect('log assist', 'ext assist descr=[extlooked];');
        Observer.Expect('log lookup typed', 'ext lookup text=[typed];');
        Observer.Verify();
    end;

    [Test]
    procedure P112_ExtensionField_DrillDown_NoTrigger_Controls()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P112 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.GoToKey('R1');
        Card.QtyExtCtl.SetValue(9);
        Card.QtyCtl.DrillDown();
        Observer.Observe('log', Log.Take());
        Observer.Observe('qty values', Card.QtyCtl.Value() + '/' + Card.QtyExtCtl.Value());
        Card.Close();
        Observer.Expect('log', 'base drill qty=9;');
        Observer.Expect('qty values', '9/9');
        Observer.Verify();
    end;
}
