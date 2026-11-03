// Batch 5, md:258 (Table connections): connection strings other than the test one, a Scoped default, unregistering or defaulting a name that is not registered,
// the TableConnectionType members. Session state: every test unregisters what it registered.
// Registration might raise or succeed; each call is behind a Try wrapper and the cleanup runs afterwards.

codeunit 67057 "W5 TableConn Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NameTxt: Label 'W5TESTCONN', Locked = true;

    // A name nobody registered.
    [Test]
    procedure TableConnection_UnregisteredName()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Observer.Observe('has', Format(HasTableConnection(TableConnectionType::CRM, NameTxt)));
        Observer.Observe('default_before', '[' + GetDefaultTableConnection(TableConnectionType::CRM) + ']');
        Ok := TryUnregister(NameTxt);
        Observer.Observe('unregister_ok', Format(Ok));
        Observer.ObserveError('unregister');
        Ok := TrySetDefault(NameTxt, false);
        Observer.Observe('set_default_ok', Format(Ok));
        Observer.ObserveError('set_default');
        Observer.Observe('default_after', '[' + GetDefaultTableConnection(TableConnectionType::CRM) + ']');
        Observer.Expect('has', 'No');
        Observer.Expect('default_before', '[]');
        Observer.Expect('unregister_ok', 'Yes');
        Observer.Expect('unregister|text', '');
        Observer.Expect('unregister|code', '');
        Observer.Expect('set_default_ok', 'Yes');
        Observer.Expect('set_default|text', '');
        Observer.Expect('set_default|code', '');
        Observer.Expect('default_after', '[W5TESTCONN]');
        Observer.Verify();
    end;

    // A connection string that is not the test connection.
    [Test]
    procedure TableConnection_OtherConnectionString()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRegister(NameTxt, 'Url=https://w5.invalid.example;AuthType=Office365');
        Observer.Observe('register_ok', Format(Ok));
        Observer.ObserveError('register');
        Observer.Observe('has_after_register', Format(HasTableConnection(TableConnectionType::CRM, NameTxt)));
        Observer.Observe('has_lower_case', Format(HasTableConnection(TableConnectionType::CRM, LowerCase(NameTxt))));
        CleanUp();
        Observer.Observe('has_after_cleanup', Format(HasTableConnection(TableConnectionType::CRM, NameTxt)));
        Observer.Expect('register_ok', 'Yes');
        Observer.Expect('register|text', '');
        Observer.Expect('register|code', '');
        Observer.Expect('has_after_register', 'Yes');
        Observer.Expect('has_lower_case', 'Yes');
        Observer.Expect('has_after_cleanup', 'No');
        Observer.Verify();
    end;

    // An empty connection string and an empty name.
    [Test]
    procedure TableConnection_EmptyStringAndEmptyName()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        Ok := TryRegister(NameTxt, '');
        Observer.Observe('empty_string_ok', Format(Ok));
        Observer.ObserveError('empty_string');
        CleanUp();
        Ok := TryRegister('', '@@test@@');
        Observer.Observe('empty_name_ok', Format(Ok));
        Observer.ObserveError('empty_name');
        Observer.Observe('has_empty_name', Format(HasTableConnection(TableConnectionType::CRM, '')));
        if HasTableConnection(TableConnectionType::CRM, '') then
            UnregisterTableConnection(TableConnectionType::CRM, '');
        Observer.Expect('empty_string_ok', 'Yes');
        Observer.Expect('empty_string|text', '');
        Observer.Expect('empty_string|code', '');
        Observer.Expect('empty_name_ok', 'Yes');
        Observer.Expect('empty_name|text', '');
        Observer.Expect('empty_name|code', '');
        Observer.Expect('has_empty_name', 'Yes');
        Observer.Verify();
    end;

    // The Scoped form of SetDefaultTableConnection with the test connection.
    [Test]
    procedure TableConnection_ScopedDefault()
    var
        Observer: Codeunit "Probe Observer";
        Ok: Boolean;
    begin
        ClearLastError();
        RegisterTableConnection(TableConnectionType::CRM, NameTxt, '@@test@@');
        Ok := TrySetDefault(NameTxt, true);
        Observer.Observe('scoped_default_ok', Format(Ok));
        Observer.ObserveError('scoped_default');
        Observer.Observe('default_name', GetDefaultTableConnection(TableConnectionType::CRM));
        CleanUp();
        Observer.Observe('default_after_cleanup', '[' + GetDefaultTableConnection(TableConnectionType::CRM) + ']');
        Observer.Expect('scoped_default_ok', 'Yes');
        Observer.Expect('scoped_default|text', '');
        Observer.Expect('scoped_default|code', '');
        Observer.Expect('default_name', '');
        Observer.Expect('default_after_cleanup', '[]');
        Observer.Verify();
    end;

    // The members and the format of TableConnectionType.
    [Test]
    procedure TableConnectionType_Members()
    var
        Observer: Codeunit "Probe Observer";
        Kind: TableConnectionType;
        i: Integer;
        Members: Text;
    begin
        for i := 0 to 10 do
            if Evaluate(Kind, Format(i)) then
                Members += Format(i) + '=' + Format(Kind) + ';';
        Observer.Observe('members', Members);
        Observer.Observe('crm_format_2', Format(TableConnectionType::CRM, 0, 2));
        Observer.Observe('externalsql_format_2', Format(TableConnectionType::ExternalSQL, 0, 2));
        Observer.Expect('members', '0=CRM;1=ExternalSQL;2=Exchange;3=MicrosoftGraph;4=Query;');
        Observer.Expect('crm_format_2', '0');
        Observer.Expect('externalsql_format_2', '1');
        Observer.Verify();
    end;

    local procedure CleanUp()
    begin
        if HasTableConnection(TableConnectionType::CRM, NameTxt) then
            UnregisterTableConnection(TableConnectionType::CRM, NameTxt);
    end;

    [TryFunction]
    local procedure TryRegister(Name: Text; ConnectionString: Text)
    begin
        RegisterTableConnection(TableConnectionType::CRM, Name, ConnectionString);
    end;

    [TryFunction]
    local procedure TryUnregister(Name: Text)
    begin
        UnregisterTableConnection(TableConnectionType::CRM, Name);
    end;

    [TryFunction]
    local procedure TrySetDefault(Name: Text; Scoped: Boolean)
    begin
        SetDefaultTableConnection(TableConnectionType::CRM, Name, Scoped);
    end;
}
