// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Record.IsDirty() (BC 29 and later; BC 27 and 28 reject it, see must-not-compile case 0960). Settles #626 item 8.
// BC versions: 29

#if BC29PLUS
table 77504 "LT AC Dirty Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 77504 "LT AC Record Is Dirty"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure AC_IsDirty_Lifecycle()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Dirty Row";
        Other: Record "LT AC Dirty Row";
    begin
        Row.DeleteAll();
        Observer.Observe('fresh', Format(Row.IsDirty()));
        Row.Init();
        Observer.Observe('after_init', Format(Row.IsDirty()));
        Row.Id := 1;
        Row.Name := 'one';
        Observer.Observe('after_assign_before_insert', Format(Row.IsDirty()));
        Row.Insert();
        Observer.Observe('after_insert', Format(Row.IsDirty()));
        Row.Get(1);
        Observer.Observe('after_get', Format(Row.IsDirty()));
        Row.Name := 'changed';
        Observer.Observe('after_assign', Format(Row.IsDirty()));
        Row.Modify();
        Observer.Observe('after_modify', Format(Row.IsDirty()));
        Row.Name := 'changed';
        Observer.Observe('after_same_value', Format(Row.IsDirty()));
        Row.Name := 'again';
        Row.Name := 'changed';
        Observer.Observe('after_value_restored', Format(Row.IsDirty()));
        Row.Amount := 5;
        Observer.Observe('after_second_field', Format(Row.IsDirty()));
        Row.Get(1);
        Observer.Observe('after_get_again', Format(Row.IsDirty()));
        Row.Validate(Name, 'validated');
        Observer.Observe('after_validate', Format(Row.IsDirty()));
        Other := Row;
        Observer.Observe('copy_dirty', Format(Other.IsDirty()));
        Row.Get(1);
        Other.Init();
        Other.TransferFields(Row);
        Observer.Observe('after_transferfields', Format(Other.IsDirty()));
        Row.Get(1);
        Row.Delete();
        Observer.Observe('after_delete', Format(Row.IsDirty()));
        Observer.Expect('fresh', 'No');
        Observer.Expect('after_init', 'No');
        Observer.Expect('after_assign_before_insert', 'Yes');
        Observer.Expect('after_insert', 'No');
        Observer.Expect('after_get', 'No');
        Observer.Expect('after_assign', 'Yes');
        Observer.Expect('after_modify', 'No');
        Observer.Expect('after_same_value', 'No');
        Observer.Expect('after_value_restored', 'No');
        Observer.Expect('after_second_field', 'Yes');
        Observer.Expect('after_get_again', 'No');
        Observer.Expect('after_validate', 'Yes');
        Observer.Expect('copy_dirty', 'Yes');
        Observer.Expect('after_transferfields', 'No');
        Observer.Expect('after_delete', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure AC_IsDirty_FindAndRename()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Dirty Row";
    begin
        Row.DeleteAll();
        Row.Id := 1;
        Row.Name := 'a';
        Row.Insert();
        Row.Id := 2;
        Row.Name := 'b';
        Row.Insert();
        Row.FindFirst();
        Observer.Observe('after_findfirst', Format(Row.IsDirty()));
        Row.Name := 'x';
        Observer.Observe('assigned', Format(Row.IsDirty()));
        Row.FindLast();
        Observer.Observe('after_findlast', Format(Row.IsDirty()));
        Row.Rename(3);
        Observer.Observe('after_rename', Format(Row.IsDirty()));
        Row.Name := 'y';
        Row.Reset();
        Observer.Observe('after_reset', Format(Row.IsDirty()));
        Row.Init();
        Observer.Observe('after_init_again', Format(Row.IsDirty()));
        Observer.Expect('after_findfirst', 'No');
        Observer.Expect('assigned', 'Yes');
        Observer.Expect('after_findlast', 'No');
        Observer.Expect('after_rename', 'No');
        Observer.Expect('after_reset', 'Yes');
        Observer.Expect('after_init_again', 'Yes');
        Observer.Verify();
    end;

    // ---- writer PY-D (2026-10-20): IsDirty in the shapes the runtime refuses (objects 85230-85233 below) ----

    local procedure PydSeed()
    var
        T: Record "LT PYD Dirty Trg";
        Log: Codeunit "LT PYD Dirty Log";
    begin
        T.DeleteAll();
        T.Id := 1;
        T.Name := 'a';
        T.Insert();
        T.Id := 2;
        T.Name := 'b';
        T.Insert();
        Log.Reset();
    end;

    [Test]
    procedure PYD_IsDirty_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT AC Dirty Row" temporary;
        Other: Record "LT AC Dirty Row" temporary;
    begin
        Observer.Observe('fresh', Format(Row.IsDirty()));
        Row.Init();
        Observer.Observe('after_init', Format(Row.IsDirty()));
        Row.Id := 1;
        Row.Name := 'one';
        Observer.Observe('after_assign_before_insert', Format(Row.IsDirty()));
        Row.Insert();
        Observer.Observe('after_insert', Format(Row.IsDirty()));
        Row.Get(1);
        Observer.Observe('after_get', Format(Row.IsDirty()));
        Row.Name := 'changed';
        Observer.Observe('after_assign', Format(Row.IsDirty()));
        Row.Modify();
        Observer.Observe('after_modify', Format(Row.IsDirty()));
        Row.Name := 'again';
        Row.Name := 'changed';
        Observer.Observe('after_value_restored', Format(Row.IsDirty()));
        Row.Validate(Name, 'validated');
        Observer.Observe('after_validate', Format(Row.IsDirty()));
        Other := Row;
        Observer.Observe('copy_dirty', Format(Other.IsDirty()));
        Row.FindFirst();
        Observer.Observe('after_findfirst', Format(Row.IsDirty()));
        Row.Name := 'x';
        Row.Delete();
        Observer.Observe('after_delete_changed', Format(Row.IsDirty()));
        Observer.Expect('fresh', 'No');
        Observer.Expect('after_init', 'No');
        Observer.Expect('after_assign_before_insert', 'Yes');
        Observer.Expect('after_insert', 'No');
        Observer.Expect('after_get', 'No');
        Observer.Expect('after_assign', 'Yes');
        Observer.Expect('after_modify', 'No');
        Observer.Expect('after_value_restored', 'No');
        Observer.Expect('after_validate', 'Yes');
        Observer.Expect('copy_dirty', 'Yes');
        Observer.Expect('after_findfirst', 'No');
        Observer.Expect('after_delete_changed', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_FindSetNextFindMinus()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
    begin
        PydSeed();
        T.FindSet();
        Observer.Observe('after_findset', Format(T.IsDirty()));
        T.Name := 'x';
        Observer.Observe('changed', Format(T.IsDirty()));
        T.Next();
        Observer.Observe('after_next', Format(T.IsDirty()));
        T.Name := 'y';
        Observer.Observe('next_changed', Format(T.IsDirty()));
        Observer.Observe('next_at_end', Format(T.Next()));
        Observer.Observe('after_next_end', Format(T.IsDirty()));
        T.Find('-');
        Observer.Observe('after_find_minus', Format(T.IsDirty()));
        T.Name := 'z';
        T.Find('=');
        Observer.Observe('after_find_eq', Format(T.IsDirty()));
        T.Name := 'z';
        T.Find('+');
        Observer.Observe('after_find_plus', Format(T.IsDirty()));
        T.Name := 'w';
        T.Next(-1);
        Observer.Observe('after_next_back', Format(T.IsDirty()));
        Observer.Expect('after_findset', 'No');
        Observer.Expect('changed', 'Yes');
        Observer.Expect('after_next', 'No');
        Observer.Expect('next_changed', 'Yes');
        Observer.Expect('next_at_end', '0');
        Observer.Expect('after_next_end', 'Yes');
        Observer.Expect('after_find_minus', 'No');
        Observer.Expect('after_find_eq', 'No');
        Observer.Expect('after_find_plus', 'No');
        Observer.Expect('after_next_back', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_WritesWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        Log: Codeunit "LT PYD Dirty Log";
    begin
        PydSeed();
        T.Init();
        T.Id := 3;
        T.Insert(true);
        Observer.Observe('after_insert_true', Format(T.IsDirty()) + ' stamp=' + T.Stamp);
        T.Name := 'm';
        T.Modify(true);
        Observer.Observe('after_modify_true', Format(T.IsDirty()) + ' stamp=' + T.Stamp);
        T.Rename(4);
        Observer.Observe('after_rename', Format(T.IsDirty()) + ' stamp=' + T.Stamp);
        T.Name := 'd';
        T.Delete(true);
        Observer.Observe('after_delete_true', Format(T.IsDirty()) + ' stamp=' + T.Stamp);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('after_insert_true', 'No stamp=ins');
        Observer.Expect('after_modify_true', 'No stamp=mod');
        Observer.Expect('after_rename', 'No stamp=ren');
        Observer.Expect('after_delete_true', 'Yes stamp=del');
        Observer.Expect('log', '[OnInsert dirty=Yes][OnInsert after stamp dirty=Yes][OnModify dirty=Yes xRec dirty=Yes xRec.Name=m][OnRename dirty=Yes xRec dirty=No][OnDelete dirty=Yes]');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_WriteWithSubscriber()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        Sub: Codeunit "LT PYD Dirty Sub";
        Log: Codeunit "LT PYD Dirty Log";
    begin
        PydSeed();
        BindSubscription(Sub);
        T.Get(1);
        T.Name := 's';
        T.Modify();
        Observer.Observe('after_modify_sub', Format(T.IsDirty()) + ' big=' + T.Big);
        T.Get(2);
        T.Name := 's2';
        T.Modify(true);
        Observer.Observe('after_modify_true_sub', Format(T.IsDirty()) + ' big=' + T.Big + ' stamp=' + T.Stamp);
        UnbindSubscription(Sub);
        Observer.Observe('log', Log.Dump());
        Observer.Expect('after_modify_sub', 'No big=sub');
        Observer.Expect('after_modify_true_sub', 'No big=sub stamp=mod');
        Observer.Expect('log', '[sub OnBeforeModify dirty=Yes][sub OnBeforeModify dirty=Yes][OnModify dirty=Yes xRec dirty=Yes xRec.Name=s2]');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_CopyClearCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        U: Record "LT PYD Dirty Trg";
    begin
        PydSeed();
        T.Get(1);
        T.Name := 'x';
        U.Copy(T);
        Observer.Observe('copy_of_dirty', Format(U.IsDirty()));
        U.Get(2);
        T.Copy(U);
        Observer.Observe('copy_of_clean_into_dirty', Format(T.IsDirty()));
        T.Get(1);
        T.Name := 'x';
        Clear(T);
        Observer.Observe('after_clear', Format(T.IsDirty()));
        T.Get(1);
        T.CalcFields(Cnt);
        Observer.Observe('after_calcfields', Format(T.IsDirty()));
        T.Name := 'x';
        T.CalcFields(Cnt);
        Observer.Observe('changed_then_calcfields', Format(T.IsDirty()));
        Observer.Expect('copy_of_dirty', 'Yes');
        Observer.Expect('copy_of_clean_into_dirty', 'No');
        Observer.Expect('after_clear', 'No');
        Observer.Expect('after_calcfields', 'No');
        Observer.Expect('changed_then_calcfields', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_GetBySystemIdSetPositionChangeCompany()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        U: Record "LT PYD Dirty Trg";
        Pos: Text;
    begin
        PydSeed();
        U.Get(2);
        T.Get(1);
        T.Name := 'x';
        T.GetBySystemId(U.SystemId);
        Observer.Observe('after_getbysystemid', Format(T.IsDirty()));
        Pos := U.GetPosition();
        T.Get(1);
        T.SetPosition(Pos);
        Observer.Observe('after_setposition', Format(T.IsDirty()) + ' id=' + Format(T.Id) + ' name=' + T.Name);
        T.Get(1);
        T.ChangeCompany(CompanyName());
        Observer.Observe('after_changecompany', Format(T.IsDirty()));
        T.Name := 'x';
        T.ChangeCompany(CompanyName());
        Observer.Observe('changed_then_changecompany', Format(T.IsDirty()));
        Observer.Expect('after_getbysystemid', 'No');
        Observer.Expect('after_setposition', 'Yes id=2 name=a');
        Observer.Expect('after_changecompany', 'No');
        Observer.Expect('changed_then_changecompany', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_FailedOrFalseWrites()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
    begin
        PydSeed();
        T.Get(1);
        T.Name := 'x';
        Observer.Observe('get_missing', Format(T.Get(99)));
        Observer.Observe('after_failed_get', Format(T.IsDirty()) + ' id=' + Format(T.Id) + ' name=' + T.Name);
        T.Get(1);
        Observer.Observe('get_missing_clean', Format(T.Get(99)));
        Observer.Observe('after_failed_get_clean', Format(T.IsDirty()));
        T.Get(1);
        T.Name := 'x';
        T.SetRange(Id, 50, 60);
        Observer.Observe('find_none', Format(T.FindFirst()));
        Observer.Observe('after_failed_find', Format(T.IsDirty()));
        T.Reset();
        T.Get(1);
        T.Name := 'x';
        Observer.Observe('insert_dup', Format(T.Insert()));
        Observer.Observe('after_false_insert', Format(T.IsDirty()));
        T.Get(1);
        T.Id := 77;
        T.Name := 'x';
        Observer.Observe('modify_missing', Format(T.Modify()));
        Observer.Observe('after_false_modify', Format(T.IsDirty()));
        Observer.Expect('get_missing', 'No');
        Observer.Expect('after_failed_get', 'Yes id=1 name=x');
        Observer.Expect('get_missing_clean', 'No');
        Observer.Expect('after_failed_get_clean', 'No');
        Observer.Expect('find_none', 'No');
        Observer.Expect('after_failed_find', 'Yes');
        Observer.Expect('insert_dup', 'No');
        Observer.Expect('after_false_insert', 'Yes');
        Observer.Expect('modify_missing', 'No');
        Observer.Expect('after_false_modify', 'Yes');
        Observer.Verify();
    end;

    local procedure PydByValue(T: Record "LT PYD Dirty Trg"): Text
    begin
        exit(Format(T.IsDirty()));
    end;

    local procedure PydByVar(var T: Record "LT PYD Dirty Trg"): Text
    begin
        exit(Format(T.IsDirty()));
    end;

    [Test]
    procedure PYD_IsDirty_ParametersXRecSetTable()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        U: Record "LT PYD Dirty Trg";
        RecRef: RecordRef;
        Log: Codeunit "LT PYD Dirty Log";
    begin
        PydSeed();
        T.Get(1);
        Observer.Observe('byvalue_clean', PydByValue(T));
        T.Name := 'x';
        Observer.Observe('byvalue_dirty', PydByValue(T));
        Observer.Observe('byvar_dirty', PydByVar(T));
        T.Modify(true);
        Observer.Observe('modify_log', Log.Dump());
        RecRef.Open(Database::"LT PYD Dirty Trg");
        RecRef.FindFirst();
        RecRef.SetTable(U);
        Observer.Observe('settable_after_find', Format(U.IsDirty()));
        RecRef.Field(2).Value := 'rr';
        RecRef.SetTable(U);
        Observer.Observe('settable_after_change', Format(U.IsDirty()));
        U.Get(2);
        RecRef.SetTable(U);
        Observer.Observe('settable_into_read', Format(U.IsDirty()) + ' id=' + Format(U.Id));
        Observer.Expect('byvalue_clean', 'No');
        Observer.Expect('byvalue_dirty', 'Yes');
        Observer.Expect('byvar_dirty', 'Yes');
        Observer.Expect('modify_log', '[OnModify dirty=Yes xRec dirty=Yes xRec.Name=x]');
        Observer.Expect('settable_after_find', 'No');
        Observer.Expect('settable_after_change', 'Yes');
        Observer.Expect('settable_into_read', 'Yes id=1');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_PageRecord()
    var
        Observer: Codeunit "Probe Observer";
        List: TestPage "LT PYD Dirty List";
        Log: Codeunit "LT PYD Dirty Log";
    begin
        PydSeed();
        List.OpenView();
        List.First();
        List.Close();
        Observer.Observe('log', Log.Dump());
        Observer.Expect('log', '[page OnAfterGetRecord 1 dirty=No][page OnAfterGetRecord 2 dirty=No][page OnAfterGetRecord 1 dirty=No]');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_SystemFieldsAndTransferDelete()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        U: Record "LT PYD Dirty Trg";
        Id: Integer;
        Name: Text[30];
        Stamp: Text[30];
        InitVal: Integer;
    begin
        PydSeed();
        T.Get(1);
        Id := T.Id;
        Name := T.Name;
        Stamp := T.Stamp;
        InitVal := T.InitVal;
        T.Init();
        Observer.Observe('after_init_of_read', Format(T.IsDirty()));
        T.Id := Id;
        T.Name := Name;
        T.Stamp := Stamp;
        T.InitVal := InitVal;
        Observer.Observe('fields_set_back', Format(T.IsDirty()) + ' sysid_blank=' + Format(IsNullGuid(T.SystemId)));
        T.Get(1);
        U.Get(2);
        T.TransferFields(U);
        Observer.Observe('transferfields_other_row', Format(T.IsDirty()) + ' id=' + Format(T.Id) + ' name=' + T.Name);
        T.Get(1);
        U.Get(2);
        T.TransferFields(U, false);
        Observer.Observe('transferfields_no_key', Format(T.IsDirty()) + ' id=' + Format(T.Id) + ' name=' + T.Name);
        T.Get(1);
        T.Name := 'changed';
        T.Delete();
        Observer.Observe('delete_changed', Format(T.IsDirty()) + ' name=' + T.Name);
        T.Name := 'again';
        Observer.Observe('after_delete_assign', Format(T.IsDirty()));
        Observer.Expect('after_init_of_read', 'Yes');
        Observer.Expect('fields_set_back', 'No sysid_blank=Yes');
        Observer.Expect('transferfields_other_row', 'Yes id=2 name=b');
        Observer.Expect('transferfields_no_key', 'Yes id=1 name=b');
        Observer.Expect('delete_changed', 'Yes name=changed');
        Observer.Expect('after_delete_assign', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_InitValueLoadFieldsFlowBlob()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
        Fresh: Record "LT PYD Dirty Trg";
        OutS: OutStream;
    begin
        PydSeed();
        Observer.Observe('fresh_initvalue', Format(Fresh.IsDirty()) + ' initval=' + Format(Fresh.InitVal));
        Fresh.Init();
        Observer.Observe('fresh_init', Format(Fresh.IsDirty()) + ' initval=' + Format(Fresh.InitVal));
        Fresh.InitVal := 0;
        Observer.Observe('fresh_initval_zero', Format(Fresh.IsDirty()));
        T.SetLoadFields(Name);
        T.Get(1);
        Observer.Observe('partial', Format(T.IsDirty()));
        T.Name := 'p';
        Observer.Observe('partial_changed_loaded', Format(T.IsDirty()));
        T.Get(1);
        T.Stamp := 'q';
        Observer.Observe('partial_changed_unloaded', Format(T.IsDirty()));
        T.SetLoadFields();
        T.Get(1);
        T.Cnt := 99;
        Observer.Observe('flowfield_assigned', Format(T.IsDirty()));
        T.Get(1);
        T.Pic.CreateOutStream(OutS);
        OutS.WriteText('blob');
        Observer.Observe('blob_written', Format(T.IsDirty()));
        Observer.Expect('fresh_initvalue', 'No initval=5');
        Observer.Expect('fresh_init', 'No initval=5');
        Observer.Expect('fresh_initval_zero', 'Yes');
        Observer.Expect('partial', 'No');
        Observer.Expect('partial_changed_loaded', 'Yes');
        Observer.Expect('partial_changed_unloaded', 'Yes');
        Observer.Expect('flowfield_assigned', 'No');
        Observer.Expect('blob_written', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure PYD_IsDirty_DeleteAllModifyAllAfterRead()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT PYD Dirty Trg";
    begin
        PydSeed();
        T.Get(1);
        T.ModifyAll(Name, 'all');
        Observer.Observe('after_modifyall', Format(T.IsDirty()) + ' name=' + T.Name);
        T.Get(1);
        T.Name := 'x';
        T.ModifyAll(Stamp, 'st');
        Observer.Observe('changed_then_modifyall', Format(T.IsDirty()) + ' stamp=' + T.Stamp);
        T.Get(1);
        T.DeleteAll();
        Observer.Observe('after_deleteall', Format(T.IsDirty()));
        Observer.Expect('after_modifyall', 'No name=a');
        Observer.Expect('changed_then_modifyall', 'Yes stamp=');
        Observer.Expect('after_deleteall', 'No');
        Observer.Verify();
    end;
}

// Writer PY-D (2026-10-20): objects 85230-85233 for the PYD_ IsDirty probes in codeunit 77504 (temporary records, finds, writes with
// triggers and subscribers, Copy/Clear/CalcFields/..., parameters, xRec, pages, RecordRef.SetTable, system fields, InitValue, SetLoadFields,
// FlowField and Blob, DeleteAll/ModifyAll after a read).
table 85230 "LT PYD Dirty Trg"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Stamp; Text[30]) { }
        field(4; InitVal; Integer) { InitValue = 5; }
        field(5; Cnt; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT AC Dirty Row");
        }
        field(6; Pic; Blob) { }
        field(7; Big; Text[100]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('OnInsert dirty=' + Format(Rec.IsDirty()));
        Stamp := 'ins';
        Log.Add('OnInsert after stamp dirty=' + Format(Rec.IsDirty()));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('OnModify dirty=' + Format(Rec.IsDirty()) + ' xRec dirty=' + Format(xRec.IsDirty()) + ' xRec.Name=' + xRec.Name);
        Stamp := 'mod';
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('OnDelete dirty=' + Format(Rec.IsDirty()));
        Stamp := 'del';
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('OnRename dirty=' + Format(Rec.IsDirty()) + ' xRec dirty=' + Format(xRec.IsDirty()));
        Stamp := 'ren';
    end;
}

page 85231 "LT PYD Dirty List"
{
    PageType = List;
    SourceTable = "LT PYD Dirty Trg";
    UsageCategory = None;
    ApplicationArea = All;

    layout
    {
        area(Content)
        {
            repeater(Rows)
            {
                field(Id; Rec.Id) { ApplicationArea = All; }
                field(Name; Rec.Name) { ApplicationArea = All; }
            }
        }
    }

    trigger OnAfterGetRecord()
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('page OnAfterGetRecord ' + Format(Rec.Id) + ' dirty=' + Format(Rec.IsDirty()));
    end;
}

// SingleInstance log, used only by codeunit 77504 (and the objects above that it drives).
codeunit 85232 "LT PYD Dirty Log"
{
    SingleInstance = true;

    var
        Lines: Text;

    procedure Reset()
    begin
        Lines := '';
    end;

    procedure Add(Line: Text)
    begin
        Lines += '[' + Line + ']';
    end;

    procedure Dump(): Text
    begin
        exit(Lines);
    end;
}

codeunit 85233 "LT PYD Dirty Sub"
{
    EventSubscriberInstance = Manual;

    [EventSubscriber(ObjectType::Table, Database::"LT PYD Dirty Trg", 'OnBeforeModifyEvent', '', false, false)]
    local procedure OnBeforeModify(var Rec: Record "LT PYD Dirty Trg")
    var
        Log: Codeunit "LT PYD Dirty Log";
    begin
        Log.Add('sub OnBeforeModify dirty=' + Format(Rec.IsDirty()));
        Rec.Big := 'sub';
    end;
}
#endif
