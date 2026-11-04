// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
// Scope: in-scope
// Fixtures used: self-contained table 70525
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: Commit, rollback by error and asserterror, LockTable, SetLoadFields with Modify, modify of unchanged records, Rename effects.
// BC versions: 29 (27 and 28 by CI)

table 70525 "LT DbT Tx"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[30]) { }
        field(3; Qty; Integer) { }
        field(4; Note; Text[30]) { }
    }

    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

codeunit 70526 "LT DbT Transactions"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Prep()
    var
        Rec: Record "LT DbT Tx";
    begin
        Rec.DeleteAll(false);
        Commit();
    end;

    local procedure Add(Id: Integer)
    var
        Rec: Record "LT DbT Tx";
    begin
        Rec.Init();
        Rec.Id := Id;
        Rec.Name := 'n' + Format(Id);
        Rec.Qty := Id * 10;
        Rec.Note := 'note' + Format(Id);
        Rec.Insert(false);
    end;

    local procedure FailingWrite()
    var
        Rec: Record "LT DbT Tx";
    begin
        Rec.Id := 500;
        Rec.Insert(false);
        Error('failing write');
    end;

    [Test]
    procedure Commit_ThenAsserterror()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Commit();
        Add(2);
        asserterror FailingWrite();
        Observer.ObserveError('failing write');
        Observer.Observe('count after rollback', Format(Rec.Count()));
        Observer.Observe('row 500', Format(Rec.Get(500)));
        Observer.Observe('row 2', Format(Rec.Get(2)));
        Observer.Expect('failing write|text', 'failing write');
        Observer.Expect('failing write|code', 'Dialog');
        Observer.Expect('count after rollback', '1');
        Observer.Expect('row 500', 'No');
        Observer.Expect('row 2', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Asserterror_RollsBackOwnWritesOnly()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Observer.Observe('count before', Format(Rec.Count()));
        asserterror FailingWrite();
        Observer.ObserveError('failing write');
        Observer.Observe('count after', Format(Rec.Count()));
        Observer.Observe('row 1 exists', Format(Rec.Get(1)));
        Observer.Expect('count before', '1');
        Observer.Expect('failing write|text', 'failing write');
        Observer.Expect('failing write|code', 'Dialog');
        Observer.Expect('count after', '0');
        Observer.Expect('row 1 exists', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_KeepsRowsAfterLaterError()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        Commit();
        Rec.Get(1);
        Rec.Name := 'changed';
        Rec.Modify(true);
        asserterror Error('boom');
        Observer.ObserveError('plain error');
        Rec.Get(1);
        Observer.Observe('name after error', Rec.Name);
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('plain error|text', 'boom');
        Observer.Expect('plain error|code', 'Dialog');
        Observer.Expect('name after error', 'n1');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_AfterCommitRollback()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Commit();
        Rec.Get(1);
        Rec.Qty := 999;
        Rec.Modify(true);
        asserterror Error('boom');
        Observer.ObserveError('error');
        Rec.Get(1);
        Observer.Observe('qty after error', Format(Rec.Qty));
        Observer.Expect('error|text', 'boom');
        Observer.Expect('error|code', 'Dialog');
        Observer.Expect('qty after error', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Delete_AfterCommitRollback()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        Commit();
        Rec.DeleteAll(false);
        Observer.Observe('count after deleteall', Format(Rec.Count()));
        asserterror Error('boom');
        Observer.ObserveError('error');
        Observer.Observe('count after error', Format(Rec.Count()));
        Observer.Expect('count after deleteall', '0');
        Observer.Expect('error|text', 'boom');
        Observer.Expect('error|code', 'Dialog');
        Observer.Expect('count after error', '2');
        Observer.Verify();
    end;

    [Test]
    procedure LockTable_EmptyTable()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Rec.LockTable();
        Observer.Observe('isempty', Format(Rec.IsEmpty()));
        Observer.Observe('findfirst', Format(Rec.FindFirst()));
        Observer.Expect('isempty', 'Yes');
        Observer.Expect('findfirst', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_ModifyKeepsOthers()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Rec.SetLoadFields(Name);
        Rec.Get(1);
        Observer.Observe('loaded name', Rec.Name);
        Observer.Observe('not loaded qty', Format(Rec.Qty));
        Observer.Observe('not loaded note', Rec.Note);
        Rec.Name := 'viaload';
        Rec.Modify(true);
        Rec.Reset();
        Rec.SetLoadFields();
        Rec.Get(1);
        Observer.Observe('name stored', Rec.Name);
        Observer.Observe('qty kept', Format(Rec.Qty));
        Observer.Observe('note kept', Rec.Note);
        Observer.Expect('loaded name', 'n1');
        Observer.Expect('not loaded qty', '10');
        Observer.Expect('not loaded note', 'note1');
        Observer.Expect('name stored', 'viaload');
        Observer.Expect('qty kept', '10');
        Observer.Expect('note kept', 'note1');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_ModifyOtherField()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Rec.SetLoadFields(Name);
        Rec.Get(1);
        Rec.Qty := 77;
        Rec.Modify(true);
        Rec.SetLoadFields();
        Rec.Get(1);
        Observer.Observe('qty stored', Format(Rec.Qty));
        Observer.Observe('name', Rec.Name);
        Observer.Observe('note', Rec.Note);
        Observer.Expect('qty stored', '77');
        Observer.Expect('name', 'n1');
        Observer.Expect('note', 'note1');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_FindSetModify()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
        Total: Integer;
    begin
        Prep();
        Add(1);
        Add(2);
        Add(3);
        Rec.SetLoadFields(Id, Name);
        if Rec.FindSet(true) then
            repeat
                Rec.Name := 'u' + Format(Rec.Id);
                Rec.Modify(true);
            until Rec.Next() = 0;
        Rec.SetLoadFields();
        Rec.FindSet();
        repeat
            Total += Rec.Qty;
        until Rec.Next() = 0;
        Observer.Observe('qty sum kept', Format(Total));
        Rec.Get(2);
        Observer.Observe('name 2', Rec.Name);
        Observer.Observe('note 2', Rec.Note);
        Observer.Expect('qty sum kept', '60');
        Observer.Expect('name 2', 'u2');
        Observer.Expect('note 2', 'note2');
        Observer.Verify();
    end;

    [Test]
    procedure SetLoadFields_AddLoadFieldsAndModify()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Rec.SetLoadFields(Name);
        Rec.AddLoadFields(Qty);
        Rec.Get(1);
        Observer.Observe('qty loaded', Format(Rec.Qty));
        Observer.Observe('note not loaded', Rec.Note);
        Observer.Expect('qty loaded', '10');
        Observer.Expect('note not loaded', 'note1');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_UnchangedAndReturn()
    var
        Rec: Record "LT DbT Tx";
        Other: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        Prep();
        Add(1);
        Rec.Get(1);
        Ok := Rec.Modify(true);
        Observer.Observe('unchanged modify returns', Format(Ok));
        Other.Get(1);
        Other.Qty := 5;
        Other.Modify(true);
        Ok := Rec.Modify(true);
        Observer.Observe('stale modify returns', Format(Ok));
        Rec.Get(1);
        Observer.Observe('qty after stale modify', Format(Rec.Qty));
        Observer.Expect('unchanged modify returns', 'Yes');
        Observer.Expect('stale modify returns', 'Yes');
        Observer.Expect('qty after stale modify', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Modify_StaleRecordOverwrites()
    var
        Rec: Record "LT DbT Tx";
        Other: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Rec.Get(1);
        Other.Get(1);
        Other.Qty := 5;
        Other.Modify(true);
        Rec.Name := 'stale';
        Observer.Observe('stale modify returns', Format(Rec.Modify(true)));
        Rec.Get(1);
        Observer.Observe('name', Rec.Name);
        Observer.Observe('qty', Format(Rec.Qty));
        Observer.Expect('stale modify returns', 'Yes');
        Observer.Expect('name', 'stale');
        Observer.Expect('qty', '10');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_Effects()
    var
        Rec: Record "LT DbT Tx";
        Other: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        Rec.Get(1);
        Rec.Rename(10);
        Observer.Observe('id on var', Format(Rec.Id));
        Observer.Observe('old key exists', Format(Other.Get(1)));
        Observer.Observe('new key exists', Format(Other.Get(10)));
        Observer.Observe('other fields kept', Other.Name + '/' + Format(Other.Qty) + '/' + Other.Note);
        Observer.Observe('count', Format(Other.Count()));
        Observer.Expect('id on var', '10');
        Observer.Expect('old key exists', 'No');
        Observer.Expect('new key exists', 'Yes');
        Observer.Expect('other fields kept', 'n1/10/note1');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_ErrorLeavesRecord()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        Commit();
        Rec.Get(1);
        asserterror Rec.Rename(2);
        Observer.ObserveError('rename onto existing');
        Observer.Observe('id on var', Format(Rec.Id));
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('rename onto existing|text', 'The record in table LT DbT Tx already exists. Identification fields and values: Id=''2''');
        Observer.Expect('rename onto existing|code', 'DB:RecordExists');
        Observer.Expect('id on var', '1');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure Rename_ToZeroAndNegative()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Rec.Get(1);
        Rec.Rename(0);
        Observer.Observe('id', Format(Rec.Id));
        Rec.Rename(-5);
        Observer.Observe('id negative', Format(Rec.Id));
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('id', '0');
        Observer.Expect('id negative', '-5');
        Observer.Expect('count', '1');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_Basics()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        Add(3);
        Rec.SetFilter(Id, '>1');
        Rec.ModifyAll(Qty, 0);
        Rec.Reset();
        Rec.FindSet();
        repeat
            Observer.Observe('qty of ' + Format(Rec.Id), Format(Rec.Qty));
        until Rec.Next() = 0;
        Rec.SetRange(Id, 99);
        Rec.ModifyAll(Qty, 5);
        Observer.Observe('empty set ok', 'done');
        Rec.Reset();
        Rec.ModifyAll(Note, '');
        Rec.FindFirst();
        Observer.Observe('note blank', Rec.Note);
        Observer.Expect('qty of 1', '10');
        Observer.Expect('qty of 2', '0');
        Observer.Expect('qty of 3', '0');
        Observer.Expect('empty set ok', 'done');
        Observer.Expect('note blank', '');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAll_PrimaryKeyField()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Add(2);
        asserterror Rec.ModifyAll(Id, 5);
        Observer.ObserveError('modifyall primary key');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('modifyall primary key|text', 'The MODIFYALL function cannot be used on the Id field in the LT DbT Tx table because it is part of the primary key.');
        Observer.Expect('modifyall primary key|code', 'DB:Ok');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure Commit_InsideAsserterror()
    var
        Rec: Record "LT DbT Tx";
        Observer: Codeunit "Probe Observer";
    begin
        Prep();
        Add(1);
        Commit();
        Add(2);
        Commit();
        Add(3);
        asserterror Error('x');
        Observer.ObserveError('error');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Observe('3 exists', Format(Rec.Get(3)));
        Observer.Expect('error|text', 'x');
        Observer.Expect('error|code', 'Dialog');
        Observer.Expect('count', '2');
        Observer.Expect('3 exists', 'No');
        Observer.Verify();
    end;
}
