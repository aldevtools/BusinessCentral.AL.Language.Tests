// Probe: Lookup and AssistEdit on TestPage controls. Table field OnLookup, control OnLookup, OnLookup of a modify block, both at once, controls with only a table relation (existing value, where clause, conditional relation, DrillDownPageId only, no page at all), AssistEdit with no trigger.
// Settles: md:263 (AssistEdit and Lookup with no trigger, OnLookup true, own trigger plus modify trigger), md:279 (table field OnLookup, control OnLookup text and write-back), md:280 (relation lookup with a value, where, conditional, DrillDownPageId, rollback after asserterror).

codeunit 68693 "W2 Lookup Log"
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

table 68682 "W2 Lookup Related"
{
    DataClassification = SystemMetadata;
    LookupPageId = "W2 Lookup Related List";

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 68684 "W2 Lookup Drill Related"
{
    DataClassification = SystemMetadata;
    DrillDownPageId = "W2 Lookup Drill List";

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 68686 "W2 Lookup Bare Related"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[20]) { }
        field(2; Descr; Text[30]) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

page 68683 "W2 Lookup Related List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Lookup Related";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

page 68685 "W2 Lookup Drill List"
{
    PageType = List;
    ApplicationArea = All;
    SourceTable = "W2 Lookup Drill Related";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Code; Rec.Code) { ApplicationArea = All; }
                field(Descr; Rec.Descr) { ApplicationArea = All; }
            }
        }
    }
}

table 68687 "W2 Lookup Host"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; "No."; Code[10]) { }
        field(2; RelCode; Code[20])
        {
            TableRelation = "W2 Lookup Related";
        }
        field(3; DrillCode; Code[20])
        {
            TableRelation = "W2 Lookup Drill Related";
        }
        field(4; BareCode; Code[20])
        {
            TableRelation = "W2 Lookup Bare Related";
        }
        field(5; WhereCode; Code[20])
        {
            TableRelation = "W2 Lookup Related" where(Descr = const('Wanted'));
        }
        field(6; CondCode; Code[20])
        {
            TableRelation = if (Kind = const(1)) "W2 Lookup Related" else
            if (Kind = const(2)) "W2 Lookup Drill Related";
        }
        field(7; Kind; Integer) { }
        field(8; OwnLookup; Code[20])
        {
            trigger OnLookup()
            var
                Log: Codeunit "W2 Lookup Log";
            begin
                Log.Add('table.OnLookup(' + OwnLookup + ')');
                OwnLookup := 'FromTable';
            end;

            trigger OnValidate()
            var
                Log: Codeunit "W2 Lookup Log";
            begin
                Log.Add('table.OwnLookup.OnValidate(' + OwnLookup + ')');
            end;
        }
        field(9; Plain; Code[20]) { }
        field(10; CtlTrue; Code[20]) { }
        field(11; CtlFalse; Code[20]) { }
        field(12; ModLookup; Code[20]) { }
        field(13; BothLookup; Code[20]) { }
        field(14; AssistOwn; Code[20]) { }
        field(15; CtlWithTableTrigger; Code[20])
        {
            trigger OnLookup()
            var
                Log: Codeunit "W2 Lookup Log";
            begin
                Log.Add('table.CtlWithTableTrigger.OnLookup');
                CtlWithTableTrigger := 'FromTable';
            end;
        }
    }

    keys
    {
        key(PK; "No.") { Clustered = true; }
    }
}

page 68688 "W2 Lookup Card"
{
    PageType = Card;
    ApplicationArea = All;
    SourceTable = "W2 Lookup Host";
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field("No."; Rec."No.") { ApplicationArea = All; }
            field(RelCode; Rec.RelCode) { ApplicationArea = All; }
            field(DrillCode; Rec.DrillCode) { ApplicationArea = All; }
            field(BareCode; Rec.BareCode) { ApplicationArea = All; }
            field(WhereCode; Rec.WhereCode) { ApplicationArea = All; }
            field(CondCode; Rec.CondCode) { ApplicationArea = All; }
            field(Kind; Rec.Kind) { ApplicationArea = All; }
            field(OwnLookup; Rec.OwnLookup) { ApplicationArea = All; }
            field(Plain; Rec.Plain) { ApplicationArea = All; }
            field(CtlTrue; Rec.CtlTrue)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('ctl.CtlTrue.OnLookup(text=' + Text + ')');
                    Text := 'FromCtl';
                    exit(true);
                end;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('page.CtlTrue.OnValidate(' + Rec.CtlTrue + ')');
                end;
            }
            field(CtlFalse; Rec.CtlFalse)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('ctl.CtlFalse.OnLookup(text=' + Text + ')');
                    Text := 'ShouldBeIgnored';
                    exit(false);
                end;

                trigger OnValidate()
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('page.CtlFalse.OnValidate(' + Rec.CtlFalse + ')');
                end;
            }
            field(ModLookup; Rec.ModLookup) { ApplicationArea = All; }
            field(BothLookup; Rec.BothLookup)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('base.BothLookup.OnLookup(text=' + Text + ')');
                    Text := 'FromBase';
                    exit(true);
                end;
            }
            field(AssistOwn; Rec.AssistOwn)
            {
                ApplicationArea = All;

                trigger OnAssistEdit()
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('page.AssistOwn.OnAssistEdit');
                end;
            }
            field(CtlWithTableTrigger; Rec.CtlWithTableTrigger)
            {
                ApplicationArea = All;

                trigger OnLookup(var Text: Text): Boolean
                var
                    Log: Codeunit "W2 Lookup Log";
                begin
                    Log.Add('ctl.CtlWithTableTrigger.OnLookup(text=' + Text + ')');
                    exit(false);
                end;
            }
        }
    }
}

pageextension 68689 "W2 Lookup Card Ext" extends "W2 Lookup Card"
{
    layout
    {
        modify(ModLookup)
        {
            trigger OnLookup(var Text: Text): Boolean
            var
                Log: Codeunit "W2 Lookup Log";
            begin
                Log.Add('ext.ModLookup.OnLookup(text=' + Text + ')');
                Text := 'FromExt';
                exit(true);
            end;
        }
        modify(BothLookup)
        {
            trigger OnLookup(var Text: Text): Boolean
            var
                Log: Codeunit "W2 Lookup Log";
            begin
                Log.Add('ext.BothLookup.OnLookup(text=' + Text + ')');
                Text := 'FromExt';
                exit(true);
            end;
        }
    }
}

codeunit 68692 "W2 Lookup Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        HandlerMode: Text;

    local procedure Seed()
    var
        Host: Record "W2 Lookup Host";
        Related: Record "W2 Lookup Related";
        Drill: Record "W2 Lookup Drill Related";
        Bare: Record "W2 Lookup Bare Related";
        Log: Codeunit "W2 Lookup Log";
    begin
        Host.DeleteAll();
        Related.DeleteAll();
        Drill.DeleteAll();
        Bare.DeleteAll();
        Related.Code := 'A';
        Related.Descr := 'Alpha';
        Related.Insert();
        Related.Code := 'B';
        Related.Descr := 'Wanted';
        Related.Insert();
        Related.Code := 'C';
        Related.Descr := 'Gamma';
        Related.Insert();
        Drill.Code := 'D1';
        Drill.Descr := 'Drill one';
        Drill.Insert();
        Drill.Code := 'D2';
        Drill.Descr := 'Drill two';
        Drill.Insert();
        Bare.Code := 'X1';
        Bare.Insert();
        Host."No." := 'H1';
        Host.Insert();
        Log.Take();
    end;

    local procedure OpenCard(var Pg: TestPage "W2 Lookup Card")
    var
        Host: Record "W2 Lookup Host";
    begin
        Host.Get('H1');
        Pg.OpenEdit();
        Pg.GoToRecord(Host);
    end;

    // ---- md:279 table field OnLookup ----

    [Test]
    procedure TableFieldOnLookup_EmptyField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Host: Record "W2 Lookup Host";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.OwnLookup.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.OwnLookup.Value());
        Pg.Close();
        Observer.Observe('close_log', Log.Take());
        Host.Get('H1');
        Observer.Observe('saved_after_close', Host.OwnLookup);
        Observer.Expect('lookup_log', 'table.OnLookup();');
        Observer.Expect('control_after', 'FROMTABLE');
        Observer.Expect('close_log', '');
        Observer.Expect('saved_after_close', 'FROMTABLE');
        Observer.Verify();
    end;

    [Test]
    procedure TableFieldOnLookup_FieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.OwnLookup.SetValue('typed');
        Observer.Observe('set_log', Log.Take());
        Pg.OwnLookup.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.OwnLookup.Value());
        Pg.Close();
        Observer.Expect('set_log', 'table.OwnLookup.OnValidate(TYPED);');
        Observer.Expect('lookup_log', 'table.OnLookup(TYPED);');
        Observer.Expect('control_after', 'FROMTABLE');
        Observer.Verify();
    end;

    // The page control has its own OnLookup returning false and the table field has a trigger: which one runs?
    [Test]
    procedure TableFieldOnLookup_ControlTriggerReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.CtlWithTableTrigger.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.CtlWithTableTrigger.Value());
        Pg.Close();
        Observer.Expect('lookup_log', 'ctl.CtlWithTableTrigger.OnLookup(text=);');
        Observer.Expect('control_after', '');
        Observer.Verify();
    end;

    // ---- md:279 / md:263 control OnLookup ----

    [Test]
    procedure ControlOnLookup_ReturnsTrue_EmptyField()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.CtlTrue.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.CtlTrue.Value());
        Pg.Close();
        Observer.Expect('lookup_log', 'ctl.CtlTrue.OnLookup(text=);page.CtlTrue.OnValidate(FROMCTL);');
        Observer.Expect('control_after', 'FROMCTL');
        Observer.Verify();
    end;

    [Test]
    procedure ControlOnLookup_ReturnsTrue_FieldWithValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Host: Record "W2 Lookup Host";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.CtlTrue.SetValue('typed');
        Observer.Observe('set_log', Log.Take());
        Pg.CtlTrue.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.CtlTrue.Value());
        Pg.Close();
        Host.Get('H1');
        Observer.Observe('saved_after_close', Host.CtlTrue);
        Observer.Expect('set_log', 'page.CtlTrue.OnValidate(TYPED);');
        Observer.Expect('lookup_log', 'ctl.CtlTrue.OnLookup(text=TYPED);page.CtlTrue.OnValidate(FROMCTL);');
        Observer.Expect('control_after', 'FROMCTL');
        Observer.Expect('saved_after_close', 'FROMCTL');
        Observer.Verify();
    end;

    [Test]
    procedure ControlOnLookup_ReturnsFalse()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.CtlFalse.SetValue('typed');
        Observer.Observe('set_log', Log.Take());
        Pg.CtlFalse.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.CtlFalse.Value());
        Pg.Close();
        Observer.Expect('set_log', 'page.CtlFalse.OnValidate(TYPED);');
        Observer.Expect('lookup_log', 'ctl.CtlFalse.OnLookup(text=TYPED);');
        Observer.Expect('control_after', 'TYPED');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyBlockOnLookup_ReturnsTrue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
    begin
        Seed();
        OpenCard(Pg);
        Pg.ModLookup.SetValue('typed');
        Log.Take();
        Pg.ModLookup.Lookup();
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.ModLookup.Value());
        Pg.Close();
        Observer.Expect('lookup_log', 'ext.ModLookup.OnLookup(text=TYPED);');
        Observer.Expect('control_after', 'FromExt');
        Observer.Verify();
    end;

    [Test]
    procedure OwnTriggerAndModifyBlockOnLookup()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
        Ok: Boolean;
    begin
        Seed();
        OpenCard(Pg);
        Pg.BothLookup.SetValue('typed');
        Log.Take();
        Ok := LookupBoth(Pg);
        Observer.Observe('lookup|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('lookup');
        Observer.Observe('lookup_log', Log.Take());
        Observer.Observe('control_after', Pg.BothLookup.Value());
        Pg.Close();
        Observer.Expect('lookup|ok', 'Yes');
        Observer.Expect('lookup_log', 'ext.BothLookup.OnLookup(text=TYPED);');
        Observer.Expect('control_after', 'FromExt');
        Observer.Verify();
    end;

    // ---- md:263 AssistEdit ----

    [Test]
    procedure AssistEdit_NoTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "W2 Lookup Log";
        Pg: TestPage "W2 Lookup Card";
        Ok: Boolean;
    begin
        Seed();
        OpenCard(Pg);
        Pg.Plain.SetValue('keep');
        Ok := AssistPlain(Pg);
        Observer.Observe('plain|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('plain');
        Observer.Observe('plain|value', Pg.Plain.Value());
        Ok := AssistOwn(Pg);
        Observer.Observe('own|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('own');
        Observer.Observe('own|log', Log.Take());
        Pg.Close();
        Observer.Expect('plain|ok', 'No');
        Observer.Expect('plain|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('plain|code', 'MethodNotSupported');
        Observer.Expect('plain|value', 'KEEP');
        Observer.Expect('own|ok', 'Yes');
        Observer.Expect('own|log', 'page.AssistOwn.OnAssistEdit;');
        Observer.Verify();
    end;

    [Test]
    procedure AssistEdit_OnRelationField()
    var
        Observer: Codeunit "Probe Observer";
        Pg: TestPage "W2 Lookup Card";
        Ok: Boolean;
    begin
        Seed();
        OpenCard(Pg);
        Ok := AssistRelation(Pg);
        Observer.Observe('relation|ok', Format(Ok));
        if not Ok then
            Observer.ObserveError('relation');
        Observer.Observe('relation|value', Pg.RelCode.Value());
        Pg.Close();
        Observer.Expect('relation|ok', 'No');
        Observer.Expect('relation|text', 'The NavAssistEditAction method is not supported.');
        Observer.Expect('relation|code', 'MethodNotSupported');
        Observer.Expect('relation|value', '');
        Observer.Verify();
    end;

    // ---- md:280 relation lookups ----

    // No LookupPageId, no DrillDownPageId. Seeds were written in this test and never committed: how much of them survives the asserterror?
    [ModalPageHandler]
    procedure RelatedHandler(var Pg: TestPage "W2 Lookup Related List")
    var
        Log: Codeunit "W2 Lookup Log";
        Rows: Text;
    begin
        Log.Add('RelatedList(current=' + Pg.Code.Value() + ')');
        if HandlerMode = 'WALK' then begin
            if Pg.First() then
                repeat
                    Rows += Pg.Code.Value() + ',';
                until not Pg.Next();
            Log.Add('rows=' + Rows);
                exit;
        end;
        Pg.OK().Invoke();
    end;

    [ModalPageHandler]
    procedure DrillHandler(var Pg: TestPage "W2 Lookup Drill List")
    var
        Log: Codeunit "W2 Lookup Log";
    begin
        Log.Add('DrillList(current=' + Pg.Code.Value() + ')');
        Pg.OK().Invoke();
    end;

    [TryFunction]
    local procedure SetRel(var Pg: TestPage "W2 Lookup Card"; Input: Text)
    begin
        Pg.RelCode.SetValue(Input);
    end;

    [TryFunction]
    local procedure LookupBoth(var Pg: TestPage "W2 Lookup Card")
    begin
        Pg.BothLookup.Lookup();
    end;

    [TryFunction]
    local procedure LookupCond(var Pg: TestPage "W2 Lookup Card")
    begin
        Pg.CondCode.Lookup();
    end;

    [TryFunction]
    local procedure AssistPlain(var Pg: TestPage "W2 Lookup Card")
    begin
        Pg.Plain.AssistEdit();
    end;

    [TryFunction]
    local procedure AssistOwn(var Pg: TestPage "W2 Lookup Card")
    begin
        Pg.AssistOwn.AssistEdit();
    end;

    [TryFunction]
    local procedure AssistRelation(var Pg: TestPage "W2 Lookup Card")
    begin
        Pg.RelCode.AssistEdit();
    end;
}
