// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-insert-method
// Fixtures used: ALT Universal (60000)

codeunit 60068 "Test RecordRef CRUD"
{
    Subtype = Test;
    TestPermissions = Disabled;
    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    [Test]
    procedure RecordRef_Insert_NewRecord_RecordExists()
    var
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        RecRef.Open(60000);
        FldRef := RecRef.Field(1);
        FldRef.Value := 1;
        RecRef.Insert();
        Assert.AreEqual(1, RecRef.Count(), 'Count() must return 1 after inserting 1 record via RecordRef');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Modify_ChangedValue_Persisted()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        FldRef: FieldRef;
    begin
        Initialize();
        Rec."Entry No." := 7;
        Rec."Description Field" := 'Original';
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.FindFirst();
        FldRef := RecRef.Field(17);
        FldRef.Value := 'Modified';
        RecRef.Modify();
        Rec.Get(7);
        Assert.AreEqual('Modified', Rec."Description Field", 'Modify() must persist field change to database');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Delete_ExistingRecord_RecordGone()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 5;
        Rec.Insert();
        RecRef.Open(60000);
        RecRef.FindFirst();
        RecRef.Delete();
        Assert.AreEqual(0, RecRef.Count(), 'Count() must return 0 after Delete()');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_DeleteAll_AllGone_IsEmpty()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        RecRef.DeleteAll();
        Assert.IsTrue(RecRef.IsEmpty(), 'IsEmpty() must return true after DeleteAll()');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_FindFirst_NonEmpty_ReturnsTrue()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
    begin
        Initialize();
        Rec."Entry No." := 1;
        Rec.Insert();
        RecRef.Open(60000);
        Assert.IsTrue(RecRef.FindFirst(), 'FindFirst() must return true when table is non-empty');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_FindFirst_Empty_ReturnsFalse()
    var
        RecRef: RecordRef;
    begin
        Initialize();
        RecRef.Open(60000);
        Assert.IsFalse(RecRef.FindFirst(), 'FindFirst() must return false on empty table');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_FindLast_ReturnsLastRecord()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        FldRef: FieldRef;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        RecRef.FindLast();
        FldRef := RecRef.Field(1);
        Assert.AreEqual(3, FldRef.Value, 'Field(1).Value must be 3 after FindLast() on records 1,2,3');
        RecRef.Close();
    end;

    [Test]
    procedure RecordRef_Count_ThreeRecords_ReturnsThree()
    var
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        i: Integer;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        Assert.AreEqual(3, RecRef.Count(), 'Count() must return 3 after inserting 3 records');
        RecRef.Close();
    end;

    // Corpus issue 668 item 50 (writer br): RecordRef.Modify and Delete act on the held record although the RecordRef's filter and
    // current key exclude it; the result and error of both once the row no longer exists.
    [Test]
    procedure RecordRef_ModifyDelete_FilterExcludesHeldRecord()
    var
        Observer: Codeunit "Probe Observer";
        Rec: Record "ALT Universal";
        RecRef: RecordRef;
        i: Integer;
        Ok: Boolean;
    begin
        Initialize();
        for i := 1 to 3 do begin
            Rec."Entry No." := i;
            Rec."Text Field" := 'row ' + Format(i);
            Rec."Integer Field" := 10 * i;
            Rec.Insert();
        end;
        RecRef.Open(60000);
        RecRef.FindFirst();
        RecRef.Field(1).SetRange(2, 3);
        RecRef.Field(3).SetRange(20, 30);
        Observer.Observe('key count', Format(RecRef.KeyCount()));
        RecRef.Field(6).Value := 'changed';
        Ok := RecRef.Modify(false);
        Observer.Observe('modify returns', Format(Ok));
        Rec.Get(1);
        Observer.Observe('row 1 text', Rec."Text Field");
        Observer.Observe('count under filter', Format(RecRef.Count()));
        Ok := RecRef.Delete(false);
        Observer.Observe('delete returns', Format(Ok));
        Rec.Reset();
        Observer.Observe('row 1 exists', Format(Rec.Get(1)));
        Observer.Observe('rows left', Format(Rec.Count()));
        Ok := RecRef.Delete(false);
        Observer.Observe('delete again returns', Format(Ok));
        Ok := RecRef.Modify(false);
        Observer.Observe('modify missing returns', Format(Ok));
        // The statement form of Delete on the deleted row raises RecordNotFound; the statement form of Modify raises no error (27.5, 28.5, 29.0).
        Observer.Observe('delete missing statement', StatementOutcome(RecRef, true));
        Observer.Observe('modify missing statement', StatementOutcome(RecRef, false));
        Observer.Expect('key count', '2');
        Observer.Expect('modify returns', 'Yes');
        Observer.Expect('row 1 text', 'changed');
        Observer.Expect('count under filter', '2');
        Observer.Expect('delete returns', 'Yes');
        Observer.Expect('row 1 exists', 'No');
        Observer.Expect('rows left', '2');
        Observer.Expect('delete again returns', 'No');
        Observer.Expect('modify missing returns', 'No');
        Observer.Expect('delete missing statement', 'The ALT Universal does not exist. Identification fields and values: Entry No.=''1''|DB:RecordNotFound');
        Observer.Expect('modify missing statement', 'no error|Dialog');
        Observer.Verify();
    end;

    local procedure StatementOutcome(var RecRef: RecordRef; DoDelete: Boolean): Text
    begin
        ClearLastError();
        asserterror begin
            if DoDelete then
                RecRef.Delete(false)
            else
                RecRef.Modify(false);
            Error('no error');
        end;
        exit(GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
