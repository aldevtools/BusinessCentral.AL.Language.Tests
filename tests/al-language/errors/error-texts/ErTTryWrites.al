// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-handling-errors
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), tables 70064, 70065
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: writes inside TryFunction refused
// BC versions: 29 (27 and 28 by CI)

codeunit 70068 "LT ErT Try Writes"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryInsert(Id: Integer)
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Id := Id;
        Rec.Insert();
    end;

    [TryFunction]
    local procedure TryInsertTrigger(Id: Integer)
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Id := Id;
        Rec.Insert(true);
    end;

    [TryFunction]
    local procedure TryModify(Id: Integer)
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Get(Id);
        Rec.Name := 'changed';
        Rec.Modify();
    end;

    [TryFunction]
    local procedure TryDelete(Id: Integer)
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Get(Id);
        Rec.Delete();
    end;

    [TryFunction]
    local procedure TryDeleteAll()
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
    end;

    [TryFunction]
    local procedure TryModifyAll()
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.ModifyAll(Name, 'x');
    end;

    [TryFunction]
    local procedure TryRead(Id: Integer)
    var
        Rec: Record "LT ErT Rec";
    begin
        Rec.Get(Id);
    end;

    [TryFunction]
    local procedure TryTemporaryInsert()
    var
        Tmp: Record "LT ErT Rec" temporary;
    begin
        Tmp.Id := 1;
        Tmp.Insert();
    end;

    [Test]
    procedure WriteInTryFunctionInsert()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        TryInsert(1);
        Observer.Observe('insert', 'no error');
        TryInsertTrigger(2);
        Observer.Observe('insertTrigger', 'no error');
        Observer.Observe('count', Format(Rec.Count()));
        Observer.Expect('insert', 'no error');
        Observer.Expect('insertTrigger', 'no error');
        Observer.Expect('count', '2');
        Observer.Verify();
    end;

    [Test]
    procedure WriteInTryFunctionModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Name := 'orig';
        Rec.Insert();
        TryModify(1);
        Observer.Observe('modify', 'no error');
        TryDelete(1);
        Observer.Observe('delete', 'no error');
        TryDeleteAll();
        Observer.Observe('deleteAll', 'no error');
        TryModifyAll();
        Observer.Observe('modifyAll', 'no error');
        asserterror Rec.Get(1);
        Observer.ObserveError('af116');
        Observer.Observe('name', Rec.Name);
        Observer.Expect('modify', 'no error');
        Observer.Expect('delete', 'no error');
        Observer.Expect('deleteAll', 'no error');
        Observer.Expect('modifyAll', 'no error');
        Observer.Expect('af116|text', 'The LT ErT Rec does not exist. Identification fields and values: Id=''1''');
        Observer.Expect('af116|code', 'DB:RecordNotFound');
        Observer.Expect('name', 'orig');
        Observer.Verify();
    end;

    [Test]
    procedure ReadAndTemporaryInTryFunction()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "LT ErT Rec";
    begin
        Rec.DeleteAll();
        Rec.Id := 1;
        Rec.Insert();
        Observer.Observe('readExisting', Format(TryRead(1)));
        Observer.Observe('readMissing', Format(TryRead(99)));
        Observer.Observe('readMissingText', GetLastErrorText());
        ClearLastError();
        Observer.Observe('temporaryInsert', Format(TryTemporaryInsert()));
        Observer.Observe('temporaryErrText', GetLastErrorText());
        Observer.Expect('readExisting', 'Yes');
        Observer.Expect('readMissing', 'No');
        Observer.Expect('readMissingText', 'The LT ErT Rec does not exist. Identification fields and values: Id=''99''');
        Observer.Expect('temporaryInsert', 'Yes');
        Observer.Expect('temporaryErrText', '');
        Observer.Verify();
    end;
}
