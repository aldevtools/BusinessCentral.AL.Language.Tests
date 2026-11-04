// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064, 70065
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: asserterror rollback of writes
// BC versions: 29 (27 and 28 by CI)

codeunit 70069 "LT ErT Rollback"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertThenFail(Id: Integer)
    var
        Log: Record "LT ErT Log";
    begin
        Log.Id := Id;
        Log.Note := 'written';
        Log.Insert();
        Error('fail after insert %1', Id);
    end;

    local procedure ModifyThenFail()
    var
        Log: Record "LT ErT Log";
    begin
        Log.Get(1);
        Log.Note := 'modified';
        Log.Modify();
        Error('fail after modify');
    end;

    local procedure DeleteThenFail()
    var
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Error('fail after deleteall');
    end;

    [Test]
    procedure InsertRolledBack()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        asserterror InsertThenFail(1);
        Observer.ObserveError('insertFail');
        Observer.Observe('count', Format(Log.Count()));
        Observer.Expect('insertFail|text', 'fail after insert 1');
        Observer.Expect('insertFail|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyRolledBack()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Log.Id := 1;
        Log.Note := 'orig';
        Log.Insert();
        asserterror ModifyThenFail();
        Observer.ObserveError('modifyFail');
        asserterror Log.Get(1);
        Observer.ObserveError('af66');
        Observer.Observe('note', Log.Note);
        Observer.Expect('modifyFail|text', 'fail after modify');
        Observer.Expect('modifyFail|code', 'Dialog');
        Observer.Expect('af66|text', 'The LT ErT Log does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af66|code', 'DB:RecordNotFound');
        Observer.Expect('note', 'orig');
        Observer.Verify();
    end;

    [Test]
    procedure DeleteRolledBack()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Log.Id := 1;
        Log.Insert();
        Log.Id := 2;
        Log.Insert();
        asserterror DeleteThenFail();
        Observer.ObserveError('deleteFail');
        Observer.Observe('count', Format(Log.Count()));
        Observer.Expect('deleteFail|text', 'fail after deleteall');
        Observer.Expect('deleteFail|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure EarlierWritesSurviveAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Log.Id := 1;
        Log.Insert();
        asserterror InsertThenFail(2);
        Observer.ObserveError('fail');
        Observer.Observe('count', Format(Log.Count()));
        Observer.Observe('hasOne', Format(Log.Get(1)));
        Observer.Observe('hasTwo', Format(Log.Get(2)));
        Observer.Expect('fail|text', 'fail after insert 2');
        Observer.Expect('fail|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Expect('hasOne', 'No');
        Observer.Expect('hasTwo', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure TwoAsserterrorsInARow()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        asserterror InsertThenFail(1);
        Observer.ObserveError('first');
        asserterror InsertThenFail(1);
        Observer.ObserveError('second');
        Observer.Observe('count', Format(Log.Count()));
        Log.Id := 1;
        Log.Insert();
        Observer.Observe('count2', Format(Log.Count()));
        Observer.Expect('first|text', 'fail after insert 1');
        Observer.Expect('first|code', 'Dialog');
        Observer.Expect('second|text', 'fail after insert 1');
        Observer.Expect('second|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Expect('count2', '1');
        Observer.Verify();
    end;

    [Test]
    procedure CommitInsideTest()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Log.Id := 1;
        Log.Insert();
        Commit();
        asserterror InsertThenFail(2);
        Observer.ObserveError('afterCommit');
        Observer.Observe('count', Format(Log.Count()));
        Log.DeleteAll();
        Commit();
        Observer.Observe('afterCleanup', Format(Log.Count()));
        Observer.Expect('afterCommit|text', 'fail after insert 2');
        Observer.Expect('afterCommit|code', 'Dialog');
        Observer.Expect('count', '1');
        Observer.Expect('afterCleanup', '0');
        Observer.Verify();
    end;

    [Test]
    procedure AsserterrorOnPlainRecordOps()
    var
        Observer: Codeunit "Probe Observer";
        Log: Record "LT ErT Log";
    begin
        Log.DeleteAll();
        Log.Id := 1;
        Log.Insert();
        Log.Note := 'dup';
        Log.Insert();
        Observer.Observe('dupInsert', 'no error');
        asserterror Observer.Observe('count', Format(Log.Count()));
        Observer.ObserveError('af155');
        Log.Id := 5;
        asserterror Log.Modify();
        Observer.ObserveError('modifyMissing');
        asserterror Log.Delete();
        Observer.ObserveError('deleteMissing');
        asserterror Log.Get(77);
        Observer.ObserveError('getMissing');
        Observer.Expect('dupInsert', 'no error');
        Observer.Expect('af155|text', 'The record in table LT ErT Log already exists. Identification fields and values: Id=''1''');
        Observer.Expect('af155|code', 'DB:RecordExists');
        Observer.Expect('modifyMissing|text', 'The LT ErT Log does not exist. Identification fields and values: Id=''5''');
        Observer.Expect('modifyMissing|code', 'DB:RecordNotFound');
        Observer.Expect('deleteMissing|text', 'The LT ErT Log does not exist. Identification fields and values: Id=''5''');
        Observer.Expect('deleteMissing|code', 'DB:RecordNotFound');
        Observer.Expect('getMissing|text', 'The LT ErT Log does not exist. Identification fields and values: Id=''77''');
        Observer.Expect('getMissing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;
}
