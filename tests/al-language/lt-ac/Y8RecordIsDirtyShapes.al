// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-isdirty-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: Record.IsDirty() in the shapes ACRecordIsDirty.al does not pin (al-runtime-rs docs/probes-needed.md, the IsDirty rows): a temporary record;
// after Find('-'), FindSet and Next; after Insert(true), Modify(true) and Delete(true) whose triggers change a field; after Copy, Clear, CalcFields,
// GetBySystemId, SetPosition and a failed or false Get, Find, Insert and Modify; a record passed by value, xRec in a trigger, a record filled by
// RecordRef.SetTable; system fields; a declared variable of a table with InitValue fields; a partial record (SetLoadFields); a FlowField and a Blob;
// DeleteAll and ModifyAll on a record that was read.
// Probe: written against the BC 29 SaaS sandbox. Record.IsDirty exists on BC 29 and later only (must-not-compile case 0960).
// BC versions: 29. Writer Y8 (2026-10-30).

#if BC29PLUS
codeunit 91416 "LT Y8 Dirty Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        Entries += Entry + ';';
    end;

    procedure Take() Result: Text
    begin
        Result := Entries;
        Entries := '';
    end;
}

table 91415 "LT Y8 Dirty Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Amount; Decimal) { InitValue = 7; }
        field(4; Stamp; Text[30]) { }
        field(5; Total; Integer)
        {
            FieldClass = FlowField;
            CalcFormula = count("LT Y8 Dirty Row" where(Id = field(Id)));
        }
        field(6; Data; Blob) { }
        field(7; Flag; Boolean) { InitValue = true; }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Log.Add('ins:' + Format(Rec.IsDirty()));
        Stamp := 'by OnInsert';
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Log.Add('mod:' + Format(Rec.IsDirty()) + '/x:' + Format(xRec.IsDirty()));
        Stamp := 'by OnModify';
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Log.Add('del:' + Format(Rec.IsDirty()));
        Stamp := 'by OnDelete';
    end;
}

codeunit 91415 "LT Y8 Record Is Dirty Shapes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT Y8 Dirty Row";
        Index: Integer;
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Row.DeleteAll();
        for Index := 1 to 3 do begin
            Row.Init();
            Row.Id := Index;
            Row.Name := 'n' + Format(Index);
            Row.Insert();
        end;
        Log.Take();
    end;

    local procedure ByValue(R: Record "LT Y8 Dirty Row"): Text
    begin
        exit(Format(R.IsDirty()));
    end;

    local procedure ByVar(var R: Record "LT Y8 Dirty Row"): Text
    begin
        exit(Format(R.IsDirty()));
    end;

    [Test]
    procedure Y8_IsDirty_Temporary()
    var
        Observer: Codeunit "Probe Observer";
        T: Record "LT Y8 Dirty Row" temporary;
    begin
        Observer.Observe('fresh', Format(T.IsDirty()));
        T.Init();
        T.Id := 1;
        Observer.Observe('assigned', Format(T.IsDirty()));
        T.Insert();
        Observer.Observe('after_insert', Format(T.IsDirty()));
        T.Name := 'x';
        Observer.Observe('assigned_again', Format(T.IsDirty()));
        T.Modify();
        Observer.Observe('after_modify', Format(T.IsDirty()));
        T.Name := 'y';
        T.Get(1);
        Observer.Observe('after_get', Format(T.IsDirty()));
        T.Name := 'z';
        T.FindFirst();
        Observer.Observe('after_findfirst', Format(T.IsDirty()));
        T.Delete();
        Observer.Observe('after_delete', Format(T.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_FindForms()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
    begin
        Seed();
        Row.Name := 'dirty';
        Row.Find('-');
        Observer.Observe('find_minus', Format(Row.IsDirty()));
        Row.Name := 'dirty';
        Row.FindSet();
        Observer.Observe('findset', Format(Row.IsDirty()));
        Row.Name := 'dirty';
        Row.Next();
        Observer.Observe('next', Format(Row.IsDirty()));
        Row.Name := 'dirty';
        Row.Find('=');
        Observer.Observe('find_eq', Format(Row.IsDirty()));
        Row.Name := 'dirty';
        Row.Find('>');
        Observer.Observe('find_gt', Format(Row.IsDirty()));
        Row.Name := 'dirty';
        Observer.Observe('next_at_end', Format(Row.Next()));
        Observer.Observe('next_at_end_dirty', Format(Row.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_WritesWithTriggers()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Seed();
        Row.Init();
        Row.Id := 10;
        Row.Insert(true);
        Observer.Observe('insert_true', Format(Row.IsDirty()));
        Observer.Observe('insert_true_stamp', Row.Stamp);
        Row.Name := 'changed';
        Row.Modify(true);
        Observer.Observe('modify_true', Format(Row.IsDirty()));
        Row.Modify(true);
        Observer.Observe('modify_true_again', Format(Row.IsDirty()));
        Row.Delete(true);
        Observer.Observe('delete_true', Format(Row.IsDirty()));
        Observer.Observe('delete_true_stamp', Row.Stamp);
        Observer.Observe('trigger_log', Log.Take());
        Row.Init();
        Row.Id := 11;
        Row.Insert(false);
        Observer.Observe('insert_false_stamp', Row.Stamp);
        Observer.Observe('insert_false', Format(Row.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_CopyClearCalcFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
        Other: Record "LT Y8 Dirty Row";
        Id: Guid;
    begin
        Seed();
        Row.Get(1);
        Row.Name := 'dirty';
        Other.Copy(Row);
        Observer.Observe('copy_of_dirty', Format(Other.IsDirty()));
        Row.Get(2);
        Other.Copy(Row);
        Observer.Observe('copy_of_clean', Format(Other.IsDirty()));
        Row.Name := 'dirty';
        Clear(Row);
        Observer.Observe('after_clear', Format(Row.IsDirty()));
        Row.Get(1);
        Row.CalcFields(Total);
        Observer.Observe('after_calcfields', Format(Row.IsDirty()));
        Row.Total := 99;
        Observer.Observe('flowfield_assigned', Format(Row.IsDirty()));
        Row.Get(1);
        Id := Row.SystemId;
        Row.Name := 'dirty';
        Row.GetBySystemId(Id);
        Observer.Observe('after_getbysystemid', Format(Row.IsDirty()));
        Row.Get(2);
        Row.Name := 'dirty';
        Row.SetPosition('Id=CONST(3)');
        Observer.Observe('after_setposition', Format(Row.IsDirty()));
        Observer.Observe('after_setposition_name', Row.Name);
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_FailedReadsAndWrites()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
    begin
        Seed();
        Row.Get(1);
        Row.Name := 'dirty';
        Observer.Observe('get_missing', Format(Row.Get(99)));
        Observer.Observe('after_failed_get', Format(Row.IsDirty()));
        Row.Get(1);
        Row.Name := 'dirty';
        Row.SetRange(Id, 50);
        Observer.Observe('find_none', Format(Row.FindFirst()));
        Observer.Observe('after_false_find', Format(Row.IsDirty()));
        Row.Reset();
        Row.Get(1);
        Row.Name := 'dirty';
        Observer.Observe('insert_dup', Format(Row.Insert()));
        Observer.Observe('after_false_insert', Format(Row.IsDirty()));
        Row.Get(1);
        Row.Id := 98;
        Row.Name := 'dirty';
        Observer.Observe('modify_missing', Format(Row.Modify()));
        Observer.Observe('after_false_modify', Format(Row.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_Copies()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
        Filled: Record "LT Y8 Dirty Row";
        RR: RecordRef;
        Log: Codeunit "LT Y8 Dirty Log";
    begin
        Seed();
        Row.Get(1);
        Row.Name := 'dirty';
        Observer.Observe('by_value_dirty', ByValue(Row));
        Observer.Observe('by_var_dirty', ByVar(Row));
        Row.Get(1);
        Observer.Observe('by_value_clean', ByValue(Row));
        RR.Open(Database::"LT Y8 Dirty Row");
        RR.FindFirst();
        RR.SetTable(Filled);
        Observer.Observe('settable_read_row', Format(Filled.IsDirty()));
        RR.Field(2).Value := 'changed by fieldref';
        RR.SetTable(Filled);
        Observer.Observe('settable_changed_row', Format(Filled.IsDirty()));
        Row.Get(2);
        Row.Name := 'x';
        Row.Modify(true);
        Observer.Observe('modify_trigger_log', Log.Take());
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_SystemAndInitValueFields()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
        Fresh: Record "LT Y8 Dirty Row";
    begin
        Seed();
        Observer.Observe('fresh_initvalue_var', Format(Fresh.IsDirty()));
        Observer.Observe('fresh_initvalue_amount', Format(Fresh.Amount));
        Fresh.Init();
        Observer.Observe('after_init', Format(Fresh.IsDirty()));
        Fresh.Amount := 0;
        Observer.Observe('initvalue_field_zeroed', Format(Fresh.IsDirty()));
        Row.Get(1);
        Row.SystemId := CreateGuid();
        Observer.Observe('systemid_assigned', Format(Row.IsDirty()));
        Row.Get(1);
        Row.Init();
        Observer.Observe('read_row_init', Format(Row.IsDirty()));
        Observer.Observe('read_row_init_systemid_null', Format(IsNullGuid(Row.SystemId)));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_PartialAndBlob()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
        OutS: OutStream;
    begin
        Seed();
        Row.SetLoadFields(Name);
        Row.Get(1);
        Observer.Observe('partial_read', Format(Row.IsDirty()));
        Row.Amount := 3;
        Observer.Observe('partial_unloaded_assigned', Format(Row.IsDirty()));
        Row.SetLoadFields();
        Row.Get(1);
        Row.Data.CreateOutStream(OutS);
        OutS.WriteText('blob');
        Observer.Observe('blob_written', Format(Row.IsDirty()));
        Row.Get(1);
        Row.CalcFields(Data);
        Observer.Observe('blob_calcfields', Format(Row.IsDirty()));
        Observer.Finish();
    end;

    [Test]
    procedure Y8_IsDirty_ModifyAllDeleteAll()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT Y8 Dirty Row";
    begin
        Seed();
        Row.Get(1);
        Row.ModifyAll(Name, 'all');
        Observer.Observe('modifyall_after_read', Format(Row.IsDirty()));
        Observer.Observe('modifyall_name_in_var', Row.Name);
        Row.Get(1);
        Row.Name := 'dirty';
        Row.ModifyAll(Amount, 5);
        Observer.Observe('modifyall_on_dirty', Format(Row.IsDirty()));
        Row.Get(1);
        Row.DeleteAll();
        Observer.Observe('deleteall_after_read', Format(Row.IsDirty()));
        Observer.Finish();
    end;
}
#endif
