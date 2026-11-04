// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160), self-contained tables 73629, 73630 and codeunit 73631
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RecordRef.Get(RecordId) on a RecordRef that was never opened and on a closed one (existing row, missing row, result used and unused),
//        whether the table of the RecordId is opened afterwards, Get(RecordId) of another table on an open RecordRef, an empty RecordId.
// BC versions: 29 (27 and 28 by CI)

table 73629 "LT P131 RR A"
{
    fields
    {
        field(1; Id; Integer) { }
        field(2; Name; Text[20]) { }
    }
    keys
    {
        key(PK; Id) { Clustered = true; }
    }
}

table 73630 "LT P131 RR B"
{
    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Name; Text[20]) { }
    }
    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

codeunit 73631 "LT P131 RR Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        A: Record "LT P131 RR A";
        B: Record "LT P131 RR B";
    begin
        A.DeleteAll();
        B.DeleteAll();
        A.Id := 1;
        A.Name := 'one';
        A.Insert();
        B.Code := 'X';
        B.Name := 'ex';
        B.Insert();
    end;

    local procedure IdOfA(Id: Integer): RecordId
    var
        A: Record "LT P131 RR A";
    begin
        A.Id := Id;
        exit(A.RecordId);
    end;

    local procedure IdOfB(C: Code[10]): RecordId
    var
        B: Record "LT P131 RR B";
    begin
        B.Code := C;
        exit(B.RecordId);
    end;

    [TryFunction]
    local procedure TryGet(var RR: RecordRef; Id: RecordId; var Result: Boolean)
    begin
        Result := RR.Get(Id);
    end;

    [TryFunction]
    local procedure TryGetUnused(var RR: RecordRef; Id: RecordId)
    begin
        RR.Get(Id);
    end;

    [TryFunction]
    local procedure TryNumber(var RR: RecordRef; var Result: Integer)
    begin
        Result := RR.Number;
    end;

    [TryFunction]
    local procedure TryName(var RR: RecordRef; var Result: Text)
    begin
        Result := RR.Name;
    end;

    [TryFunction]
    local procedure TryName2(var RR: RecordRef; var Result: Text)
    begin
        Result := Format(RR.Field(2).Value);
    end;

    local procedure GetOutcome(var RR: RecordRef; Id: RecordId): Text
    var
        Ok: Boolean;
        Result: Boolean;
    begin
        ClearLastError();
        Ok := TryGet(RR, Id, Result);
        if not Ok then
            exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('result|' + Format(Result));
    end;

    local procedure GetUnusedOutcome(var RR: RecordRef; Id: RecordId): Text
    var
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryGetUnused(RR, Id);
        if not Ok then
            exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('no error');
    end;

    local procedure StateOf(var RR: RecordRef): Text
    var
        Num: Integer;
        Nm: Text;
        Val: Text;
        Ok: Boolean;
        S: Text;
    begin
        ClearLastError();
        Ok := TryNumber(RR, Num);
        if Ok then
            S := 'number=' + Format(Num)
        else
            S := 'number error=' + GetLastErrorText();
        ClearLastError();
        Ok := TryName(RR, Nm);
        if Ok then
            S += '|name=' + Nm
        else
            S += '|name error=' + GetLastErrorText();
        ClearLastError();
        Ok := TryName2(RR, Val);
        if Ok then
            S += '|field2=' + Val
        else
            S += '|field2 error=' + GetLastErrorText();
        exit(S);
    end;

    [Test]
    procedure P131_Get_Unopened_ExistingRow()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        Observer.Observe('get', GetOutcome(RR, IdOfA(1)));
        Observer.Observe('state', StateOf(RR));
        Observer.Observe('get again', GetOutcome(RR, IdOfA(1)));
        Observer.Observe('state again', StateOf(RR));
        Observer.Expect('get', 'result|Yes');
        Observer.Expect('state', 'number=73629|name=LT P131 RR A|field2=one');
        Observer.Expect('get again', 'result|Yes');
        Observer.Expect('state again', 'number=73629|name=LT P131 RR A|field2=one');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Get_Unopened_MissingRow()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        Observer.Observe('get', GetOutcome(RR, IdOfA(99)));
        Observer.Observe('state', StateOf(RR));
        Observer.Observe('get B missing', GetOutcome(RR, IdOfB('NOPE')));
        Observer.Observe('state B', StateOf(RR));
        Observer.Expect('get', 'result|No');
        Observer.Expect('state', 'number=0|name error=The record is not open.|field2 error=The record is not open.');
        Observer.Expect('get B missing', 'result|No');
        Observer.Expect('state B', 'number=0|name error=The record is not open.|field2 error=The record is not open.');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Get_Unopened_ResultUnused()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        Observer.Observe('existing', GetUnusedOutcome(RR, IdOfA(1)));
        Observer.Observe('state existing', StateOf(RR));
        Observer.Observe('missing', GetUnusedOutcome(RR2, IdOfA(99)));
        Observer.Observe('state missing', StateOf(RR2));
        Observer.Expect('existing', 'no error');
        Observer.Expect('state existing', 'number=73629|name=LT P131 RR A|field2=one');
        Observer.Expect('missing', 'error|The LT P131 RR A does not exist. Identification fields and values: Id=''99''|DB:RecordNotFound');
        Observer.Expect('state missing', 'number=0|name error=The record is not open.|field2 error=The record is not open.');
        Observer.Verify();
    end;

    [TryFunction]
    local procedure TryPattern(var RR: RecordRef; Id: RecordId; var GetResult: Boolean)
    begin
        GetResult := RR.Get(Id);
        if not GetResult then
            RR.Open(Id.TableNo);
    end;

    local procedure PatternOutcome(var RR: RecordRef; Id: RecordId): Text
    var
        GetResult: Boolean;
    begin
        ClearLastError();
        if not TryPattern(RR, Id, GetResult) then
            exit('error|' + GetLastErrorText() + '|' + GetLastErrorCode());
        exit('get=' + Format(GetResult) + '|' + StateOf(RR));
    end;

    [Test]
    procedure P131_Get_Unopened_ThenOpenOfTheRecordIdTable()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
    begin
        Seed();
        Observer.Observe('missing row', PatternOutcome(RR, IdOfA(99)));
        Observer.Observe('existing row', PatternOutcome(RR2, IdOfA(1)));
        Observer.Expect('missing row', 'get=No|number=73629|name=LT P131 RR A|field2=');
        Observer.Expect('existing row', 'get=Yes|number=73629|name=LT P131 RR A|field2=one');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Get_Closed_RecordRef()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT P131 RR A");
        RR.Close();
        Observer.Observe('existing', GetOutcome(RR, IdOfA(1)));
        Observer.Observe('state', StateOf(RR));
        Observer.Observe('missing', GetOutcome(RR, IdOfA(99)));
        Observer.Expect('existing', 'result|Yes');
        Observer.Expect('state', 'number=73629|name=LT P131 RR A|field2=one');
        Observer.Expect('missing', 'result|No');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Get_OpenOnAnotherTable()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
    begin
        Seed();
        RR.Open(Database::"LT P131 RR A");
        Observer.Observe('B existing', GetOutcome(RR, IdOfB('X')));
        Observer.Observe('state', StateOf(RR));
        Observer.Observe('B missing', GetOutcome(RR, IdOfB('NOPE')));
        Observer.Observe('state missing', StateOf(RR));
        Observer.Observe('A existing', GetOutcome(RR, IdOfA(1)));
        Observer.Observe('state A', StateOf(RR));
        Observer.Expect('B existing', 'result|Yes');
        Observer.Expect('state', 'number=73630|name=LT P131 RR B|field2=ex');
        Observer.Expect('B missing', 'result|No');
        Observer.Expect('state missing', 'number=73630|name=LT P131 RR B|field2=ex');
        Observer.Expect('A existing', 'result|Yes');
        Observer.Expect('state A', 'number=73629|name=LT P131 RR A|field2=one');
        Observer.Verify();
    end;

    [Test]
    procedure P131_Get_EmptyRecordId()
    var
        Observer: Codeunit "Probe Observer";
        RR: RecordRef;
        RR2: RecordRef;
        Empty: RecordId;
    begin
        Seed();
        Observer.Observe('unopened', GetOutcome(RR, Empty));
        Observer.Observe('state unopened', StateOf(RR));
        RR2.Open(Database::"LT P131 RR A");
        Observer.Observe('opened', GetOutcome(RR2, Empty));
        Observer.Observe('state opened', StateOf(RR2));
        Observer.Expect('unopened', 'result|No');
        Observer.Expect('state unopened', 'number=0|name error=The record is not open.|field2 error=The record is not open.');
        Observer.Expect('opened', 'result|No');
        Observer.Expect('state opened', 'number=73629|name=LT P131 RR A|field2=');
        Observer.Verify();
    end;
}
