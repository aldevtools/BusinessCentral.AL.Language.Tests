// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/fieldref/fieldref-validate-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-al-variables
// Scope: in-scope
// Fixtures used: CmTriggerObjects.al in this folder (84820-84829, 84831-84833), Probe Observer (69160).
// Facts: corpus issue 669 (odd AL behavior leads, part D), items 31, 33 to 40.
//   31: CurrFieldNo := 10 in a table extension procedure, then Modify(true): the base OnModify reads 10 (Rec.CurrFieldNo: AL0161, case 1696).
//   33: a value missing from the related table fails before OnValidate runs (Rec.Validate, FieldRef.Validate(v), FieldRef.Validate());
//       the field keeps its old value. ValidateTableRelation = false: no error, OnValidate runs.
//   34: no property and = true both check (table and tableextension fields), = false does not.
//   35: Insert(true) runs the extension's OnBeforeInsert, OnInsert, OnAfterInsert; what OnAfterInsert sets is in the variable but not
//       stored until a later Modify. Insert(false) and Insert() run none of them.
//   36: in OnInsert the SystemId is set; a row inserted with it by Insert(false, true) is found by GetBySystemId in the same trigger;
//       TransferFields does not copy the SystemId.
//   37: triggers of a temporary record run and write to and delete from real tables; DeleteAll() on it leaves real rows alone.
//   38: xRec in OnValidate is the value before Validate and does not follow assignments to Rec or a nested Validate; the nested
//       Validate's xRec is the outer xRec. In OnModify called from code, xRec equals Rec.
//   39: in code, OnBeforeModify / OnAfterModify see xRec = Rec (Get+assign, never read, Validate); after a TestPage edit xRec is the stored row.
//   40: TestPage New on a list filtered Id 1..5 with key 7: TestValidation error "The view is filtered, and the entry is outside the
//       filter. Some actions may not work." after OnInsertRecord ran; the row is stored. No filter, or key 3: no error.
// BC versions: 27, 28, 29

codeunit 84830 "LT CM Trigger Leads"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT CM Log";

    local procedure Reset()
    var
        Row: Record "LT CM Row";
        Parent: Record "LT CM Parent";
        LogRow: Record "LT CM Log Row";
        TempRow: Record "LT CM Temp Row";
        Src: Record "LT CM Src";
        Backup: Record "LT CM Backup";
        InsRow: Record "LT CM Ins Row";
    begin
        Row.DeleteAll();
        Parent.DeleteAll();
        LogRow.DeleteAll();
        TempRow.DeleteAll();
        Src.DeleteAll();
        Backup.DeleteAll();
        InsRow.DeleteAll();
        Log.Take();
    end;

    local procedure SeedRow(Id: Integer; Name: Text[30]; Note: Text[30])
    var
        Row: Record "LT CM Row";
    begin
        Row.Init();
        Row.Id := Id;
        Row.Name := Name;
        Row.Note := Note;
        Row.Insert(false);
    end;

    local procedure LogRows() Result: Text
    var
        LogRow: Record "LT CM Log Row";
    begin
        if LogRow.FindSet() then
            repeat
                Result += LogRow.Txt + ';';
            until LogRow.Next() = 0;
    end;

    // Item 31: a table extension procedure assigns CurrFieldNo, then calls Modify(true); the base OnModify reads it.
    [Test]
    procedure Item31_TableExtension_AssignsCurrFieldNo()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'n', '');
        Row.Get(1);
        Row.CmAssignCurrFieldNoThenModify(10);
        Observer.Observe('modify after ext assigns 10', Log.Take());
        Observer.Expect('modify after ext assigns 10', 'T.OnModify rec=n x=n cur=10;T.OnModify after-assign xnote=;');
        Observer.Verify();
    end;

    // Item 33: Rec.Validate on a field with a TableRelation and an OnValidate trigger, value not in the related table.
    [Test]
    procedure Item33_Validate_BadRelation_TriggerRuns()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Row.Id := 1;
        asserterror Row.Validate(Rel, 'NOPE');
        Observer.ObserveError('validate NOPE');
        Observer.Observe('log', Log.Take());
        Observer.Observe('value after', Row.Rel);
        Observer.Expect('validate NOPE|text', 'The field Rel of table LT CM Row contains a value (NOPE) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('validate NOPE|code', 'DB:PrimRecordNotFound');
        Observer.Expect('log', '');
        Observer.Expect('value after', '');
        Observer.Verify();
    end;

    // Item 33: the same through FieldRef.Validate(Value), and FieldRef.Validate() without a value on an assigned bad value.
    [Test]
    procedure Item33_FieldRefValidate_BadRelation()
    var
        Row: Record "LT CM Row";
        RecRef: RecordRef;
        Fld: FieldRef;
        Parent: Record "LT CM Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Row.Id := 1;
        RecRef.GetTable(Row);
        Fld := RecRef.Field(Row.FieldNo(Rel));
        asserterror Fld.Validate('NOPE');
        Observer.ObserveError('fieldref validate NOPE');
        Observer.Observe('log 1', Log.Take());
        Fld.Value := 'NOPE2';
        asserterror Fld.Validate();
        Observer.ObserveError('fieldref validate() on NOPE2');
        Observer.Observe('log 2', Log.Take());
        Parent.Code := 'P1';
        Parent.Insert();
        Fld.Validate('P1');
        Observer.Observe('log 3 good value', Log.Take());
        Observer.Observe('value 3', Format(Fld.Value));
        Fld := RecRef.Field(Row.FieldNo("Rel False"));
        Fld.Validate('NOPE3');
        Observer.Observe('log 4 relation false', Log.Take());
        Observer.Observe('value 4', Format(Fld.Value));
        Observer.Expect('fieldref validate NOPE|text', 'The field Rel of table LT CM Row contains a value (NOPE) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('fieldref validate NOPE|code', 'DB:PrimRecordNotFound');
        Observer.Expect('log 1', '');
        Observer.Expect('fieldref validate() on NOPE2|text', 'The field Rel of table LT CM Row contains a value (NOPE2) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('fieldref validate() on NOPE2|code', 'DB:PrimRecordNotFound');
        Observer.Expect('log 2', '');
        Observer.Expect('log 3 good value', 'Rel.OnValidate rec=P1;');
        Observer.Expect('value 3', 'P1');
        Observer.Expect('log 4 relation false', 'RelFalse.OnValidate rec=NOPE3;');
        Observer.Expect('value 4', 'NOPE3');
        Observer.Verify();
    end;

    // Item 34: ValidateTableRelation = true and = false on a table field, and the three forms on a tableextension field.
    [Test]
    procedure Item34_ValidateTableRelation_Property()
    var
        Row: Record "LT CM Row";
        InsRow: Record "LT CM Ins Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        asserterror Row.Validate("Rel True", 'NOPE');
        Observer.ObserveError('table true');
        Row.Validate("Rel False", 'NOPE');
        Observer.Observe('table false value', Row."Rel False");
        Log.Take();
        asserterror InsRow.Validate("Ext Rel", 'NOPE');
        Observer.ObserveError('ext default');
        asserterror InsRow.Validate("Ext Rel True", 'NOPE');
        Observer.ObserveError('ext true');
        InsRow.Validate("Ext Rel False", 'NOPE');
        Observer.Observe('ext false value', InsRow."Ext Rel False");
        Observer.Expect('table true|text', 'The field Rel True of table LT CM Row contains a value (NOPE) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('table true|code', 'DB:PrimRecordNotFound');
        Observer.Expect('table false value', 'NOPE');
        Observer.Expect('ext default|text', 'The field Ext Rel of table LT CM Ins Row contains a value (NOPE) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('ext default|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ext true|text', 'The field Ext Rel True of table LT CM Ins Row contains a value (NOPE) that cannot be found in the related table (LT CM Parent).');
        Observer.Expect('ext true|code', 'DB:PrimRecordNotFound');
        Observer.Expect('ext false value', 'NOPE');
        Observer.Verify();
    end;

    // Item 35: fields set by a table extension's OnBeforeInsert, OnInsert and OnAfterInsert; in memory and in the database.
    [Test]
    procedure Item35_TableExtensionInsertTriggers_WhatIsStored()
    var
        InsRow: Record "LT CM Ins Row";
        Stored: Record "LT CM Ins Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        InsRow.Id := 1;
        InsRow.Insert(true);
        Observer.Observe('true memory', InsRow."Set By Before" + '|' + InsRow."Set By Insert" + '|' + InsRow."Set By After");
        Stored.Get(1);
        Observer.Observe('true stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Clear(InsRow);
        InsRow.Id := 2;
        InsRow.Insert(false);
        Observer.Observe('false memory', InsRow."Set By Before" + '|' + InsRow."Set By Insert" + '|' + InsRow."Set By After");
        Stored.Get(2);
        Observer.Observe('false stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Clear(InsRow);
        InsRow.Id := 3;
        InsRow.Insert();
        Stored.Get(3);
        Observer.Observe('no argument stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Finish35(Observer);
    end;

    local procedure Finish35(var Observer: Codeunit "Probe Observer")
    var
        InsRow: Record "LT CM Ins Row";
        Stored: Record "LT CM Ins Row";
    begin
        // A Modify after Insert(true) stores what OnAfterInsert left in the variable.
        InsRow.Id := 4;
        InsRow.Insert(true);
        InsRow.Modify();
        Stored.Get(4);
        Observer.Observe('true then modify stored', Stored."Set By Before" + '|' + Stored."Set By Insert" + '|' + Stored."Set By After");
        Observer.Expect('true memory', 'before|insert|after');
        Observer.Expect('true stored', 'before|insert|');
        Observer.Expect('false memory', '||');
        Observer.Expect('false stored', '||');
        Observer.Expect('no argument stored', '||');
        Observer.Expect('true then modify stored', 'before|insert|after');
        Observer.Verify();
    end;

    // Item 36: inside OnInsert, a row of another table inserted with the SystemId of the row being inserted, found by GetBySystemId.
    [Test]
    procedure Item36_GetBySystemId_InsideOnInsert()
    var
        Src: Record "LT CM Src";
        Backup: Record "LT CM Backup";
        Observer: Codeunit "Probe Observer";
        Mode: Integer;
    begin
        Reset();
        for Mode := 1 to 3 do begin
            Clear(Src);
            Src.Id := Mode;
            Src.Name := 'n' + Format(Mode);
            Src.Mode := Mode;
            Src.Insert(true);
            Observer.Observe('mode ' + Format(Mode), Log.Take());
            Backup.Get(Mode);
            Observer.Observe('mode ' + Format(Mode) + ' stored same sysid', Format(Backup.SystemId = Src.SystemId));
        end;
        Observer.Expect('mode 1', 'src.sysid_null=No;backup.same_sysid=Yes;getbysystemid=Yes;found.name=n1;');
        Observer.Expect('mode 1 stored same sysid', 'Yes');
        Observer.Expect('mode 2', 'src.sysid_null=No;backup.same_sysid=No;getbysystemid=No;');
        Observer.Expect('mode 2 stored same sysid', 'No');
        Observer.Expect('mode 3', 'src.sysid_null=No;backup.same_sysid=No;getbysystemid=No;');
        Observer.Expect('mode 3 stored same sysid', 'No');
        Observer.Verify();
    end;

    // Item 37: triggers of a temporary record write to a real table and delete a real related row.
    [Test]
    procedure Item37_TemporaryRecord_TriggersTouchRealTables()
    var
        TempRow: Record "LT CM Temp Row" temporary;
        RealRow: Record "LT CM Temp Row";
        Parent: Record "LT CM Parent";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Parent.Code := '1';
        Parent.Insert();
        Parent.Code := '2';
        Parent.Insert();
        Parent.Code := '3';
        Parent.Insert();
        RealRow.Id := 9;
        RealRow.Insert(false);

        TempRow.Id := 1;
        TempRow.Insert(true);
        TempRow.Modify(true);
        TempRow.Delete(true);
        Observer.Observe('real log after insert, modify, delete (true)', LogRows());
        Observer.Observe('real parents after delete(true)', ParentCodes());

        TempRow.Id := 2;
        TempRow.Insert(false);
        TempRow.Id := 3;
        TempRow.Insert(false);
        TempRow.Get(2);
        TempRow.Delete(false);
        Observer.Observe('real parents after delete(false)', ParentCodes());
        TempRow.DeleteAll(true);
        Observer.Observe('real log after DeleteAll(true)', LogRows());
        Observer.Observe('real parents after DeleteAll(true)', ParentCodes());
        TempRow.Id := 4;
        TempRow.Insert(false);
        TempRow.DeleteAll();
        Observer.Observe('real rows after temp DeleteAll()', Format(RealRow.Count()));
        Observer.Observe('temp rows after DeleteAll()', Format(TempRow.Count()));
        Observer.Expect('real log after insert, modify, delete (true)', 'OnInsert 1 temp=Yes;OnModify 1;OnDelete 1;');
        Observer.Expect('real parents after delete(true)', '2,3,');
        Observer.Expect('real parents after delete(false)', '2,3,');
        Observer.Expect('real log after DeleteAll(true)', 'OnInsert 1 temp=Yes;OnModify 1;OnDelete 1;OnDelete 3;');
        Observer.Expect('real parents after DeleteAll(true)', '2,');
        Observer.Expect('real rows after temp DeleteAll()', '1');
        Observer.Expect('temp rows after DeleteAll()', '0');
        Observer.Verify();
    end;

    local procedure ParentCodes() Result: Text
    var
        Parent: Record "LT CM Parent";
    begin
        if Parent.FindSet() then
            repeat
                Result += Parent.Code + ',';
            until Parent.Next() = 0;
    end;

    // Item 38: xRec inside OnValidate: the value before Validate, unchanged by assignments to Rec and by a nested Validate.
    [Test]
    procedure Item38_XRecInsideOnValidateAndOnModify()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'old', 'oldnote');
        Row.Get(1);
        Row.Validate(Name, 'new');
        Observer.Observe('validate log', Log.Take());
        Observer.Observe('after validate', Row.Name + '|' + Row.Note);
        Row.Modify(true);
        Observer.Observe('modify log', Log.Take());
        Observer.Observe('after modify', Row.Note);
        Row.Get(1);
        Observer.Observe('stored after modify', Row.Name + '|' + Row.Note);
        Observer.Expect('validate log', 'Name.OnValidate rec=new x=old xnote=oldnote;Name.after-assign xnote=oldnote;Note.OnValidate rec=nested x=oldnote xname=old;Name.after-nested x=old xnote=oldnote note=nested;');
        Observer.Expect('after validate', 'new|nested');
        Observer.Expect('modify log', 'T.OnModify rec=new x=new cur=0;T.OnModify after-assign xnote=nested;');
        Observer.Expect('after modify', 'set-in-modify');
        Observer.Expect('stored after modify', 'new|set-in-modify');
        Observer.Verify();
    end;

    // Item 39: Rec and xRec in OnBeforeModify / OnAfterModify subscribers and the OnModify trigger.
    [Test]
    procedure Item39_ModifyEvents_RecAndXRec()
    var
        Row: Record "LT CM Row";
        Subs: Codeunit "LT CM Modify Subs";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'stored', '');
        BindSubscription(Subs);
        // (a) Get, assign, Modify.
        Row.Get(1);
        Row.Name := 'a';
        Row.Modify(true);
        Observer.Observe('a get assign modify', Log.Take());
        // (b) a record never read: only the key and the new value set.
        Clear(Row);
        Row.Id := 1;
        Row.Name := 'b';
        Row.Modify(true);
        Observer.Observe('b never read', Log.Take());
        // (c) Get, Validate a field, Modify.
        Row.Get(1);
        Row.Validate(Amount, 5);
        Row.Name := 'c';
        Row.Modify(true);
        Observer.Observe('c validate then modify', Log.Take());
        UnbindSubscription(Subs);
        Observer.Expect('a get assign modify', 'S.BeforeModify rec=a x=a;T.OnModify rec=a x=a cur=0;T.OnModify after-assign xnote=;S.AfterModify rec=a x=a;');
        Observer.Expect('b never read', 'S.BeforeModify rec=b x=b;T.OnModify rec=b x=b cur=0;T.OnModify after-assign xnote=;S.AfterModify rec=b x=b;');
        Observer.Expect('c validate then modify', 'S.BeforeModify rec=c x=c;T.OnModify rec=c x=c cur=0;T.OnModify after-assign xnote=set-in-modify;S.AfterModify rec=c x=c;');
        Observer.Verify();
    end;

    // Item 39: the same events for an edit through a card TestPage.
    [Test]
    procedure Item39_ModifyEvents_PageEdit()
    var
        Card: TestPage "LT CM Card";
        Subs: Codeunit "LT CM Modify Subs";
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        SeedRow(1, 'stored', '');
        BindSubscription(Subs);
        Row.Get(1);
        Card.OpenEdit();
        Card.GoToRecord(Row);
        Card.Name.SetValue('pg');
        Card.Close();
        UnbindSubscription(Subs);
        Observer.Observe('page edit', Log.Take());
        Observer.Expect('page edit', 'Name.OnValidate rec=pg x=stored xnote=;Name.after-assign xnote=;Note.OnValidate rec=nested x= xname=stored;Name.after-nested x=stored xnote= note=nested;S.BeforeModify rec=pg x=stored;T.OnModify rec=pg x=stored cur=0;T.OnModify after-assign xnote=;S.AfterModify rec=pg x=stored;');
        Observer.Verify();
    end;

    // Item 40: a new row through a list TestPage, without a filter, with a filter the new key is outside, and inside.
    [Test]
    procedure Item40_PageInsert_FilteredView()
    var
        Row: Record "LT CM Row";
        Observer: Codeunit "Probe Observer";
    begin
        Reset();
        Observer.Observe('no filter', Format(TryNewRow('', 9)));
        Observer.ObserveError('no filter');
        Observer.Observe('no filter log', Log.Take());
        Observer.Observe('no filter stored', Format(Row.Get(9)));
        Observer.Observe('filter 1..5, key 7', Format(TryNewRow('1..5', 7)));
        Observer.ObserveError('filter 1..5, key 7');
        Observer.Observe('filter 1..5, key 7 log', Log.Take());
        Observer.Observe('filter 1..5, key 7 stored', Format(Row.Get(7)));
        Observer.Observe('filter 1..5, key 3', Format(TryNewRow('1..5', 3)));
        Observer.ObserveError('filter 1..5, key 3');
        Observer.Observe('filter 1..5, key 3 log', Log.Take());
        Observer.Observe('filter 1..5, key 3 stored', Format(Row.Get(3)));
        Observer.Expect('no filter', 'Yes');
        Observer.Expect('no filter|text', '');
        Observer.Expect('no filter|code', '');
        Observer.Expect('no filter log', 'P.OnInsertRecord id=9 filters=;P.OnModifyRecord id=9;T.OnModify rec= x= cur=0;T.OnModify after-assign xnote=;');
        Observer.Expect('no filter stored', 'Yes');
        Observer.Expect('filter 1..5, key 7', 'No');
        Observer.Expect('filter 1..5, key 7|text', 'Validation error for Field: ,  Message = ''The view is filtered, and the entry is outside the filter. Some actions may not work.''');
        Observer.Expect('filter 1..5, key 7|code', 'TestValidation');
        Observer.Expect('filter 1..5, key 7 log', 'P.OnInsertRecord id=7 filters=Id: 1..5;P.OnModifyRecord id=7;T.OnModify rec= x= cur=0;T.OnModify after-assign xnote=;');
        Observer.Expect('filter 1..5, key 7 stored', 'Yes');
        Observer.Expect('filter 1..5, key 3', 'Yes');
        Observer.Expect('filter 1..5, key 3|text', '');
        Observer.Expect('filter 1..5, key 3|code', '');
        Observer.Expect('filter 1..5, key 3 log', 'P.OnInsertRecord id=3 filters=Id: 1..5;P.OnModifyRecord id=3;T.OnModify rec= x= cur=0;T.OnModify after-assign xnote=;');
        Observer.Expect('filter 1..5, key 3 stored', 'Yes');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryNewRow(Filter: Text; Id: Integer)
    var
        List: TestPage "LT CM List";
    begin
        List.OpenEdit();
        if Filter <> '' then
            List.Filter.SetFilter(Id, Filter);
        List.New();
        List.Id.SetValue(Id);
        List.Amount.SetValue(1);
        List.Close();
    end;
}
