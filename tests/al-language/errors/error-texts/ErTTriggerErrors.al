// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064, 70065
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: errors in table triggers with partial writes
// BC versions: 29 (27 and 28 by CI)

codeunit 70074 "LT ErT Trigger Errors"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure InsertTwo()
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Id := 1;
        Rec.Name := 'ok';
        Rec.Insert(true);
        Rec.Id := 2;
        Rec.Name := 'FailInsert';
        Rec.Insert(true);
    end;

    [Test]
    procedure OnInsertErrorRaisedOnlyWithTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'FailInsert';
        Rec.Insert(false);
        Observer.Observe('noTriggerCount', Format(Rec.Count()));
        Rec.Id := 2;
        asserterror Rec.Insert(true);
        Observer.ObserveError('withTrigger');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('noTriggerCount', '1');
        Observer.Expect('withTrigger|text', 'Insert refused for 2');
        Observer.Expect('withTrigger|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure PartialWritesRolledBackByAsserterror()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        asserterror InsertTwo();
        Observer.ObserveError('insertTwo');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('insertTwo|text', 'Insert refused for 2');
        Observer.Expect('insertTwo|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Verify();
    end;

    [Test]
    procedure OnModifyError()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'orig';
        Rec.Insert();
        Rec.Name := 'FailModify';
        asserterror Rec.Modify(true);
        Observer.ObserveError('modifyTrigger');
        asserterror Rec.Get(1);
        Observer.ObserveError('af69');
        Observer.Observe('nameAfter', Rec.Name);
        Rec.Name := 'FailModify';
        asserterror Rec.Modify(false);
        Observer.ObserveError('af73');
        asserterror Rec.Get(1);
        Observer.ObserveError('af75');
        Observer.Observe('nameNoTrigger', Rec.Name);
        Observer.Expect('modifyTrigger|text', 'Modify refused for 1');
        Observer.Expect('modifyTrigger|code', 'Dialog');
        Observer.Expect('af69|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af69|code', 'DB:RecordNotFound');
        Observer.Expect('nameAfter', 'FailModify');
        Observer.Expect('af73|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af73|code', 'DB:RecordNotFound');
        Observer.Expect('af75|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af75|code', 'DB:RecordNotFound');
        Observer.Expect('nameNoTrigger', 'FailModify');
        Observer.Verify();
    end;

    [Test]
    procedure OnDeleteError()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'FailDelete';
        Rec.Insert();
        asserterror Rec.Delete(true);
        Observer.ObserveError('deleteTrigger');
        Observer.Observe('count', Format(Rec.Count()));
        Rec.DeleteAll(true);
        Observer.Observe('deleteAllTrigger', 'no error');
        Observer.Observe('countAfterDeleteAll', Format(Rec.Count()));
        Rec.DeleteAll(false);
        Observer.Observe('countNoTrigger', Format(Rec.Count()));
        Observer.Expect('deleteTrigger|text', 'Delete refused for 1');
        Observer.Expect('deleteTrigger|code', 'Dialog');
        Observer.Expect('count', '0');
        Observer.Expect('deleteAllTrigger', 'no error');
        Observer.Expect('countAfterDeleteAll', '0');
        Observer.Expect('countNoTrigger', '0');
        Observer.Verify();
    end;

    [Test]
    procedure ModifyAllWithTriggerError()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'a';
        Rec.Insert();
        Rec.Id := 2;
        Rec.Name := 'b';
        Rec.Insert();
        asserterror Rec.ModifyAll(Name, 'FailModify', true);
        Observer.ObserveError('modifyAll');
        asserterror Rec.FindSet();
        Observer.ObserveError('af115');
        Observer.Observe('first', Rec.Name);
        Rec.Next();
        Observer.Observe('second', Rec.Name);
        Observer.Expect('modifyAll|text', 'Modify refused for 1');
        Observer.Expect('modifyAll|code', 'Dialog');
        Observer.Expect('af115|text', 'The LT ErT Rec table is empty.');
        Observer.Expect('af115|code', 'DB:TableIsEmpty');
        Observer.Expect('first', 'b');
        Observer.Expect('second', 'b');
        Observer.Verify();
    end;
}
