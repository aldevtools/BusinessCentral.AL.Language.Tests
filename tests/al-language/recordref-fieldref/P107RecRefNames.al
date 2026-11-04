// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-data-type
// Scope: in-scope
// Fixtures used: tables 72694-72695, codeunit 72696 (P107Objects.al), Probe Observer
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.Field(Text), FieldExist(Text), IsDirty, LoadFields, SetTable(Rec, ShareTable)
// BC versions: 29 (27 and 28 by CI)

codeunit 72697 "LT P107 RecRef Names"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P107_FieldByName()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P107 Helper";
        RecRef: RecordRef;
        FldRef: FieldRef;
        Nm: Text;
    begin
        Helper.Seed();
        RecRef.Open(72694);
        RecRef.FindFirst();
        FldRef := RecRef.Field('Name');
        Observer.Observe('by_name', Format(FldRef.Value));
        Observer.Observe('by_name_number', Format(FldRef.Number));
        Nm := 'Qty';
        FldRef := RecRef.Field(Nm);
        Observer.Observe('text_var', Format(FldRef.Value));
        Observer.Observe('text_var_name', FldRef.Name);
        FldRef := RecRef.Field('name');
        Observer.Observe('lowercase', Format(FldRef.Number));
        FldRef := RecRef.Field('NAME');
        Observer.Observe('uppercase', Format(FldRef.Number));
        asserterror FldRef := RecRef.Field('Code Cap');
        Observer.ObserveError('af36');
        Observer.Observe('caption_name', Format(FldRef.Number));
        asserterror FldRef := RecRef.Field('Nope');
        Observer.ObserveError('missing');
        asserterror FldRef := RecRef.Field('');
        Observer.ObserveError('empty');
        asserterror FldRef := RecRef.Field(' Name');
        Observer.ObserveError('leading_space');
        RecRef.Close();
        Observer.Expect('by_name', 'Alpha');
        Observer.Expect('by_name_number', '2');
        Observer.Expect('text_var', '1');
        Observer.Expect('text_var_name', 'Qty');
        Observer.Expect('lowercase', '2');
        Observer.Expect('uppercase', '2');
        Observer.Expect('af36|text', 'The supplied field number ''Code Cap'' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('af36|code', 'FieldNotFound');
        Observer.Expect('caption_name', '2');
        Observer.Expect('missing|text', 'The supplied field number ''Nope'' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('missing|code', 'FieldNotFound');
        Observer.Expect('empty|text', 'The supplied field number '''' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('empty|code', 'FieldNotFound');
        Observer.Expect('leading_space|text', 'The supplied field number '' Name'' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('leading_space|code', 'FieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P107_FieldExistByName()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Nm: Text;
    begin
        RecRef.Open(72694);
        Observer.Observe('Name', Format(RecRef.FieldExist('Name')));
        Nm := 'Qty';
        Observer.Observe('text_var', Format(RecRef.FieldExist(Nm)));
        Observer.Observe('lowercase', Format(RecRef.FieldExist('name')));
        Observer.Observe('uppercase', Format(RecRef.FieldExist('QTY')));
        Observer.Observe('missing', Format(RecRef.FieldExist('Nope')));
        Observer.Observe('empty', Format(RecRef.FieldExist('')));
        Observer.Observe('caption', Format(RecRef.FieldExist('Name Cap')));
        Observer.Observe('padded', Format(RecRef.FieldExist(' Name ')));
        Observer.Observe('number_text', Format(RecRef.FieldExist('1')));
        Observer.Observe('by_number', Format(RecRef.FieldExist(1)));
        Observer.Observe('by_number_missing', Format(RecRef.FieldExist(99)));
        RecRef.Close();
        Observer.Expect('Name', 'Yes');
        Observer.Expect('text_var', 'Yes');
        Observer.Expect('lowercase', 'Yes');
        Observer.Expect('uppercase', 'Yes');
        Observer.Expect('missing', 'No');
        Observer.Expect('empty', 'No');
        Observer.Expect('caption', 'No');
        Observer.Expect('padded', 'No');
        Observer.Expect('number_text', 'No');
        Observer.Expect('by_number', 'Yes');
        Observer.Expect('by_number_missing', 'No');
        Observer.Verify();
    end;

#if BC28PLUS
    [Test]
    procedure P107_IsDirty()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P107 Helper";
        RecRef: RecordRef;
    begin
        Helper.Seed();
        RecRef.Open(72694);
        Observer.Observe('open', Format(RecRef.IsDirty()));
        RecRef.FindFirst();
        Observer.Observe('found', Format(RecRef.IsDirty()));
        RecRef.Field(3).Value := 1;
        Observer.Observe('same_value', Format(RecRef.IsDirty()));
        RecRef.Field(3).Value := 2;
        Observer.Observe('changed', Format(RecRef.IsDirty()));
        RecRef.Modify();
        Observer.Observe('modified', Format(RecRef.IsDirty()));
        RecRef.Field(2).Value := 'Changed';
        Observer.Observe('name_changed', Format(RecRef.IsDirty()));
        RecRef.Find('=');
        Observer.Observe('refound', Format(RecRef.IsDirty()));
        RecRef.Init();
        Observer.Observe('init', Format(RecRef.IsDirty()));
        RecRef.Close();
        Observer.Expect('open', 'No');
        Observer.Expect('found', 'No');
        Observer.Expect('same_value', 'No');
        Observer.Expect('changed', 'Yes');
        Observer.Expect('modified', 'No');
        Observer.Expect('name_changed', 'Yes');
        Observer.Expect('refound', 'No');
        Observer.Expect('init', 'Yes');
        Observer.Verify();
    end;
#endif

    [Test]
    procedure P107_LoadFields()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P107 Helper";
        RecRef: RecordRef;
        Ok: Boolean;
    begin
        Helper.Seed();
        RecRef.Open(72694);
        RecRef.SetLoadFields(2);
        RecRef.FindFirst();
        Observer.Observe('setloadfields_name', Format(RecRef.Field(2).Value));
        RecRef.Close();
        RecRef.Open(72694);
        Ok := RecRef.AddLoadFields(3);
        Observer.Observe('addloadfields_ret', Format(Ok));
        RecRef.FindFirst();
        Observer.Observe('addloadfields_qty', Format(RecRef.Field(3).Value));
        Observer.Observe('addloadfields_name', Format(RecRef.Field(2).Value));
        RecRef.Close();
        RecRef.Open(72694);
        asserterror RecRef.SetLoadFields(99);
        Observer.ObserveError('setloadfields_missing');
        asserterror RecRef.AddLoadFields(99);
        Observer.ObserveError('addloadfields_missing');
        RecRef.Close();
        Observer.Expect('setloadfields_name', 'Alpha');
        Observer.Expect('addloadfields_ret', 'No');
        Observer.Expect('addloadfields_qty', '1');
        Observer.Expect('addloadfields_name', 'Alpha');
        Observer.Expect('setloadfields_missing|text', 'The supplied field number ''99'' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('setloadfields_missing|code', 'FieldNotFound');
        Observer.Expect('addloadfields_missing|text', 'The supplied field number ''99'' cannot be found in the ''LT P107 Rec'' table.');
        Observer.Expect('addloadfields_missing|code', 'FieldNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P107_SetTableShare()
    var
        Observer: Codeunit "Probe Observer";
        Helper: Codeunit "LT P107 Helper";
        RecRef: RecordRef;
        Rec: Record "LT P107 Rec";
        Rec2: Record "LT P107 Rec";
    begin
        Helper.Seed();
        RecRef.Open(72694);
        RecRef.FindLast();
        RecRef.SetTable(Rec, false);
        Observer.Observe('share_false_code', Rec.Code);
        Observer.Observe('share_false_temp', Format(Rec.IsTemporary()));
        asserterror RecRef.SetTable(Rec2, true);
        Observer.ObserveError('af146');
        Observer.Observe('share_true_code', Rec2.Code);
        Observer.Observe('share_true_temp', Format(Rec2.IsTemporary()));
        RecRef.Close();
        Observer.Expect('share_false_code', 'C');
        Observer.Expect('share_false_temp', 'No');
        Observer.Expect('af146|text', 'The COPY function can only be used with the shareTable argument set to true if both records are temporary.');
        Observer.Expect('af146|code', 'Argument');
        Observer.Expect('share_true_code', '');
        Observer.Expect('share_true_temp', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P107_SetTableShareTemporary()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Tmp: Record "LT P107 Rec" temporary;
        Target: Record "LT P107 Rec" temporary;
    begin
        Tmp.Code := 'T1';
        Tmp.Insert();
        RecRef.GetTable(Tmp);
        asserterror RecRef.Insert();
        Observer.ObserveError('af165');
        Target.Code := 'X';
        Target.Insert();
        RecRef.SetTable(Target, true);
        Observer.Observe('share_true_count', Format(Target.Count()));
        Observer.Observe('share_true_temp', Format(Target.IsTemporary()));
        Target.Reset();
        RecRef.SetTable(Target, false);
        Observer.Observe('share_false_count', Format(Target.Count()));
        Observer.Observe('share_false_temp', Format(Target.IsTemporary()));
        Observer.Expect('af165|text', 'The record in table LT P107 Rec already exists. Identification fields and values: Code Cap=''T1''');
        Observer.Expect('af165|code', 'DB:RecordExists');
        Observer.Expect('share_true_count', '1');
        Observer.Expect('share_true_temp', 'Yes');
        Observer.Expect('share_false_count', '1');
        Observer.Expect('share_false_temp', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P107_SetTableWrongTable()
    var
        Observer: Codeunit "Probe Observer";
        RecRef: RecordRef;
        Dest: Record "LT P107 Dest";
    begin
        RecRef.Open(72694);
        asserterror RecRef.SetTable(Dest, true);
        Observer.ObserveError('wrong_table_true');
        asserterror RecRef.SetTable(Dest, false);
        Observer.ObserveError('wrong_table_false');
        RecRef.Close();
        Observer.Expect('wrong_table_true|text', 'The table IDs do not match.');
        Observer.Expect('wrong_table_true|code', 'TableIdMismatch');
        Observer.Expect('wrong_table_false|text', 'The table IDs do not match.');
        Observer.Expect('wrong_table_false|code', 'TableIdMismatch');
        Observer.Verify();
    end;

    // Corpus #664 item 12: RecordRef.Open with a Variant argument. The compiler gives warning AL0916 and picks Open(Integer) (AL 30 beta,
    // runtime 18.0); this records what that call does with a Variant that holds an Integer, a BigInteger, a numeric Text and a table name.
    [Test]
    procedure BM_OpenVariantArgument()
    var
        Observer: Codeunit "Probe Observer";
        V: Variant;
        Big: BigInteger;
    begin
        V := 72694;
        Observer.Observe('integer', TryOpenVariant(V));
        Big := 72694;
        V := Big;
        Observer.Observe('biginteger', TryOpenVariant(V));
        V := '72694';
        Observer.Observe('numeric_text', TryOpenVariant(V));
        V := 'LT P107 Rec';
        Observer.Observe('table_name_text', TryOpenVariant(V));
        V := 0;
        Observer.Observe('zero', TryOpenVariant(V));
        Observer.Expect('integer', 'ok|No|72694|LT P107 Rec');
        Observer.Expect('biginteger', 'ok|No|72694|LT P107 Rec');
        Observer.Expect('numeric_text', 'ok|No|72694|LT P107 Rec');
        Observer.Expect('table_name_text', 'error|before open|The expression Variant cannot be type-converted to a Integer value.|TypeConversion:Format');
        // Open(0) raises no error, but the RecordRef is not open afterwards: Number() raises the error.
        Observer.Expect('zero', 'error|opened|The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    local procedure TryOpenVariant(V: Variant): Text
    var
        Opened: Text;
    begin
        ClearLastError();
        if TryOpen(V, Opened) then
            exit('ok|' + Opened);
        exit('error|' + Opened + '|' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    // The first version passed the RecordRef out of the try function; on BC 29.0 the test then stopped with "The record is not open."
    // (the caller read Number after the try function returned true), so the number and name are now read inside the try function, next to the Open call.
    [TryFunction]
    local procedure TryOpen(V: Variant; var Opened: Text)
    var
        RecRef: RecordRef;
    begin
        Opened := 'before open';
        RecRef.Open(V);
        Opened := 'opened';
        Opened := Format(RecRef.IsTemporary()) + '|' + Format(RecRef.Number()) + '|' + RecRef.Name();
    end;
}

