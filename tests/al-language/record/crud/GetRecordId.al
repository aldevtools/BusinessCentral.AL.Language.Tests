// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/record/record-get-method
// Scope: in-scope
// Fixtures used: self-contained
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Record.Get(RecordId) on a missing row (result used and unused, TryFunction, asserterror) and with a RecordId of another table.
// BC versions: 29 (27 and 28 by CI)

table 70338 "LT P98 GetRow"
{
    fields
    {
        field(1; Id; Code[10]) { }
        field(2; Info; Text[30]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

table 70339 "LT P98 GetOther"
{
    fields
    {
        field(1; Id; Integer) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 70340 "LT P98 GetRecordId"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryGet(var R: Record "LT P98 GetRow"; Id: RecordId)
    begin
        R.Get(Id);
    end;

    local procedure Reset()
    var
        R: Record "LT P98 GetRow";
        O: Record "LT P98 GetOther";
    begin
        R.DeleteAll();
        O.DeleteAll();
    end;

    [Test]
    procedure P98_Get_RecordId_Found()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        R2: Record "LT P98 GetRow";
    begin
        Reset();
        R.Id := 'A';
        R.Info := 'found';
        R.Insert();
        Observer.Observe('result', Format(R2.Get(R.RecordId)));
        Observer.Observe('info', R2.Info);
        Observer.Observe('id', R2.Id);
        Observer.Expect('result', 'Yes');
        Observer.Expect('info', 'found');
        Observer.Expect('id', 'A');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_Missing_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        R2: Record "LT P98 GetRow";
    begin
        Reset();
        R.Id := 'GONE';
        R.Info := 'x';
        R2.Id := 'KEEP';
        R2.Info := 'keep';
        Observer.Observe('result', Format(R2.Get(R.RecordId)));
        Observer.Observe('id', R2.Id);
        Observer.Observe('info', R2.Info);
        Observer.Expect('result', 'No');
        Observer.Expect('id', 'KEEP');
        Observer.Expect('info', 'keep');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_Missing_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        R2: Record "LT P98 GetRow";
    begin
        Reset();
        R.Id := 'GONE';
        asserterror R2.Get(R.RecordId);
        Observer.ObserveError('missing');
        Observer.Expect('missing|text', 'The LT P98 GetRow does not exist. Identification fields and values: Id=''GONE''');
        Observer.Expect('missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_Missing_Try()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        R2: Record "LT P98 GetRow";
    begin
        Reset();
        R.Id := 'GONE';
        Observer.Observe('try', Format(TryGet(R2, R.RecordId)));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('try', 'No');
        Observer.Expect('text', 'The LT P98 GetRow does not exist. Identification fields and values: Id=''GONE''');
        Observer.Expect('code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_OtherTable()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        O: Record "LT P98 GetOther";
        Ok: Boolean;
    begin
        Reset();
        O.Id := 5;
        O.Insert();
        asserterror R.Get(O.RecordId);
        Observer.ObserveError('unused');
        Ok := TryGet(R, O.RecordId);
        Observer.Observe('try', Format(Ok));
        Observer.Observe('text', GetLastErrorText());
        Observer.Observe('code', GetLastErrorCode());
        Observer.Expect('unused|text', 'A RecordID from table ''LT P98 GetOther'' cannot be used with a record from table ''LT P98 GetRow''.');
        Observer.Expect('unused|code', 'DB:Ok');
        Observer.Expect('try', 'No');
        Observer.Expect('text', 'A RecordID from table ''LT P98 GetOther'' cannot be used with a record from table ''LT P98 GetRow''.');
        Observer.Expect('code', 'DB:Ok');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_OtherTable_ResultUsed()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        O: Record "LT P98 GetOther";
        Ok: Boolean;
    begin
        Reset();
        O.Id := 5;
        O.Insert();
        Ok := R.Get(O.RecordId);
        Observer.Observe('used', 'no error');
        Observer.Observe('ok', Format(Ok));
        Observer.Expect('used', 'no error');
        Observer.Expect('ok', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P98_Get_RecordId_Empty()
    var
        Observer: Codeunit "Probe Observer";
        R: Record "LT P98 GetRow";
        Empty: RecordId;
        Ok: Boolean;
    begin
        Reset();
        Ok := R.Get(Empty);
        Observer.Observe('empty', 'no error');
        Observer.Observe('ok', Format(Ok));
        Observer.Expect('empty', 'no error');
        Observer.Expect('ok', 'No');
        Observer.Verify();
    end;
}
