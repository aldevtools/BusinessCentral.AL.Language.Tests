// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-insert-method
// Scope: in-scope
// Fixtures used: self-contained tables 72000, 72001, SingleInstance log codeunit 72000 (used only by test codeunit 72001)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: which triggers (OnInsert/OnModify/OnDelete/OnRename/OnValidate) run for Insert/Modify/Delete/Rename/ModifyAll/DeleteAll/Validate with and without RunTrigger, and the errors of
// duplicate key, record not found and rename onto an existing key.
// BC versions: 29 (27 and 28 by CI)

table 72000 "LT RcB Trg"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT RcB Log";
            begin
                Log.Add('VId');
            end;
        }
        field(2; Name; Text[30])
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT RcB Log";
            begin
                Log.Add('VName');
            end;
        }
        field(3; Amount; Decimal)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT RcB Log";
            begin
                Log.Add('VAmount');
            end;
        }
        field(4; Qty; Integer)
        {
            trigger OnValidate()
            var
                Log: Codeunit "LT RcB Log";
            begin
                Log.Add('VQty');
                if Qty < 0 then
                    Error('Qty must not be negative');
            end;
        }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    var
        Log: Codeunit "LT RcB Log";
    begin
        Log.Add('I' + Format(Id));
    end;

    trigger OnModify()
    var
        Log: Codeunit "LT RcB Log";
    begin
        Log.Add('M' + Format(Id));
    end;

    trigger OnDelete()
    var
        Log: Codeunit "LT RcB Log";
    begin
        Log.Add('D' + Format(Id));
    end;

    trigger OnRename()
    var
        Log: Codeunit "LT RcB Log";
    begin
        Log.Add('R' + Format(xRec.Id) + '>' + Format(Id));
    end;
}

table 72001 "LT RcB Trg Fail"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }

    trigger OnInsert()
    begin
        if Name = 'fail' then
            Error('insert refused for %1', Id);
    end;

    trigger OnModify()
    begin
        if Name = 'fail' then
            Error('modify refused for %1', Id);
    end;

    trigger OnDelete()
    begin
        if Name = 'fail' then
            Error('delete refused for %1', Id);
    end;

    trigger OnRename()
    begin
        Error('rename refused');
    end;
}

codeunit 72000 "LT RcB Log"
{
    SingleInstance = true;

    var
        Entries: Text;

    procedure Add(Entry: Text)
    begin
        if Entries <> '' then
            Entries += ',';
        Entries += Entry;
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

codeunit 72001 "LT RcB Triggers"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep(var Rec: Record "LT RcB Trg")
    var
        Log: Codeunit "LT RcB Log";
    begin
        Rec.DeleteAll(false);
        Log.Take();
    end;

    local procedure Seed(Count: Integer)
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        i: Integer;
    begin
        for i := 1 to Count do begin
            Rec.Init();
            Rec.Id := i;
            Rec.Name := 'n' + Format(i);
            Rec.Amount := i * 10;
            Rec.Insert(false);
        end;
        Log.Take();
    end;

    [Test]
    procedure Insert_Trigger()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep(Rec);
        Rec.Id := 1;
        Rec.Insert(true);
        Observer.Observe('insert true', Log.Take());
        Rec.Id := 2;
        Rec.Insert(false);
        Observer.Observe('insert false', Log.Take());
        Rec.Id := 3;
        Rec.Insert();
        Observer.Observe('insert default', Log.Take());
        Rec.Id := 4;
        Ok := Rec.Insert(true);
        Observer.Observe('insert returns', Format(Ok));
        Observer.Observe('count', Format(Rec.Count()));
        Rec.Id := 5;
        Rec.Name := 'with name';
        Rec.Insert(true);
        Observer.Observe('assign no validate', Log.Take());
        Observer.Expect('insert true', 'I1');
        Observer.Expect('insert false', '');
        Observer.Expect('insert default', '');
        Observer.Expect('insert returns', 'Yes');
        Observer.Expect('count', '4');
        Observer.Expect('assign no validate', 'I4,I5');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_DuplicateBoolean()
    var
        Rec: Record "LT RcB Trg";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(1);
        Rec.Id := 1;
        Observer.Observe('dup in if', Format(Rec.Insert()));
        Rec.Id := 1;
        Observer.Observe('dup in if no trigger', Format(Rec.Insert(false)));
        Observer.Expect('dup in if', 'No');
        Observer.Expect('dup in if no trigger', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Insert_TriggerError()
    var
        Rec: Record "LT RcB Trg Fail";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll(false);
        Rec.Id := 1;
        Rec.Name := 'fail';
        asserterror Rec.Insert(true);
        Observer.ObserveError('insert trigger error');
        Observer.Observe('count', Format(Rec.Count()));
        Rec.Insert(false);
        Observer.Observe('count no trigger', Format(Rec.Count()));
        Observer.Expect('insert trigger error|text', 'insert refused for 1');
        Observer.Expect('insert trigger error|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Expect('count no trigger', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_Trigger()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.Get(1);
        Rec.Name := 'changed';
        Rec.Modify(true);
        Observer.Observe('modify true', Log.Take());
        Rec.Name := 'changed2';
        Rec.Modify(false);
        Observer.Observe('modify false', Log.Take());
        Rec.Name := 'changed3';
        Rec.Modify();
        Observer.Observe('modify default', Log.Take());
        Rec.Modify(true);
        Observer.Observe('modify unchanged', Log.Take());
        Observer.Observe('returns', Format(Rec.Modify(true)));
        Log.Take();
        Rec.Get(1);
        Observer.Observe('name', Rec.Name);
        Observer.Expect('modify true', 'M1');
        Observer.Expect('modify false', '');
        Observer.Expect('modify default', '');
        Observer.Expect('modify unchanged', 'M1');
        Observer.Expect('returns', 'Yes');
        Observer.Expect('name', 'changed3');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_NotFound()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(1);
        Rec.Id := 99;
        asserterror Rec.Modify(true);
        Observer.ObserveError('modify missing true');
        Observer.Observe('log', Log.Take());
        asserterror Rec.Modify(false);
        Observer.ObserveError('modify missing false');
        asserterror Rec.Modify();
        Observer.ObserveError('modify missing default');
        Rec.Init();
        asserterror Rec.Modify();
        Observer.ObserveError('modify init record');
        Observer.Expect('modify missing true|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('modify missing true|code', 'DB:RecordNotFound');
        Observer.Expect('log', 'M99');
        Observer.Expect('modify missing false|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('modify missing false|code', 'DB:RecordNotFound');
        Observer.Expect('modify missing default|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('modify missing default|code', 'DB:RecordNotFound');
        Observer.Expect('modify init record|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('modify init record|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_Trigger()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(5);
        Rec.Get(1);
        Rec.Delete(true);
        Observer.Observe('delete true', Log.Take());
        Rec.Get(2);
        Rec.Delete(false);
        Observer.Observe('delete false', Log.Take());
        Rec.Get(3);
        Rec.Delete();
        Observer.Observe('delete default', Log.Take());
        Observer.Observe('returns', Format(Rec.Get(4)));
        Observer.Observe('delete returns', Format(Rec.Delete(true)));
        Log.Take();
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('delete true', 'D1');
        Observer.Expect('delete false', '');
        Observer.Expect('delete default', '');
        Observer.Expect('returns', 'Yes');
        Observer.Expect('delete returns', 'Yes');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_NotFound()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(1);
        Rec.Id := 50;
        asserterror Rec.Delete(true);
        Observer.ObserveError('delete missing true');
        Observer.Observe('log', Log.Take());
        asserterror Rec.Delete(false);
        Observer.ObserveError('delete missing false');
        asserterror Rec.Delete();
        Observer.ObserveError('delete missing default');
        Observer.Observe('boolean form', Format(Rec.Delete()));
        Observer.Expect('delete missing true|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''50''');
        Observer.Expect('delete missing true|code', 'DB:RecordNotFound');
        Observer.Expect('log', 'D50');
        Observer.Expect('delete missing false|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''50''');
        Observer.Expect('delete missing false|code', 'DB:RecordNotFound');
        Observer.Expect('delete missing default|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''50''');
        Observer.Expect('delete missing default|code', 'DB:RecordNotFound');
        Observer.Expect('boolean form', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Trigger()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.Get(1);
        Rec.Rename(11);
        Observer.Observe('rename', Log.Take());
        Observer.Observe('id after', Format(Rec.Id));
        Observer.Observe('old exists', Format(Rec.Get(1)));
        Observer.Observe('new exists', Format(Rec.Get(11)));
        Observer.Observe('name kept', Rec.Name);
        Log.Take();
        Rec.Get(2);
        Rec.Rename(2);
        Observer.Observe('rename same', Log.Take());
        Observer.Expect('rename', 'R1>11');
        Observer.Expect('id after', '11');
        Observer.Expect('old exists', 'No');
        Observer.Expect('new exists', 'Yes');
        Observer.Expect('name kept', 'n1');
        Observer.Expect('rename same', 'R2>2');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Errors()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.Get(1);
        asserterror Rec.Rename(2);
        Observer.ObserveError('rename onto existing');
        Observer.Observe('log', Log.Take());
        Rec.Id := 77;
        asserterror Rec.Rename(78);
        Observer.ObserveError('rename missing');
        Observer.Expect('rename onto existing|text', 'The record in table LT RcB Trg already exists. Identification fields and values: Id=''2''');
        Observer.Expect('rename onto existing|code', 'DB:RecordExists');
        Observer.Expect('log', 'R1>2');
        Observer.Expect('rename missing|text', 'The LT RcB Trg does not exist. Identification fields and values: Id=''77''');
        Observer.Expect('rename missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_TriggerError()
    var
        Rec: Record "LT RcB Trg Fail";
        Observer: Codeunit "Probe Observer";
    begin
        Rec.DeleteAll(false);
        Rec.Id := 1;
        Rec.Insert(false);
        asserterror Rec.Rename(2);
        Observer.ObserveError('rename trigger error');
        Observer.Expect('rename trigger error|text', 'rename refused');
        Observer.Expect('rename trigger error|code', 'Dialog');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Triggers()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.ModifyAll(Name, 'all');
        Observer.Observe('modifyall default', Log.Take());
        Rec.ModifyAll(Name, 'all2', false);
        Observer.Observe('modifyall false', Log.Take());
        Rec.ModifyAll(Name, 'all3', true);
        Observer.Observe('modifyall true', Log.Take());
        Rec.ModifyAll(Amount, 5, true);
        Observer.Observe('modifyall amount true', Log.Take());
        Rec.FindFirst();
        Observer.Observe('name', Rec.Name);
        Observer.Observe('amount', Format(Rec.Amount));
        Observer.Expect('modifyall default', '');
        Observer.Expect('modifyall false', '');
        Observer.Expect('modifyall true', 'M1,M2,M3');
        Observer.Expect('modifyall amount true', 'M1,M2,M3');
        Observer.Expect('name', 'all3');
        Observer.Expect('amount', '5');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Filtered_Empty()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(4);
        Rec.SetFilter(Id, '2..3');
        Rec.ModifyAll(Name, 'part', true);
        Observer.Observe('filtered', Log.Take());
        Rec.SetRange(Id, 100);
        Rec.ModifyAll(Name, 'none', true);
        Observer.Observe('empty set', Log.Take());
        Rec.Reset();
        Rec.SetRange(Id, 1);
        Rec.FindFirst();
        Observer.Observe('untouched', Rec.Name);
        Observer.Expect('filtered', 'M2,M3');
        Observer.Expect('empty set', '');
        Observer.Expect('untouched', 'n1');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_ValidateFailure()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.ModifyAll(Qty, -1, true);
        Observer.Observe('modifyall validate error', 'no error');
        Observer.Observe('log', Log.Take());
        Rec.ModifyAll(Qty, -1, false);
        Rec.FindFirst();
        Observer.Observe('qty without validate', Format(Rec.Qty));
        Observer.Expect('modifyall validate error', 'no error');
        Observer.Expect('log', 'M1,M2,M3');
        Observer.Expect('qty without validate', '-1');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteAll_Triggers()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Seed(3);
        Rec.DeleteAll();
        Observer.Observe('deleteall default', Log.Take());
        Observer.Observe('count', Format(Rec.Count()));
        Seed(3);
        Rec.DeleteAll(false);
        Observer.Observe('deleteall false', Log.Take());
        Seed(3);
        Rec.DeleteAll(true);
        Observer.Observe('deleteall true', Log.Take());
        Seed(4);
        Rec.SetFilter(Id, '>2');
        Rec.DeleteAll(true);
        Observer.Observe('deleteall filtered', Log.Take());
        Rec.Reset();
        Observer.Observe('left', Format(Rec.Count()));
        Rec.SetRange(Id, 1000);
        Rec.DeleteAll(true);
        Observer.Observe('empty', Log.Take());
        Observer.Expect('deleteall default', '');
        Observer.Expect('count', '0');
        Observer.Expect('deleteall false', '');
        Observer.Expect('deleteall true', 'D1,D2,D3');
        Observer.Expect('deleteall filtered', 'D3,D4');
        Observer.Expect('left', '2');
        Observer.Expect('empty', '');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Triggers()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Rec.Validate(Name, 'v');
        Observer.Observe('validate name', Log.Take());
        Rec.Validate(Amount, 3);
        Observer.Observe('validate amount', Log.Take());
        Rec.Validate(Id, 5);
        Observer.Observe('validate id', Log.Take());
        Rec.Validate(Name);
        Observer.Observe('validate no value', Log.Take());
        Rec.Name := 'assigned';
        Observer.Observe('assignment', Log.Take());
        Rec.Validate(Qty, 4);
        Observer.Observe('qty ok', Log.Take());
        asserterror Rec.Validate(Qty, -1);
        Observer.ObserveError('qty error');
        Observer.Observe('qty after error', Format(Rec.Qty));
        Observer.Observe('log', Log.Take());
        Observer.Expect('validate name', 'VName');
        Observer.Expect('validate amount', 'VAmount');
        Observer.Expect('validate id', 'VId');
        Observer.Expect('validate no value', 'VName');
        Observer.Expect('assignment', '');
        Observer.Expect('qty ok', 'VQty');
        Observer.Expect('qty error|text', 'Qty must not be negative');
        Observer.Expect('qty error|code', 'Dialog');
        Observer.Expect('qty after error', '4');
        Observer.Expect('log', 'VQty');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_SameValue_Truncation()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Rec.Name := 'same';
        Rec.Validate(Name, 'same');
        Observer.Observe('same value', Log.Take());
        asserterror Rec.Validate(Name, 'this text is much longer than thirty characters');
        Observer.ObserveError('too long');
        Rec.Validate(Amount, 1.123456789);
        Observer.Observe('amount', Format(Rec.Amount));
        Log.Take();
        Observer.Expect('same value', 'VName');
        Observer.Expect('too long|text', 'The length of the string is 47, but it must be less than or equal to 30 characters. Value: this text is much longer than thirty characters');
        Observer.Expect('too long|code', 'StringLengthExceeded');
        Observer.Expect('amount', '1.123456789');
        Observer.Verify();
    end;

    [Test]
    procedure Validate_Chain_RecordVariable()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
    begin
        Prep(Rec);
        Rec.Validate(Id, 1);
        Rec.Validate(Name, 'a');
        Rec.Insert(true);
        Observer.Observe('validate then insert', Log.Take());
        Rec.Validate(Name, 'b');
        Rec.Modify(true);
        Observer.Observe('validate then modify', Log.Take());
        Observer.Expect('validate then insert', 'VId,VName,I1');
        Observer.Expect('validate then modify', 'VName,M1');
        Observer.Verify();
    end;

    // Corpus issue 668 items 25 and 30 (writer BQ).
    // Record.Delete (return value used) and RecordRef.Delete of a row that the record's filters exclude (docs: the Record page says Delete takes filters into
    // account, the RecordRef page says filters do not affect it).
    [Test]
    procedure Delete_Row_Outside_The_Filters_BQ()
    var
        Rec: Record "LT RcB Trg";
        Check: Record "LT RcB Trg";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
        Deleted: Boolean;
    begin
        Prep(Rec);
        Seed(4);
        Rec.SetRange(Id, 3, 4);
        Rec.Id := 1;
        Deleted := Rec.Delete();
        Observer.Observe('recordDeleted', Format(Deleted));
        Observer.Observe('recordLastError', GetLastErrorText());
        Observer.Observe('row1Exists', Format(Check.Get(1)));
        Rec.Get(2);
        Deleted := Rec.Delete();
        Observer.Observe('afterGetDeleted', Format(Deleted));
        Observer.Observe('row2Exists', Format(Check.Get(2)));
        RecRef.Open(Database::"LT RcB Trg");
        RecRef.Field(1).SetRange(4);
        RecRef.Field(1).Value := 3;
        Observer.Observe('recRefDeleted', Format(RecRef.Delete()));
        Observer.Observe('row3Exists', Format(Check.Get(3)));
        Observer.Expect('recordDeleted', 'Yes');
        Observer.Expect('recordLastError', '');
        Observer.Expect('row1Exists', 'No');
        Observer.Expect('afterGetDeleted', 'Yes');
        Observer.Expect('row2Exists', 'No');
        Observer.Expect('recRefDeleted', 'Yes');
        Observer.Expect('row3Exists', 'No');
        Observer.Verify();
    end;

    // ModifyAll to the value a row already has: is that row written (OnModify with RunTrigger true, SystemModifiedAt)? (docs: ModifyAll)
    [Test]
    procedure ModifyAll_Equal_Value_Rows_BQ()
    var
        Rec: Record "LT RcB Trg";
        Log: Codeunit "LT RcB Log";
        Observer: Codeunit "Probe Observer";
        Before1: DateTime;
        Before2: DateTime;
    begin
        Prep(Rec);
        Seed(2);
        Rec.Get(1);
        Before1 := Rec.SystemModifiedAt;
        Rec.Get(2);
        Before2 := Rec.SystemModifiedAt;
        Sleep(50);
        Rec.Reset();
        Rec.ModifyAll(Amount, 10, true);
        Observer.Observe('log', Log.Take());
        Rec.Get(1);
        Observer.Observe('row1Amount', Format(Rec.Amount));
        Observer.Observe('row1StampChanged', Format(Rec.SystemModifiedAt <> Before1));
        Rec.Get(2);
        Observer.Observe('row2Amount', Format(Rec.Amount));
        Observer.Observe('row2StampChanged', Format(Rec.SystemModifiedAt <> Before2));
        Rec.Get(1);
        Before1 := Rec.SystemModifiedAt;
        Sleep(50);
        Rec.Reset();
        Rec.ModifyAll(Amount, 10, false);
        Observer.Observe('logFalse', Log.Take());
        Rec.Get(1);
        Observer.Observe('row1StampChangedFalse', Format(Rec.SystemModifiedAt <> Before1));
        Observer.Expect('log', 'M1,M2');
        Observer.Expect('row1Amount', '10');
        Observer.Expect('row1StampChanged', 'No');
        Observer.Expect('row2Amount', '10');
        Observer.Expect('row2StampChanged', 'Yes');
        Observer.Expect('logFalse', '');
        Observer.Expect('row1StampChangedFalse', 'Yes');
        Observer.Verify();
    end;

    // ModifyAll on a FlowFilter field compiles (a FlowField does not: tests/must-not-compile/cases/1452-modifyall-flowfield.al); what it
    // does at run time (docs: diagnostic AL0780).
    [Test]
    procedure ModifyAll_FlowFilter_Field_BQ()
    var
        Owner: Record "LT BQ FG Owner";
        BqSeed: Codeunit "LT BQ Seed";
        Observer: Codeunit "Probe Observer";
    begin
        BqSeed.Owners();
        Owner.ModifyAll(IdFilter, 3);
        Observer.Observe('modifyAll', 'no error');
        Observer.Observe('flowFilterOnVariable', Owner.GetFilter(IdFilter));
        Observer.Observe('count', Format(Owner.Count()));
        Owner.Get(3);
        Owner.CalcFields(Total);
        Observer.Observe('total3', Format(Owner.Total));
        Observer.Expect('modifyAll', 'no error');
        Observer.Expect('flowFilterOnVariable', '');
        Observer.Expect('count', '3');
        Observer.Expect('total3', '7');
        Observer.Verify();
    end;
}
