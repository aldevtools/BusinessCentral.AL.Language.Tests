// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-modify-method
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Stale buffer: Modify, Commit, Modify, asserterror Error, then Modify again through the same buffer: saved or refused. Tests that Commit delete their rows at the end.
// BC versions: 29 (27 and 28 by CI)

table 70355 "LT P98 StaleRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Counter; Integer) { }
        field(3; Note; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70356 "LT P98 StaleBuffer"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure P98_Stale_AfterAsserterror_SameBuffer()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 StaleRow";
        Check: Record "LT P98 StaleRow";
    begin
        R.DeleteAll();
        R.Id := 'S1';
        R.Insert();
        R.Counter := 1;
        R.Modify();
        Commit();
        R.Counter := 2;
        R.Modify();
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Observer.Observe('buffer', Format(R.Counter));
        Check.Get('S1');
        Observer.Observe('dbAfterError', Format(Check.Counter));
        R.Counter := 3;
        Observer.Observe('modify', Format(R.Modify()));
        Check.Get('S1');
        Observer.Observe('dbAfterModify', Format(Check.Counter));
        R.DeleteAll();
        Commit();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('buffer', '2');
        Observer.Expect('dbAfterError', '1');
        Observer.Expect('modify', 'Yes');
        Observer.Expect('dbAfterModify', '3');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Stale_BufferNotReassigned()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 StaleRow";
        Check: Record "LT P98 StaleRow";
    begin
        R.DeleteAll();
        R.Id := 'S2';
        R.Counter := 10;
        R.Note := 'orig';
        R.Insert();
        Commit();
        R.Counter := 11;
        R.Modify();
        asserterror Error('boom');
        Observer.ObserveError('boom');
        Observer.Observe('bufferCounter', Format(R.Counter));
        Observer.Observe('modifyNoChange', Format(R.Modify()));
        Check.Get('S2');
        Observer.Observe('db', Format(Check.Counter) + '|' + Check.Note);
        R.DeleteAll();
        Commit();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('bufferCounter', '11');
        Observer.Expect('modifyNoChange', 'Yes');
        Observer.Expect('db', '10|orig');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Stale_RowChangedByOtherBuffer()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 StaleRow";
        Other: Record "LT P98 StaleRow";
        Check: Record "LT P98 StaleRow";
    begin
        R.DeleteAll();
        R.Id := 'S3';
        R.Counter := 1;
        R.Note := 'n1';
        R.Insert();
        R.Get('S3');
        Other.Get('S3');
        Other.Counter := 50;
        Other.Modify();
        R.Note := 'n2';
        Observer.Observe('modifyStale', Format(R.Modify()));
        Check.Get('S3');
        Observer.Observe('db', Format(Check.Counter) + '|' + Check.Note);
        R.DeleteAll();
        Observer.Expect('modifyStale', 'Yes');
        Observer.Expect('db', '1|n2');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Stale_ModifyAfterRowDeleted()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 StaleRow";
        Other: Record "LT P98 StaleRow";
    begin
        R.DeleteAll();
        R.Id := 'S4';
        R.Insert();
        Other.Get('S4');
        Other.Delete();
        R.Counter := 5;
        asserterror R.Modify();
        Observer.ObserveError('modifyDeleted');
        Observer.Observe('modifyFalse', Format(R.Modify(false)));
        Observer.Expect('modifyDeleted|text', 'The LT P98 StaleRow does not exist. Identification fields and values: Id=''S4''');
        Observer.Expect('modifyDeleted|code', 'DB:RecordNotFound');
        Observer.Expect('modifyFalse', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Stale_CommitThenErrorThenModify_Rec()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 StaleRow";
        Check: Record "LT P98 StaleRow";
    begin
        R.DeleteAll();
        R.Id := 'S5';
        R.Counter := 1;
        R.Insert();
        Commit();
        R.Counter := 2;
        R.Modify();
        Commit();
        R.Counter := 3;
        R.Modify();
        asserterror Error('boom');
        Observer.ObserveError('boom');
        R.Note := 'late';
        R.Modify();
        Check.Get('S5');
        Observer.Observe('db', Format(Check.Counter) + '|' + Check.Note);
        Observer.Observe('buf', Format(R.Counter) + '|' + R.Note);
        R.DeleteAll();
        Commit();
        Observer.Expect('boom|text', 'boom');
        Observer.Expect('boom|code', 'Dialog');
        Observer.Expect('db', '3|late');
        Observer.Expect('buf', '3|late');
        Observer.Verify();
    end;
}
