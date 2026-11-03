// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-table-ext-object
// Scope: in-scope
// Fixtures used: Probe Observer (69160); LT P163 VH Log (73234, SingleInstance, used by LT P163 Validate Ext only)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)
// Known pin for one extension: record/TestTriggerDispatchOrder.al:TriggerOrder_Validate_FieldPipeline_IsStable

codeunit 73234 "LT P163 VH Log"
{
    SingleInstance = true;

    var
        Txt: Text;

    procedure Add(Entry: Text)
    begin
        if Txt <> '' then
            Txt += ';';
        Txt += Entry;
    end;

    procedure Get(): Text
    begin
        exit(Txt);
    end;

    procedure Reset()
    begin
        Txt := '';
    end;
}

table 73327 "LT P163 VH"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Watched; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT P163 VH Log";
            begin
                Log.Add('base-onvalidate:' + xRec.Watched + '>' + Rec.Watched);
            end;
        }
        field(3; Other; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT P163 VH Log";
    begin
        Log.Add('base-oninsert');
    end;
}

tableextension 73328 "LT P163 VH Ext A" extends "LT P163 VH"
{
    fields
    {
        modify(Watched)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "LT P163 VH Log";
            begin
                Log.Add('extA-before:' + xRec.Watched + '>' + Rec.Watched);
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "LT P163 VH Log";
            begin
                Log.Add('extA-after:' + xRec.Watched + '>' + Rec.Watched);
            end;
        }
    }
}

tableextension 73329 "LT P163 VH Ext B" extends "LT P163 VH"
{
    fields
    {
        modify(Watched)
        {
            trigger OnBeforeValidate()
            var
                Log: Codeunit "LT P163 VH Log";
            begin
                Log.Add('extB-before:' + xRec.Watched + '>' + Rec.Watched);
            end;

            trigger OnAfterValidate()
            var
                Log: Codeunit "LT P163 VH Log";
            begin
                Log.Add('extB-after:' + xRec.Watched + '>' + Rec.Watched);
            end;
        }
    }
}

page 73235 "LT P163 VH Card"
{
    PageType = Card;
    SourceTable = "LT P163 VH";
    ApplicationArea = All;
    UsageCategory = None;

    layout
    {
        area(Content)
        {
            field(CodeFld; Rec.Code) { ApplicationArea = All; }
            field(Watched; Rec.Watched) { ApplicationArea = All; }
            field(Other; Rec.Other) { ApplicationArea = All; }
        }
    }
}

codeunit 73236 "LT P163 Validate Ext"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P163 VH Log";

    local procedure Seed(var R: Record "LT P163 VH")
    begin
        R.DeleteAll(false);
        R.Init();
        R.Code := 'A';
        R.Watched := 'old';
        R.Insert(false);
        Log.Reset();
    end;

    [Test]
    procedure P163_Validate_TwoExtensionsOnOneField_Order()
    var
        R: Record "LT P163 VH";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.Get('A');
        R.Validate(Watched, 'new');
        Observer.Observe('validate', Log.Get());
        Observer.Observe('value_after', R.Watched);
        Log.Reset();
        R.Validate(Watched, 'new');
        Observer.Observe('validate_same_value', Log.Get());
        Log.Reset();
        R.Validate(Watched, '');
        Observer.Observe('validate_blank', Log.Get());
        Observer.Expect('validate', 'extA-before:old>new;extB-before:old>new;base-onvalidate:old>new;extA-after:old>new;extB-after:old>new');
        Observer.Expect('value_after', 'new');
        Observer.Expect('validate_same_value', 'extA-before:new>new;extB-before:new>new;base-onvalidate:new>new;extA-after:new>new;extB-after:new>new');
        Observer.Expect('validate_blank', 'extA-before:new>;extB-before:new>;base-onvalidate:new>;extA-after:new>;extB-after:new>');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Validate_PlainAssignment_AndInsertRunTrigger()
    var
        R: Record "LT P163 VH";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.Get('A');
        R.Watched := 'assigned';
        Observer.Observe('assignment', Log.Get());
        R.Modify(true);
        Observer.Observe('modify_true', Log.Get());
        R.Init();
        R.Code := 'B';
        R.Watched := 'second';
        R.Insert(true);
        Observer.Observe('insert_true_with_value', Log.Get());
        Log.Reset();
        R.Init();
        R.Code := 'C';
        R.Validate(Watched, 'third');
        R.Insert(true);
        Observer.Observe('validate_then_insert', Log.Get());
        Observer.Expect('assignment', '');
        Observer.Expect('modify_true', '');
        Observer.Expect('insert_true_with_value', 'base-oninsert');
        Observer.Expect('validate_then_insert', 'extA-before:>third;extB-before:>third;base-onvalidate:>third;extA-after:>third;extB-after:>third;base-oninsert');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Validate_ModifyAll_AndTransferFields()
    var
        R: Record "LT P163 VH";
        Other: Record "LT P163 VH";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.ModifyAll(Watched, 'bulk', false);
        Observer.Observe('modifyall_runtrigger_false', Log.Get());
        R.ModifyAll(Watched, 'bulk2', true);
        Observer.Observe('modifyall_runtrigger_true', Log.Get());
        Log.Reset();
        Other.TransferFields(R, false);
        Observer.Observe('transferfields', Log.Get());
        Observer.Expect('modifyall_runtrigger_false', '');
        Observer.Expect('modifyall_runtrigger_true', '');
        Observer.Expect('transferfields', '');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Validate_ThroughATestPageEdit()
    var
        R: Record "LT P163 VH";
        Card: TestPage "LT P163 VH Card";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        Card.OpenEdit();
        Card.GoToKey('A');
        Log.Reset();
        Card.Watched.SetValue('edited');
        Observer.Observe('page_edit', Log.Get());
        Card.Close();
        R.Get('A');
        Observer.Observe('stored', R.Watched);
        Observer.Expect('page_edit', 'extA-before:old>edited;extB-before:old>edited;base-onvalidate:old>edited;extA-after:old>edited;extB-after:old>edited');
        Observer.Expect('stored', 'edited');
        Observer.Verify();
    end;

    [Test]
    procedure P163_Validate_OtherFieldDoesNotFireWatchedTriggers()
    var
        R: Record "LT P163 VH";
        Observer: Codeunit "Probe Observer";
    begin
        Seed(R);
        R.Get('A');
        R.Validate(Other, 5);
        Observer.Observe('validate_other', Log.Get());
        Observer.Expect('validate_other', '');
        Observer.Verify();
    end;
}
