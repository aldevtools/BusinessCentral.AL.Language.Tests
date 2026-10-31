// Probe (observe only): RecordRef.Get(RecordId) on a RecordRef that was never opened (Data Type Management does `if not RecRef.Get(RecID) then RecRef.Open(RecID.TableNo)`).
// Settles docs/probes-needed.md row 977 (batch 4). Object ids 68074 - 68075.

table 68074 "W4 RecRef Get Row"
{
    DataClassification = SystemMetadata;
    fields
    {
        field(1; Id; Integer) { }
        field(2; Info; Text[20]) { }
    }
    keys { key(PK; Id) { Clustered = true; } }
}

codeunit 68075 "W4 RecRef Get Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Seed()
    var
        R: Record "W4 RecRef Get Row";
    begin
        R.DeleteAll();
        R.Id := 1;
        R.Info := 'one';
        R.Insert();
    end;

    local procedure IdOf(Id: Integer): RecordId
    var
        R: Record "W4 RecRef Get Row";
    begin
        R.Id := Id;
        exit(R.RecordId());
    end;

    [TryFunction]
    local procedure TryGet(var RR: RecordRef; Id: RecordId; var Found: Boolean)
    begin
        Found := RR.Get(Id);
    end;

    [TryFunction]
    local procedure TryGetOrOpen(var RR: RecordRef; Id: RecordId)
    begin
        if not RR.Get(Id) then
            RR.Open(Id.TableNo());
    end;

    local procedure Outcome(Ok: Boolean; Found: Boolean): Text
    begin
        if Ok then
            exit('ok found=' + Format(Found));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [Test]
    procedure Get_OnUnopenedRecordRef_ExistingRow()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('get', Outcome(TryGet(RR, IdOf(1), Found), Found));
        ClearLastError();
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Observe('isopen_proxy_name', RR.Name());
        Observer.Expect('get', 'ok found=Yes');
        Observer.Expect('number_after', '68074');
        Observer.Expect('isopen_proxy_name', 'W4 RecRef Get Row');
        Observer.Verify();
    end;

    [Test]
    procedure Get_OnUnopenedRecordRef_MissingRow()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('get', Outcome(TryGet(RR, IdOf(99), Found), Found));
        ClearLastError();
        Observer.Observe('number_after', Format(RR.Number()));
        Observer.Expect('get', 'ok found=No');
        Observer.Expect('number_after', '0');
        Observer.Verify();
    end;

    [Test]
    procedure GetOrOpen_Pattern_OfDataTypeManagement()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        if TryGetOrOpen(RR, IdOf(99)) then
            Observer.Observe('missing_row', 'ok number=' + Format(RR.Number()) + ' name=' + RR.Name())
        else begin
            Observer.Observe('missing_row', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Clear(RR);
        if TryGetOrOpen(RR, IdOf(1)) then
            Observer.Observe('existing_row', 'ok number=' + Format(RR.Number()) + ' info=' + Format(RR.FieldExist(2)))
        else begin
            Observer.Observe('existing_row', 'error:' + GetLastErrorText() + '|' + GetLastErrorCode());
            ClearLastError();
        end;
        Observer.Expect('missing_row', 'ok number=68074 name=W4 RecRef Get Row');
        Observer.Expect('existing_row', 'ok number=68074 info=Yes');
        Observer.Verify();
    end;

    [Test]
    procedure Get_AfterOpen_ForComparison()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"W4 RecRef Get Row");
        Observer.Observe('existing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        ClearLastError();
        Observer.Observe('info_after_existing', Format(RR.Field(2).Value()));
        Observer.Observe('missing', Outcome(TryGet(RR, IdOf(99), Found), Found));
        ClearLastError();
        Observer.Expect('existing', 'ok found=Yes');
        Observer.Expect('info_after_existing', 'one');
        Observer.Expect('missing', 'ok found=No');
        Observer.Verify();
    end;

    // Writer Y30 (2026-10-31, measured on SaaS BC 29 and the CI legs 27.5/28.5/29.0): RecordRef.SystemIdNo answers 2000000000 on
    // a RecordRef that is not open (never opened, after Close, after Clear) and raises no error. RecordRef.Get(RecordId) on a
    // RecordRef that is not open opens the RecordId's table and loads the row when it exists; when the row is missing the ref
    // stays closed (Number 0, IsEmpty raises "The record is not open."). On an open ref a missing row leaves it open.
    [TryFunction]
    local procedure Y30TrySystemIdNo(var RR: RecordRef; var No: Integer)
    begin
        No := RR.SystemIdNo();
    end;

    local procedure Y30SystemIdNo(var RR: RecordRef): Text
    var
        No: Integer;
    begin
        ClearLastError();
        if Y30TrySystemIdNo(RR, No) then
            exit('ok ' + Format(No));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    [TryFunction]
    local procedure Y30TryIsEmpty(var RR: RecordRef; var Empty: Boolean)
    begin
        Empty := RR.IsEmpty();
    end;

    local procedure Y30IsEmpty(var RR: RecordRef): Text
    var
        Empty: Boolean;
    begin
        ClearLastError();
        if Y30TryIsEmpty(RR, Empty) then
            exit('ok ' + Format(Empty));
        exit('error:' + GetLastErrorText() + '|' + GetLastErrorCode());
    end;

    local procedure Y30State(var RR: RecordRef): Text
    begin
        exit('number=' + Format(RR.Number()) + ' sysid=' + Y30SystemIdNo(RR) + ' isempty=' + Y30IsEmpty(RR));
    end;

    [Test]
    procedure Y30_SystemIdNo_NotOpen()
    var
        RR: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('never_opened', Y30SystemIdNo(RR));
        RR.Open(Database::"W4 RecRef Get Row");
        Observer.Observe('open', Y30SystemIdNo(RR));
        RR.Close();
        Observer.Observe('after_close', Y30SystemIdNo(RR));
        Observer.Observe('after_close_number', Format(RR.Number()));
        RR.Open(Database::"W4 RecRef Get Row");
        Clear(RR);
        Observer.Observe('after_clear', Y30SystemIdNo(RR));
        Observer.Expect('never_opened', 'ok 2000000000');
        Observer.Expect('open', 'ok 2000000000');
        Observer.Expect('after_close', 'ok 2000000000');
        Observer.Expect('after_close_number', '0');
        Observer.Expect('after_clear', 'ok 2000000000');
        Observer.Verify();
    end;

    [Test]
    procedure Y30_GetRecordId_OnUnopened_State()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        Observer.Observe('existing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        Observer.Observe('existing_state', Y30State(RR) + ' name=' + RR.Name() + ' info=' + Format(RR.Field(2).Value()));
        Clear(RR);
        Observer.Observe('missing', Outcome(TryGet(RR, IdOf(99), Found), Found));
        Observer.Observe('missing_state', Y30State(RR));
        Observer.Expect('existing', 'ok found=Yes');
        Observer.Expect('existing_state', 'number=68074 sysid=ok 2000000000 isempty=ok No name=W4 RecRef Get Row info=one');
        Observer.Expect('missing', 'ok found=No');
        Observer.Expect('missing_state', 'number=0 sysid=ok 2000000000 isempty=error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Y30_GetRecordId_AfterClose_State()
    var
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        Seed();
        RR.Open(Database::"W4 RecRef Get Row");
        RR.Close();
        Observer.Observe('existing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        Observer.Observe('existing_state', Y30State(RR) + ' info=' + Format(RR.Field(2).Value()));
        RR.Close();
        Observer.Observe('missing', Outcome(TryGet(RR, IdOf(99), Found), Found));
        Observer.Observe('missing_state', Y30State(RR));
        Observer.Expect('existing', 'ok found=Yes');
        Observer.Expect('existing_state', 'number=68074 sysid=ok 2000000000 isempty=ok No info=one');
        Observer.Expect('missing', 'ok found=No');
        Observer.Expect('missing_state', 'number=0 sysid=ok 2000000000 isempty=error:The record is not open.|RecordNotOpened');
        Observer.Verify();
    end;

    [Test]
    procedure Y30_GetRecordId_Missing_OnEmptyTable()
    var
        R: Record "W4 RecRef Get Row";
        RR: RecordRef;
        Found: Boolean;
        Observer: Codeunit "Probe Observer";
    begin
        R.DeleteAll();
        Observer.Observe('missing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        Observer.Observe('missing_state', Y30State(RR));
        RR.Open(Database::"W4 RecRef Get Row");
        Observer.Observe('opened_missing', Outcome(TryGet(RR, IdOf(1), Found), Found));
        Observer.Observe('opened_missing_state', Y30State(RR));
        Observer.Expect('missing', 'ok found=No');
        Observer.Expect('missing_state', 'number=0 sysid=ok 2000000000 isempty=error:The record is not open.|RecordNotOpened');
        Observer.Expect('opened_missing', 'ok found=No');
        Observer.Expect('opened_missing_state', 'number=68074 sysid=ok 2000000000 isempty=ok Yes');
        Observer.Verify();
    end;
}
