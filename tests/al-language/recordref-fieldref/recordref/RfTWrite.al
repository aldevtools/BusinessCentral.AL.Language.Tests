// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-insert-method
// Scope: in-scope
// Fixtures used: tables 73000, 73001 (RfTObjects.al), codeunit 73010 (RfTHelpers.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Init, Insert, Modify, Delete, Rename, DeleteAll, Validate, TestField, FieldError on RecordRef/FieldRef.
// BC versions: 29 (27 and 28 by CI)

codeunit 73022 "LT RfT Write"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure Insert_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
    begin
        Helper.Reset();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'A1';
        RecRef.Field(2).Value := 'hello';
        Observer.Observe('insert', Format(RecRef.Insert()));
        Observer.Observe('count', Format(RecRef.Count()));
        Rec.Get('A1');
        Observer.Observe('txt', Rec.Txt);
        RecRef.Init();
        RecRef.Field(1).Value := 'A2';
        Observer.Observe('insert_true', Format(RecRef.Insert(true)));
        RecRef.Init();
        RecRef.Field(1).Value := 'A3';
        Observer.Observe('insert_false', Format(RecRef.Insert(false)));
        RecRef.Init();
        RecRef.Field(1).Value := 'A4';
        Observer.Observe('insert_false_false', Format(RecRef.Insert(false, false)));
        Observer.Observe('count_after', Format(RecRef.Count()));
        Observer.Expect('insert', 'Yes');
        Observer.Expect('count', '1');
        Observer.Expect('txt', 'hello');
        Observer.Expect('insert_true', 'Yes');
        Observer.Expect('insert_false', 'Yes');
        Observer.Expect('insert_false_false', 'Yes');
        Observer.Expect('count_after', '4');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Duplicate_Error()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Reset();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'A1';
        RecRef.Insert();
        asserterror RecRef.Insert();
        Observer.ObserveError('duplicate');
        Observer.Expect('duplicate|text', 'The record in table RfT Data Caption already exists. Identification fields and values: Code Caption=''A1''');
        Observer.Expect('duplicate|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Blank_PK_And_Trigger()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Reset();
        RecRef.Open(73001);
        Observer.Observe('insert_blank', Format(RecRef.Insert()));
        Observer.Observe('count', Format(RecRef.Count()));
        Observer.Expect('insert_blank', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_Temporary_Duplicate()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
    begin
        RecRef.Open(73001, true);
        RecRef.Field(1).Value := 'T1';
        RecRef.Insert();
        asserterror RecRef.Insert();
        Observer.ObserveError('temp_duplicate');
        Observer.Expect('temp_duplicate|text', 'The record in table RfT Data Caption already exists. Identification fields and values: Code Caption=''T1''');
        Observer.Expect('temp_duplicate|code', 'DB:RecordExists');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Rec.Code := 'D1';
        RecRef.Get(Rec.RecordId());
        RecRef.Field(2).Value := 'changed';
        Observer.Observe('modify', Format(RecRef.Modify()));
        Rec.Get('D1');
        Observer.Observe('txt', Rec.Txt);
        RecRef.Field(2).Value := 'changed2';
        Observer.Observe('modify_true', Format(RecRef.Modify(true)));
        RecRef.Field(2).Value := 'changed3';
        Observer.Observe('modify_false', Format(RecRef.Modify(false)));
        Observer.Expect('modify', 'Yes');
        Observer.Expect('txt', 'changed');
        Observer.Expect('modify_true', 'Yes');
        Observer.Expect('modify_false', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Missing_Row()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        B: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'NOPE';
        B := RecRef.Modify();
        Observer.Observe('modify_missing', 'no error');
        Observer.Expect('modify_missing', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        B: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'D1';
        Observer.Observe('delete', Format(RecRef.Delete()));
        Observer.Observe('count', Format(RecRef.Count()));
        RecRef.Field(1).Value := 'D2';
        Observer.Observe('delete_true', Format(RecRef.Delete(true)));
        RecRef.Field(1).Value := 'D3';
        Observer.Observe('delete_false', Format(RecRef.Delete(false)));
        Observer.Observe('count_after', Format(RecRef.Count()));
        RecRef.Field(1).Value := 'D1';
        B := RecRef.Delete();
        Observer.Observe('delete_missing', 'no error');
        Observer.Expect('delete', 'Yes');
        Observer.Expect('count', '4');
        Observer.Expect('delete_true', 'Yes');
        Observer.Expect('delete_false', 'Yes');
        Observer.Expect('count_after', '2');
        Observer.Expect('delete_missing', 'no error');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(3).SetRange(10, 20);
        RecRef.DeleteAll();
        RecRef.Reset();
        Observer.Observe('after_filtered_delete', Format(RecRef.Count()));
        RecRef.DeleteAll(true);
        Observer.Observe('after_delete_all', Format(RecRef.Count()));
        RecRef.DeleteAll(false);
        Observer.Observe('delete_all_empty', Format(RecRef.Count()));
        Observer.Expect('after_filtered_delete', '3');
        Observer.Expect('after_delete_all', '0');
        Observer.Expect('delete_all_empty', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
        B: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        Rec.Code := 'D1';
        RecRef.Get(Rec.RecordId());
        Observer.Observe('rename', Format(RecRef.Rename('D1X')));
        Observer.Observe('get_new', Format(Rec.Get('D1X')));
        Observer.Observe('get_old', Format(Rec.Get('D1')));
        Observer.Observe('current_after', Format(RecRef.Field(1).Value));
        asserterror B := RecRef.Rename('D2');
        Observer.ObserveError('rename_existing');
        asserterror B := RecRef.Rename('a', 'b');
        Observer.ObserveError('rename_too_many');
        Observer.Expect('rename', 'Yes');
        Observer.Expect('get_new', 'Yes');
        Observer.Expect('get_old', 'No');
        Observer.Expect('current_after', 'D1X');
        Observer.Expect('rename_existing|text', 'The record in table RfT Data Caption already exists. Identification fields and values: Code Caption=''D2''');
        Observer.Expect('rename_existing|code', 'DB:RecordExists');
        Observer.Expect('rename_too_many|text', 'The number of field arguments does not match the primary key size.');
        Observer.Expect('rename_too_many|code', 'RenameArgument');
        Observer.Verify();
    end;

    [Test]
    procedure Init_ClearsFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.FindFirst();
        Observer.Observe('before_txt', Format(RecRef.Field(2).Value));
        RecRef.Init();
        Observer.Observe('after_txt', Format(RecRef.Field(2).Value));
        Observer.Observe('after_code', Format(RecRef.Field(1).Value));
        Observer.Observe('after_int', Format(RecRef.Field(3).Value));
        Observer.Observe('after_opt', Format(RecRef.Field(9).Value));
        Observer.Observe('after_col', Format(RecRef.Field(10).Value));
        Observer.Expect('before_txt', 'Text 1');
        Observer.Expect('after_txt', '');
        Observer.Expect('after_code', 'D1');
        Observer.Expect('after_int', '0');
        Observer.Expect('after_opt', 'Erste');
        Observer.Expect('after_col', 'Red');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Triggers()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Reset();
        RecRef.Open(73001);
        Fld := RecRef.Field(18);
        Fld.Value := 7;
        Observer.Observe('value_no_trigger', Format(RecRef.Field(2).Value));
        Fld.Validate(8);
        Observer.Observe('validate_value', Format(RecRef.Field(2).Value));
        Observer.Observe('validate_field', Format(Fld.Value));
        Fld.Validate();
        Observer.Observe('validate_noarg', Format(RecRef.Field(2).Value));
        Fld.Value := 9;
        Fld.Validate();
        Observer.Observe('validate_noarg_9', Format(RecRef.Field(2).Value));
        Observer.Expect('value_no_trigger', '');
        Observer.Expect('validate_value', 'validated 8');
        Observer.Expect('validate_field', '8');
        Observer.Expect('validate_noarg', 'validated 8');
        Observer.Expect('validate_noarg_9', 'validated 9');
        Observer.Verify();
    end;

    [Test]
    procedure TestField_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Get(Rec_Id('D2'));
        Fld := RecRef.Field(2);
        Fld.TestField();
        Observer.Observe('testfield_nonblank', 'ok');
        Fld.TestField('Text 2');
        Observer.Observe('testfield_equal', 'ok');
        asserterror Fld.TestField('other');
        Observer.ObserveError('testfield_diff');
        Fld := RecRef.Field(5);
        asserterror Fld.TestField();
        Observer.ObserveError('testfield_bool_false');
        Fld := RecRef.Field(4);
        asserterror Fld.TestField(5);
        Observer.ObserveError('testfield_decimal');
        Fld := RecRef.Field(3);
        Fld.TestField(20);
        Observer.Observe('testfield_int_ok', 'ok');
        asserterror Fld.TestField(21);
        Observer.ObserveError('testfield_int_diff');
        Fld := RecRef.Field(9);
        asserterror Fld.TestField(2);
        Observer.ObserveError('testfield_option');
        Fld := RecRef.Field(10);
        asserterror Fld.TestField();
        Observer.ObserveError('testfield_enum_default');
        asserterror Fld.TestField(Enum::"LT RfT Color"::Blue);
        Observer.ObserveError('testfield_enum_blue');
        Fld := RecRef.Field(6);
        asserterror Fld.TestField(0D);
        Observer.ObserveError('testfield_date');
        Fld := RecRef.Field(7);
        asserterror Fld.TestField();
        Observer.ObserveError('testfield_time_blank');
        Observer.Expect('testfield_nonblank', 'ok');
        Observer.Expect('testfield_equal', 'ok');
        Observer.Expect('testfield_diff|text', 'Txt Caption must be equal to ''other''  in RfT Data Caption: Code Caption=D2. Current value is ''Text 2''.');
        Observer.Expect('testfield_diff|code', 'TestField');
        Observer.Expect('testfield_bool_false|text', 'Bool must have a value in RfT Data Caption: Code Caption=D2. It cannot be zero or empty.');
        Observer.Expect('testfield_bool_false|code', 'TestField');
        Observer.Expect('testfield_decimal|text', 'Dec must be equal to ''5''  in RfT Data Caption: Code Caption=D2. Current value is ''2.5''.');
        Observer.Expect('testfield_decimal|code', 'TestField');
        Observer.Expect('testfield_int_ok', 'ok');
        Observer.Expect('testfield_int_diff|text', 'Int must be equal to ''21''  in RfT Data Caption: Code Caption=D2. Current value is ''20''.');
        Observer.Expect('testfield_int_diff|code', 'TestField');
        Observer.Expect('testfield_option|text', 'Opt must be equal to ''Dritte''  in RfT Data Caption: Code Caption=D2. Current value is ''Zweite''.');
        Observer.Expect('testfield_option|code', 'TestField');
        Observer.Expect('testfield_enum_default|text', 'Col must not be Red in RfT Data Caption: Code Caption=D2');
        Observer.Expect('testfield_enum_default|code', 'TestField');
        Observer.Expect('testfield_enum_blue|text', 'Col must be equal to ''Blue Caption''  in RfT Data Caption: Code Caption=D2. Current value is ''Red''.');
        Observer.Expect('testfield_enum_blue|code', 'TestField');
        Observer.Expect('testfield_date|text', 'Dt must be equal to ''''  in RfT Data Caption: Code Caption=D2. Current value is ''01/02/20''.');
        Observer.Expect('testfield_date|code', 'TestField');
        Observer.Expect('testfield_time_blank|text', 'Tm must have a value in RfT Data Caption: Code Caption=D2. It cannot be zero or empty.');
        Observer.Expect('testfield_time_blank|code', 'TestField');
        Observer.Verify();
    end;

    local procedure Rec_Id(CodeValue: Code[20]): RecordId
    var
        Rec: Record "LT RfT Data";
    begin
        Rec.Code := CodeValue;
        exit(Rec.RecordId());
    end;

    [Test]
    procedure FieldError_Variants()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Fld: FieldRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Get(Rec_Id('D2'));
        Fld := RecRef.Field(2);
        asserterror Fld.FieldError();
        Observer.ObserveError('fielderror');
        asserterror Fld.FieldError('custom text');
        Observer.ObserveError('fielderror_text');
        asserterror Fld.FieldError('');
        Observer.ObserveError('fielderror_empty');
        Fld := RecRef.Field(3);
        asserterror Fld.FieldError();
        Observer.ObserveError('fielderror_int');
        asserterror Fld.FieldError('msg');
        Observer.ObserveError('fielderror_int_text');
        Fld := RecRef.Field(9);
        asserterror Fld.FieldError('msg');
        Observer.ObserveError('fielderror_option');
        Fld := RecRef.Field(10);
        asserterror Fld.FieldError('msg');
        Observer.ObserveError('fielderror_enum');
        Observer.Expect('fielderror|text', 'Txt Caption must not be Text 2 in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_text|text', 'Txt Caption custom text in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_empty|text', 'Txt Caption must not be Text 2 in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_empty|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_int|text', 'Int must not be 20 in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_int|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_int_text|text', 'Int msg in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_int_text|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_option|text', 'Opt msg in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_option|code', 'NCLCSRTS:TableErrorStr');
        Observer.Expect('fielderror_enum|text', 'Col msg in RfT Data Caption Code Caption=''D2''.');
        Observer.Expect('fielderror_enum|code', 'NCLCSRTS:TableErrorStr');
        Observer.Verify();
    end;

    [Test]
    procedure Duplicate_Independent()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Dup: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(3).SetRange(10, 20);
        Dup := RecRef.Duplicate();
        Observer.Observe('dup_name', Dup.Name());
        Observer.Observe('dup_count', Format(Dup.Count()));
        Dup.Reset();
        Observer.Observe('dup_count_reset', Format(Dup.Count()));
        Observer.Observe('orig_count', Format(RecRef.Count()));
        RecRef.FindFirst();
        Observer.Observe('orig_first', Format(RecRef.Field(1).Value));
        Observer.Observe('dup_current_empty', Format(Dup.Field(1).Value));
        Observer.Expect('dup_name', 'LT RfT Data');
        Observer.Expect('dup_count', '2');
        Observer.Expect('dup_count_reset', '5');
        Observer.Expect('orig_count', '2');
        Observer.Expect('orig_first', 'D1');
        Observer.Expect('dup_current_empty', '');
        Observer.Verify();
    end;

    [Test]
    procedure RecordId_And_Rec_Relation()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT RfT Helper";
        RecRef: RecordRef;
        Rec: Record "LT RfT Data";
        RecId: RecordId;
    begin
        Helper.Seed();
        RecRef.Open(73001);
        RecRef.Field(1).Value := 'D1';
        Rec.Code := 'D1';
        Observer.Observe('equal_no_find', Format(RecRef.RecordId() = Rec.RecordId()));
        Observer.Observe('format_no_find', Format(RecRef.RecordId()));
        RecRef.Field(1).Value := 'D9';
        Observer.Observe('format_other', Format(RecRef.RecordId()));
        RecId := RecRef.RecordId();
        Observer.Observe('table_of_id', Format(RecId.TableNo()));
        Observer.Expect('equal_no_find', 'Yes');
        Observer.Expect('format_no_find', 'LT RfT Data: D1');
        Observer.Expect('format_other', 'LT RfT Data: D9');
        Observer.Expect('table_of_id', '73001');
        Observer.Verify();
    end;
}
