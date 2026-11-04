// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/recordref/recordref-get-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); self-contained tables 74258 and 74259, codeunit 74260
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Settles (issue 135, reasons 34-35): "RecordRef.Get on a RecordRef that is not open: BC's error text, and whether Get(RecordId) opens the table of the RecordId, are not pinned".
// Facts: RecordRef.Get(RecordId) on a RecordRef that was never opened and on one that was closed again: result, error text and code, whether the RecordRef is open afterwards (Number, Name, Count), the Base Application pattern `if not RecRef.Get(RecId) then RecRef.Open(RecId.TableNo)`; for an existing row, a deleted row and a blank RecordId; RecordRef.Get with a key value on an unopened RecordRef.
// BC versions: 29 (27 and 28 by CI)

table 74258 "LT P135 RR Row"
{
    DataClassification = SystemMetadata;

    fields
    {
        field(1; Code; Code[10]) { }
        field(2; Qty; Integer) { }
    }

    keys
    {
        key(PK; Code) { Clustered = true; }
    }
}

table 74259 "LT P135 RR Other"
{
    DataClassification = SystemMetadata;

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

codeunit 74260 "LT P135 RR Get"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        Row: Record "LT P135 RR Row";
        Other: Record "LT P135 RR Other";
    begin
        Row.DeleteAll();
        Other.DeleteAll();
        Row.Code := 'A';
        Row.Qty := 10;
        Row.Insert();
        Row.Code := 'B';
        Row.Qty := 20;
        Row.Insert();
        Other.Id := 1;
        Other.Name := 'one';
        Other.Insert();
    end;

    [TryFunction]
    local procedure TryGet(var RR: RecordRef; Rid: RecordId; var Found: Boolean)
    begin
        Found := RR.Get(Rid);
    end;

    [TryFunction]
    local procedure TryGetUnused(var RR: RecordRef; Rid: RecordId)
    begin
        RR.Get(Rid);
    end;

    [TryFunction]
    local procedure TryPattern(var RR: RecordRef; Rid: RecordId)
    begin
        if not RR.Get(Rid) then
            RR.Open(Rid.TableNo);
    end;

    [TryFunction]
    local procedure TryField(var RR: RecordRef; var Result: Text)
    begin
        Result := Format(RR.Field(2).Value);
    end;

    local procedure Pattern(var RR: RecordRef; Rid: RecordId): Text
    begin
        ClearLastError();
        if TryPattern(RR, Rid) then
            exit('ok');
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure FieldRead(var RR: RecordRef): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryField(RR, Result) then
            exit('ok ' + Result);
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure TryState(var RR: RecordRef; var Result: Text)
    begin
        Result := 'number=' + Format(RR.Number) + ' name=' + RR.Name + ' count=' + Format(RR.Count()) + ' isempty=' + Format(RR.IsEmpty());
    end;

    local procedure Outcome(var RR: RecordRef; Rid: RecordId): Text
    var
        Found: Boolean;
    begin
        ClearLastError();
        if TryGet(RR, Rid, Found) then
            exit('ok found=' + Format(Found));
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure OutcomeUnused(var RR: RecordRef; Rid: RecordId): Text
    begin
        ClearLastError();
        if TryGetUnused(RR, Rid) then
            exit('ok');
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure State(var RR: RecordRef): Text
    var
        Result: Text;
    begin
        ClearLastError();
        if TryState(RR, Result) then
            exit(Result);
        exit('err ' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure P135_Get_RecordId_OnNeverOpenedRecordRef()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        Row.Get('A');
        Rid := Row.RecordId;
        Observer.Observe('state before', State(RR));
        Observer.Observe('get existing', Outcome(RR, Rid));
        Observer.Observe('state after get existing', State(RR));
        Observer.Observe('get existing again', Outcome(RR, Rid));
        Observer.Observe('state after again', State(RR));
        Observer.Expect('state before', 'err The record is not open.|RecordNotOpened');
        Observer.Expect('get existing', 'ok found=Yes');
        Observer.Expect('state after get existing', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Expect('get existing again', 'ok found=Yes');
        Observer.Expect('state after again', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_Unused_Result()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        Row.Get('B');
        Rid := Row.RecordId;
        Observer.Observe('get unused existing', OutcomeUnused(RR, Rid));
        Observer.Observe('state after', State(RR));
        Row.Delete();
        Observer.Observe('get unused deleted', OutcomeUnused(RR, Rid));
        Observer.Observe('state after deleted', State(RR));
        Observer.Expect('get unused existing', 'ok');
        Observer.Expect('state after', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Expect('get unused deleted', 'err The LT P135 RR Row does not exist. Identification fields and values: Code=''B''|DB:RecordNotFound');
        Observer.Expect('state after deleted', 'number=74258 name=LT P135 RR Row count=1 isempty=No');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_DeletedRow_AndBlankRecordId()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        RR2: RecordRef;
        RR3: RecordRef;
        Rid: RecordId;
        Blank: RecordId;
    begin
        Seed();
        Row.Get('B');
        Rid := Row.RecordId;
        Row.Delete();
        Observer.Observe('get deleted', Outcome(RR, Rid));
        Observer.Observe('state after get deleted', State(RR));
        Observer.Observe('get blank record id', Outcome(RR2, Blank));
        Observer.Observe('state after blank', State(RR2));
        RR3.Open(74259);
        Observer.Observe('opened other table, blank record id', Outcome(RR3, Blank));
        Observer.Observe('opened other table state', State(RR3));
        Observer.Expect('get deleted', 'ok found=No');
        Observer.Expect('state after get deleted', 'err The record is not open.|RecordNotOpened');
        Observer.Expect('get blank record id', 'ok found=No');
        Observer.Expect('state after blank', 'err The record is not open.|RecordNotOpened');
        Observer.Expect('opened other table, blank record id', 'ok found=No');
        Observer.Expect('opened other table state', 'number=74259 name=LT P135 RR Other count=1 isempty=No');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_AfterClose()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        Row.Get('A');
        Rid := Row.RecordId;
        RR.Open(74258);
        Observer.Observe('state opened', State(RR));
        RR.Close();
        Observer.Observe('state closed', State(RR));
        Observer.Observe('get after close', Outcome(RR, Rid));
        Observer.Observe('state after get', State(RR));
        Observer.Expect('state opened', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Expect('state closed', 'err The record is not open.|RecordNotOpened');
        Observer.Expect('get after close', 'ok found=Yes');
        Observer.Expect('state after get', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_BasePattern_OpenWhenMissing()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        RR2: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        Row.Get('A');
        Rid := Row.RecordId;
        Row.Delete();
        Observer.Observe('pattern missing row', Pattern(RR, Rid));
        Observer.Observe('pattern missing row state', State(RR));
        Observer.Observe('pattern table no', Format(Rid.TableNo));
        Row.Get('B');
        Rid := Row.RecordId;
        Observer.Observe('pattern existing row', Pattern(RR2, Rid));
        Observer.Observe('pattern existing row state', State(RR2));
        Observer.Observe('pattern existing field', FieldRead(RR2));
        Observer.Expect('pattern missing row', 'ok');
        Observer.Expect('pattern missing row state', 'number=74258 name=LT P135 RR Row count=1 isempty=No');
        Observer.Expect('pattern table no', '74258');
        Observer.Expect('pattern existing row', 'ok');
        Observer.Expect('pattern existing row state', 'number=74258 name=LT P135 RR Row count=1 isempty=No');
        Observer.Expect('pattern existing field', 'ok 20');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_OtherTable_ThenOwn()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        Other: Record "LT P135 RR Other";
        RR: RecordRef;
        RidRow: RecordId;
        RidOther: RecordId;
    begin
        Seed();
        Row.Get('A');
        RidRow := Row.RecordId;
        Other.Get(1);
        RidOther := Other.RecordId;
        Observer.Observe('unopened get other table', Outcome(RR, RidOther));
        Observer.Observe('state', State(RR));
        Observer.Observe('then get first table', Outcome(RR, RidRow));
        Observer.Observe('state after second', State(RR));
        Observer.Observe('then get other again', Outcome(RR, RidOther));
        Observer.Observe('state after third', State(RR));
        Observer.Expect('unopened get other table', 'ok found=Yes');
        Observer.Expect('state', 'number=74259 name=LT P135 RR Other count=1 isempty=No');
        Observer.Expect('then get first table', 'ok found=Yes');
        Observer.Expect('state after second', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Expect('then get other again', 'ok found=Yes');
        Observer.Expect('state after third', 'number=74259 name=LT P135 RR Other count=1 isempty=No');
        Observer.Verify();
    end;

    [Test]
    procedure P135_Get_RecordId_ThenFieldsReadable()
    var
        Observer: Codeunit "Probe Observer";
        Row: Record "LT P135 RR Row";
        RR: RecordRef;
        Rid: RecordId;
    begin
        Seed();
        Row.Get('B');
        Rid := Row.RecordId;
        Observer.Observe('get', Outcome(RR, Rid));
        Observer.Observe('field read', FieldRead(RR));
        Observer.Observe('state', State(RR));
        Observer.Expect('get', 'ok found=Yes');
        Observer.Expect('field read', 'ok 20');
        Observer.Expect('state', 'number=74258 name=LT P135 RR Row count=2 isempty=No');
        Observer.Verify();
    end;
}
