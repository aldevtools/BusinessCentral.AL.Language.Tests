// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160) and ALT CRM Entity (60291, a TableType = CRM table), from the AL Language Coverage Tests app; self-contained codeunit 98620
// Probe: a TableType = CRM table in a test session on the service tier, through the CRM table connection Microsoft's test library registers
// ("Library - Mock CRM Connection".RegisterTestConnection: RegisterTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST', '@@test@@') and
// SetDefaultTableConnection(TABLECONNECTIONTYPE::CRM, 'TEST')). Covers what session/TestDatabaseTableConnectionCrm.al of the Cloud app leaves open:
// FindSet order and filters, Modify, Delete, Rename, Get of a missing key, a duplicate Insert, Modify of a missing row, a registered connection that is
// not the default, rows after an unregister, two registered connections, and Get/FindSet/Modify/Delete with no connection at all.
// Every test unregisters the connection names it uses, at the start and at the end (a table connection is session state).
// Expected values: corpus CI run 41187321466 (jobs BC OnPrem 27.5, 28.5 and 29.0, Linux BC containers), the same on all three. The container has no CRM
// table connection of its own (Y16_Crm_ConnectionStateAtStart).
// BC versions: 27, 28, 29

codeunit 98620 "LT Y16 CRM Connection Ops"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        ConnNameTok: Label 'TEST', Locked = true;
        OtherConnNameTok: Label 'Y16OTHER', Locked = true;
        TestConnStringTok: Label '@@test@@', Locked = true;

    local procedure Cleanup()
    begin
        if HasTableConnection(TableConnectionType::CRM, ConnNameTok) then
            UnregisterTableConnection(TableConnectionType::CRM, ConnNameTok);
        if HasTableConnection(TableConnectionType::CRM, OtherConnNameTok) then
            UnregisterTableConnection(TableConnectionType::CRM, OtherConnNameTok);
    end;

    local procedure RegisterTestConnection()
    begin
        RegisterTableConnection(TableConnectionType::CRM, ConnNameTok, TestConnStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnNameTok);
    end;

    local procedure Id(N: Integer): Guid
    var
        G: Guid;
    begin
        Evaluate(G, StrSubstNo('{0000000%1-0000-0000-0000-000000000000}', N));
        exit(G);
    end;

    local procedure InsertRow(N: Integer; Name: Text[100]; Amount: Decimal)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Init();
        Entity.EntityId := Id(N);
        Entity.Name := Name;
        Entity.Amount := Amount;
        Entity.Insert();
    end;

    local procedure Names(var Entity: Record "ALT CRM Entity"): Text
    var
        Result: Text;
    begin
        if Entity.FindSet() then
            repeat
                Result += Entity.Name + ';';
            until Entity.Next() = 0;
        exit(Result);
    end;

    [TryFunction]
    local procedure TryInsert(N: Integer; Name: Text[100])
    begin
        InsertRow(N, Name, 0);
    end;

    [TryFunction]
    local procedure TryGet(N: Integer)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Get(Id(N));
    end;

    [TryFunction]
    local procedure TryGetIf(N: Integer; var Found: Boolean)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Found := Entity.Get(Id(N));
    end;

    [TryFunction]
    local procedure TryFindSet(var Found: Boolean)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Found := Entity.FindSet();
    end;

    [TryFunction]
    local procedure TryModify(N: Integer; Name: Text[100])
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.EntityId := Id(N);
        Entity.Name := Name;
        Entity.Modify();
    end;

    [TryFunction]
    local procedure TryDelete(N: Integer)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.EntityId := Id(N);
        Entity.Delete();
    end;

    [TryFunction]
    local procedure TryRename(N: Integer; NewN: Integer)
    var
        Entity: Record "ALT CRM Entity";
    begin
        Entity.Get(Id(N));
        Entity.Rename(Id(NewN));
    end;

    [TryFunction]
    local procedure TryCount(var N: Integer)
    var
        Entity: Record "ALT CRM Entity";
    begin
        N := Entity.Count();
    end;

    local procedure ObserveTry(var Observer: Codeunit "Probe Observer"; Name: Text; Ok: Boolean)
    begin
        if Ok then
            Observer.Observe(Name, 'ok')
        else
            Observer.ObserveError(Name);
    end;

    [Test]
    procedure Y16_Crm_ConnectionStateAtStart()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        Observer.Observe('has TEST', Format(HasTableConnection(TableConnectionType::CRM, ConnNameTok)));
        Observer.Observe('default', '[' + GetDefaultTableConnection(TableConnectionType::CRM) + ']');
        Observer.Expect('has TEST', 'No');
        Observer.Expect('default', '[]');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_FindSetOrderAndFilters()
    var
        Observer: Codeunit "Probe Observer";
        Entity: Record "ALT CRM Entity";
    begin
        Cleanup();
        RegisterTestConnection();
        InsertRow(3, 'c', 3);
        InsertRow(1, 'a', 1);
        InsertRow(2, 'b', 2);
        Observer.Observe('findset', Names(Entity));
        Entity.SetRange(Name, 'b');
        Observer.Observe('setrange name b', Names(Entity) + ' count=' + Format(Entity.Count()));
        Entity.Reset();
        Entity.SetFilter(Amount, '>%1', 1);
        Observer.Observe('setfilter amount>1', Names(Entity));
        Entity.Reset();
        Entity.Ascending(false);
        Observer.Observe('descending', Names(Entity));
        Entity.Reset();
        Observer.Observe('findfirst', Format(Entity.FindFirst()) + ' ' + Entity.Name);
        Observer.Observe('findlast', Format(Entity.FindLast()) + ' ' + Entity.Name);
        Observer.Observe('isempty', Format(Entity.IsEmpty()));
        Cleanup();
        Observer.Expect('findset', 'a;b;c;');
        Observer.Expect('setrange name b', 'b; count=1');
        Observer.Expect('setfilter amount>1', 'b;c;');
        Observer.Expect('descending', 'c;b;a;');
        Observer.Expect('findfirst', 'Yes a');
        Observer.Expect('findlast', 'Yes c');
        Observer.Expect('isempty', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_ModifyDeleteRename()
    var
        Observer: Codeunit "Probe Observer";
        Entity: Record "ALT CRM Entity";
        N: Integer;
    begin
        Cleanup();
        RegisterTestConnection();
        InsertRow(1, 'a', 1);
        InsertRow(2, 'b', 2);
        Entity.Get(Id(1));
        Entity.Name := 'a2';
        Observer.Observe('modify ret', Format(Entity.Modify()));
        Clear(Entity);
        Entity.Get(Id(1));
        Observer.Observe('after modify', Entity.Name + ' ' + Format(Entity.Amount));
        Observer.Observe('delete ret', Format(Entity.Delete()));
        Observer.Observe('get deleted', Format(Entity.Get(Id(1))));
        Observer.Observe('count after delete', Format(Entity.Count()));
        ObserveTry(Observer, 'rename', TryRename(2, 4));
        Observer.Observe('get old key', Format(Entity.Get(Id(2))));
        Observer.Observe('get new key', Format(Entity.Get(Id(4))) + ' ' + Entity.Name);
        if TryCount(N) then;
        Observer.Observe('count end', Format(N));
        Cleanup();
        Observer.Expect('modify ret', 'Yes');
        Observer.Expect('after modify', 'a2 1');
        Observer.Expect('delete ret', 'Yes');
        Observer.Expect('get deleted', 'No');
        Observer.Expect('count after delete', '1');
        Observer.Expect('rename', 'ok');
        Observer.Expect('get old key', 'No');
        Observer.Expect('get new key', 'Yes b');
        Observer.Expect('count end', '1');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_ErrorsWithConnection()
    var
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Cleanup();
        RegisterTestConnection();
        InsertRow(1, 'a', 1);
        ObserveTry(Observer, 'get missing', TryGet(9));
        Found := true;
        ObserveTry(Observer, 'get missing if', TryGetIf(9, Found));
        Observer.Observe('get missing if found', Format(Found));
        ObserveTry(Observer, 'insert duplicate', TryInsert(1, 'dup'));
        ObserveTry(Observer, 'modify missing', TryModify(9, 'x'));
        ObserveTry(Observer, 'delete missing', TryDelete(9));
        Cleanup();
        Observer.Expect('get missing|text', 'The ALT CRM Entity does not exist. Identification fields and values: Entity Id=''{00000009-0000-0000-0000-000000000000}''');
        Observer.Expect('get missing|code', 'DB:RecordNotFound');
        Observer.Expect('get missing if', 'ok');
        Observer.Expect('get missing if found', 'No');
        Observer.Expect('insert duplicate|text', 'The record in table ALT CRM Entity already exists. Identification fields and values: Entity Id=''{00000001-0000-0000-0000-000000000000}''');
        Observer.Expect('insert duplicate|code', 'DB:RecordExists');
        Observer.Expect('modify missing|text', 'The ALT CRM Entity does not exist. Identification fields and values: Entity Id=''{00000009-0000-0000-0000-000000000000}''');
        Observer.Expect('modify missing|code', 'DB:RecordNotFound');
        Observer.Expect('delete missing|text', 'The ALT CRM Entity does not exist. Identification fields and values: Entity Id=''{00000009-0000-0000-0000-000000000000}''');
        Observer.Expect('delete missing|code', 'DB:RecordNotFound');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_RegisteredButNotDefault()
    var
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
        N: Integer;
    begin
        Cleanup();
        RegisterTableConnection(TableConnectionType::CRM, ConnNameTok, TestConnStringTok);
        Observer.Observe('default', '[' + GetDefaultTableConnection(TableConnectionType::CRM) + ']');
        ObserveTry(Observer, 'insert', TryInsert(1, 'a'));
        ObserveTry(Observer, 'count', TryCount(N));
        Observer.Observe('count value', Format(N));
        ObserveTry(Observer, 'findset', TryFindSet(Found));
        Cleanup();
        Observer.Expect('default', '[]');
        Observer.Expect('insert|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('insert|code', 'Argument');
        Observer.Expect('count|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('count|code', 'Argument');
        Observer.Expect('count value', '0');
        Observer.Expect('findset|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('findset|code', 'Argument');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_RowsAfterUnregisterAndSecondConnection()
    var
        Observer: Codeunit "Probe Observer";
        Entity: Record "ALT CRM Entity";
        N: Integer;
    begin
        Cleanup();
        RegisterTestConnection();
        InsertRow(1, 'a', 1);
        UnregisterTableConnection(TableConnectionType::CRM, ConnNameTok);
        RegisterTestConnection();
        if TryCount(N) then
            Observer.Observe('count after re-register', Format(N))
        else
            Observer.ObserveError('count after re-register');
        InsertRow(2, 'b', 2);
        RegisterTableConnection(TableConnectionType::CRM, OtherConnNameTok, TestConnStringTok);
        SetDefaultTableConnection(TableConnectionType::CRM, OtherConnNameTok);
        if TryCount(N) then
            Observer.Observe('count on second connection', Format(N))
        else
            Observer.ObserveError('count on second connection');
        InsertRow(3, 'c', 3);
        SetDefaultTableConnection(TableConnectionType::CRM, ConnNameTok);
        Observer.Observe('back on first', Names(Entity));
        Cleanup();
        Observer.Expect('count after re-register', '0');
        Observer.Expect('count on second connection', '0');
        Observer.Expect('back on first', 'b;');
        Observer.Verify();
    end;

    [Test]
    procedure Y16_Crm_NoConnection_GetFindSetModifyDelete()
    var
        Observer: Codeunit "Probe Observer";
        Found: Boolean;
    begin
        Cleanup();
        ObserveTry(Observer, 'get', TryGetIf(1, Found));
        ObserveTry(Observer, 'findset', TryFindSet(Found));
        ObserveTry(Observer, 'modify', TryModify(1, 'x'));
        ObserveTry(Observer, 'delete', TryDelete(1));
        ObserveTry(Observer, 'insert', TryInsert(1, 'x'));
        Observer.Expect('get|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('get|code', 'Argument');
        Observer.Expect('findset|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('findset|code', 'Argument');
        Observer.Expect('modify|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('modify|code', 'Argument');
        Observer.Expect('delete|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('delete|code', 'Argument');
        Observer.Expect('insert|text', 'Table connection  for table type CRM must be registered using RegisterTableConnection or cmdlet New-NAVTableConnection before it can be used.');
        Observer.Expect('insert|code', 'Argument');
        Observer.Verify();
    end;
}
