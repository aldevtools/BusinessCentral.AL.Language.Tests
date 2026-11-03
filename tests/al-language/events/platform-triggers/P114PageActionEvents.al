// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-events-in-al
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained: table 74229, SingleInstance log 74230 (used only by test codeunit 74233), subscribers 74231, page 74232
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Facts: OnBeforeActionEvent / OnAfterActionEvent subscribers of a page action around the action's OnAction trigger when a TestPage invokes it; OnBeforeValidateEvent /
// OnAfterValidateEvent of a page control against the page control OnValidate trigger and the table field events and trigger when TestPage SetValue runs; the
// page level OnDeleteRecordEvent when a page action deletes the record.

table 74229 "LT P114 Row"
{
    DataClassification = CustomerContent;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P114 Log";
            begin
                Log.Add('table-Name-OnValidate:' + Name);
                if Name = 'FAIL' then
                    Error('P114 name failed');
            end;
        }
        field(3; Qty; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P114 Log";
            begin
                Log.Add('table-Qty-OnValidate:' + Format(Qty));
            end;
        }
        field(4; Tag; Code[10])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P114 Log";
            begin
                Log.Add('table-Tag-OnValidate:' + Tag);
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnModify()
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('table-OnModify:' + Format(Id));
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('table-OnDelete:' + Format(Id));
    end;
}

codeunit 74230 "LT P114 Log"
{
    SingleInstance = true;

    var
        Lines: List of [Text];

    procedure Reset()
    begin
        Clear(Lines);
    end;

    procedure Add(Line: Text)
    begin
        Lines.Add(Line);
    end;

    procedure Count(): Integer
    begin
        exit(Lines.Count());
    end;

    procedure Dump(): Text
    var
        Line: Text;
        Result: Text;
    begin
        foreach Line in Lines do begin
            if Result <> '' then
                Result += ' | ';
            Result += Line;
        end;
        exit('[' + Result + ']');
    end;
}

codeunit 74231 "LT P114 Subs"
{
    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeActionEvent', 'Plain', false, false)]
    local procedure BeforePlain(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('before-Plain:' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterActionEvent', 'Plain', false, false)]
    local procedure AfterPlain(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('after-Plain:' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeActionEvent', 'Modifier', false, false)]
    local procedure BeforeModifier(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('before-Modifier:' + Rec.Name);
        Rec.Name := 'FromBefore';
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterActionEvent', 'Modifier', false, false)]
    local procedure AfterModifier(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('after-Modifier:' + Rec.Name);
    end;

    // No parameters at all.
    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeActionEvent', 'Failing', false, false)]
    local procedure BeforeFailing()
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('before-Failing');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterActionEvent', 'Failing', false, false)]
    local procedure AfterFailing()
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('after-Failing');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeActionEvent', 'Deleter', false, false)]
    local procedure BeforeDeleter(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('before-Deleter:' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterActionEvent', 'Deleter', false, false)]
    local procedure AfterDeleter(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('after-Deleter:' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnDeleteRecordEvent', '', false, false)]
    local procedure PageDeleteRecord(var Rec: Record "LT P114 Row"; var AllowDelete: Boolean)
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-DeleteRecordEvent:' + Format(Rec.Id));
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeValidateEvent', 'NameCtl', false, false)]
    local procedure PageNameBefore(var Rec: Record "LT P114 Row"; var xRec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Name-before(rec=' + Rec.Name + ',x=' + xRec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterValidateEvent', 'NameCtl', false, false)]
    local procedure PageNameAfter(var Rec: Record "LT P114 Row"; var xRec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Name-after(rec=' + Rec.Name + ',x=' + xRec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeValidateEvent', 'QtyCtl', false, false)]
    local procedure PageQtyBefore(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Qty-before(rec=' + Format(Rec.Qty) + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterValidateEvent', 'QtyCtl', false, false)]
    local procedure PageQtyAfter(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Qty-after(rec=' + Format(Rec.Qty) + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnBeforeValidateEvent', 'TagCtl', false, false)]
    local procedure PageTagBefore(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Tag-before(rec=' + Rec.Tag + ')');
    end;

    [EventSubscriber(ObjectType::Page, Page::"LT P114 Card", 'OnAfterValidateEvent', 'TagCtl', false, false)]
    local procedure PageTagAfter(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-Tag-after(rec=' + Rec.Tag + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P114 Row", 'OnBeforeValidateEvent', 'Name', false, false)]
    local procedure TableNameBefore(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('table-Name-before(rec=' + Rec.Name + ')');
    end;

    [EventSubscriber(ObjectType::Table, Database::"LT P114 Row", 'OnAfterValidateEvent', 'Name', false, false)]
    local procedure TableNameAfter(var Rec: Record "LT P114 Row")
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('table-Name-after(rec=' + Rec.Name + ')');
    end;
}

page 74232 "LT P114 Card"
{
    PageType = Card;
    SourceTable = "LT P114 Row";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(IdCtl; Rec.Id) { ApplicationArea = All; }
            field(NameCtl; Rec.Name)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('page-Name-OnValidate:' + Rec.Name);
                end;
            }
            field(QtyCtl; Rec.Qty)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('page-Qty-OnValidate:' + Format(Rec.Qty));
                end;
            }
            field(TagCtl; Rec.Tag)
            {
                ApplicationArea = All;

                trigger OnValidate()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('page-Tag-OnValidate:' + Rec.Tag);
                end;
            }
        }
    }

    actions
    {
        area(Processing)
        {
            action(Plain)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('OnAction-Plain:' + Format(Rec.Id));
                end;
            }
            action(Modifier)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('OnAction-Modifier:' + Rec.Name);
                end;
            }
            action(Failing)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('OnAction-Failing');
                    Error('P114 action failed');
                end;
            }
            action(Deleter)
            {
                ApplicationArea = All;

                trigger OnAction()
                var
                    Log: Codeunit "LT P114 Log";
                begin
                    Log.Add('OnAction-Deleter');
                    Rec.Delete(true);
                end;
            }
        }
    }

    trigger OnDeleteRecord(): Boolean
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-OnDeleteRecord:' + Format(Rec.Id));
        exit(true);
    end;

    trigger OnModifyRecord(): Boolean
    var
        Log: Codeunit "LT P114 Log";
    begin
        Log.Add('page-OnModifyRecord:' + Format(Rec.Id));
        exit(true);
    end;
}

codeunit 74233 "LT P114 Page Events"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P114 Row";
        Log: Codeunit "LT P114 Log";
    begin
        Row.DeleteAll(false);
        Row.Id := 1;
        Row.Name := 'one';
        Row.Qty := 1;
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'two';
        Row.Qty := 2;
        Row.Insert();
        Log.Reset();
    end;

    [Test]
    procedure P114_ActionOrder()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.Plain.Invoke();
        Observer.Observe('log-count', Format(Log.Count()));
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('log-count', '3');
        Observer.Expect('log', '[before-Plain:1 | OnAction-Plain:1 | after-Plain:1]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ActionTwiceOnTwoRows()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Card.Plain.Invoke();
        Observer.Observe('first', Log.Dump());
        Log.Reset();
        Card.Next();
        Card.Plain.Invoke();
        Observer.Observe('second', Log.Dump());
        Card.Close();
        Observer.Expect('first', '[before-Plain:1 | OnAction-Plain:1 | after-Plain:1]');
        Observer.Expect('second', '[before-Plain:2 | OnAction-Plain:2 | after-Plain:2]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_BeforeEventChangesRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Row: Record "LT P114 Row";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.Modifier.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('page-name-after', Card.NameCtl.Value());
        Row.Get(1);
        Observer.Observe('stored-name', Row.Name);
        Card.Close();
        Observer.Expect('log', '[before-Modifier:one | OnAction-Modifier:FromBefore | after-Modifier:FromBefore | page-OnModifyRecord:1 | table-OnModify:1]');
        Observer.Expect('page-name-after', 'FromBefore');
        Observer.Expect('stored-name', 'FromBefore');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ActionRaisesError()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        asserterror Card.Failing.Invoke();
        Observer.ObserveError('failing');
        Observer.Observe('log', Log.Dump());
        Observer.Expect('failing|text', 'P114 action failed');
        Observer.Expect('failing|code', 'TestWrapped:Dialog');
        Observer.Expect('log', '[before-Failing | OnAction-Failing]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ActionDeletesRecord()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Row: Record "LT P114 Row";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.Deleter.Invoke();
        Observer.Observe('log', Log.Dump());
        Observer.Observe('rows', Format(Row.Count()));
        asserterror Card.Close();
        Observer.ObserveError('af476');
        Observer.Expect('log', '[before-Deleter:1 | OnAction-Deleter | table-OnDelete:1 | after-Deleter:1]');
        Observer.Expect('rows', '1');
        Observer.Expect('af476|text', 'The TestPage is not open.');
        Observer.Expect('af476|code', 'TestPageNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ValidateOrderText()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Row: Record "LT P114 Row";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.NameCtl.SetValue('changed');
        Observer.Observe('after-setvalue', Log.Dump());
        Card.Close();
        Observer.Observe('after-close', Log.Dump());
        Row.Get(1);
        Observer.Observe('stored', Row.Name);
        Observer.Expect('after-setvalue', '[table-Name-before(rec=changed) | table-Name-OnValidate:changed | table-Name-after(rec=changed) | page-Name-before(rec=changed,x=one) | page-Name-OnValidate:changed | page-Name-after(rec=changed,x=one)]');
        Observer.Expect('after-close', '[table-Name-before(rec=changed) | table-Name-OnValidate:changed | table-Name-after(rec=changed) | page-Name-before(rec=changed,x=one) | page-Name-OnValidate:changed | page-Name-after(rec=changed,x=one) | page-OnModifyRecord:1 | table-OnModify:1]');
        Observer.Expect('stored', 'changed');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ValidateOrderInteger()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.QtyCtl.SetValue(42);
        Observer.Observe('after-setvalue', Log.Dump());
        Card.Close();
        Observer.Expect('after-setvalue', '[table-Qty-OnValidate:42 | page-Qty-before(rec=42) | page-Qty-OnValidate:42 | page-Qty-after(rec=42)]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ValidateOrderCode()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.TagCtl.SetValue('abc');
        Observer.Observe('after-setvalue', Log.Dump());
        Observer.Observe('page-value', Card.TagCtl.Value());
        Card.Close();
        Observer.Expect('after-setvalue', '[table-Tag-OnValidate:ABC | page-Tag-before(rec=ABC) | page-Tag-OnValidate:ABC | page-Tag-after(rec=ABC)]');
        Observer.Expect('page-value', 'ABC');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ValidateSameValue()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        Card.NameCtl.SetValue('one');
        Observer.Observe('same-value', Log.Dump());
        Card.Close();
        Observer.Expect('same-value', '[table-Name-before(rec=one) | table-Name-OnValidate:one | table-Name-after(rec=one) | page-Name-before(rec=one,x=one) | page-Name-OnValidate:one | page-Name-after(rec=one,x=one)]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_ValidateTriggerRaises()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenEdit();
        Card.First();
        Log.Reset();
        asserterror Card.NameCtl.SetValue('FAIL');
        Observer.ObserveError('validate');
        Observer.Observe('log', Log.Dump());
        Observer.Expect('validate|text', 'Validation error for Field: NameCtl,  Message = ''P114 name failed (Select Refresh to discard errors)''');
        Observer.Expect('validate|code', 'TestValidation');
        Observer.Expect('log', '[table-Name-before(rec=FAIL) | table-Name-OnValidate:FAIL]');
        Observer.Verify();
    end;

    [Test]
    procedure P114_NewRecordValidate()
    var
        Observer: Codeunit "Probe Observer";
        Log: Codeunit "LT P114 Log";
        Row: Record "LT P114 Row";
        Card: TestPage "LT P114 Card";
    begin
        Seed();
        Card.OpenNew();
        Log.Reset();
        Card.IdCtl.SetValue(7);
        Card.NameCtl.SetValue('seven');
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Observe('row7', Format(Row.Get(7)));
        Observer.Expect('log', '[table-Name-before(rec=seven) | table-Name-OnValidate:seven | table-Name-after(rec=seven) | page-Name-before(rec=seven,x=) | page-Name-OnValidate:seven | page-Name-after(rec=seven,x=)]');
        Observer.Expect('row7', 'Yes');
        Observer.Verify();
    end;
}
