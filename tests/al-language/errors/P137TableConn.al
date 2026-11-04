// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-unregistertableconnection-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: UnregisterTableConnection(CRM, Name) for a name that was never registered, a second time after a first, with another case, with an empty name; SetDefaultTableConnection for a name not registered; HasTableConnection after each; error text and code or no error
// BC versions: 29 (27 and 28 by CI)

codeunit 74432 "LT P137 Table Conn"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        NameA: Label 'P137CONNA', Locked = true;
        NameB: Label 'P137CONNB', Locked = true;
        ConnString: Label '@@test@@', Locked = true;

    local procedure Clean()
    begin
        if HasTableConnection(TableConnectionType::CRM, NameA) then
            UnregisterTableConnection(TableConnectionType::CRM, NameA);
        if HasTableConnection(TableConnectionType::CRM, NameB) then
            UnregisterTableConnection(TableConnectionType::CRM, NameB);
    end;

    local procedure Out(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 800));
    end;

    [TryFunction]
    local procedure TryUnregister(Name: Text)
    begin
        UnregisterTableConnection(TableConnectionType::CRM, Name);
    end;

    [TryFunction]
    local procedure TryRegister(Name: Text)
    begin
        RegisterTableConnection(TableConnectionType::CRM, Name, ConnString);
    end;

    [TryFunction]
    local procedure TrySetDefault(Name: Text)
    begin
        SetDefaultTableConnection(TableConnectionType::CRM, Name);
    end;

    [Test]
    procedure P137_Unregister_NeverRegistered()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('has_before', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister', Out(TryUnregister(NameA)));
        ClearLastError();
        Observer.Observe('has_after', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister_empty_name', Out(TryUnregister('')));
        ClearLastError();
        Observer.Observe('unregister_long_name', Out(TryUnregister(PadStr('', 200, 'x'))));
        ClearLastError();
        Observer.Expect('has_before', 'No');
        Observer.Expect('unregister', 'ok');
        Observer.Expect('has_after', 'No');
        Observer.Expect('unregister_empty_name', 'ok');
        Observer.Expect('unregister_long_name', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Unregister_Twice()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('register', Out(TryRegister(NameA)));
        ClearLastError();
        Observer.Observe('has_registered', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister_first', Out(TryUnregister(NameA)));
        ClearLastError();
        Observer.Observe('has_after_first', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister_second', Out(TryUnregister(NameA)));
        ClearLastError();
        Observer.Observe('register_again', Out(TryRegister(NameA)));
        ClearLastError();
        Observer.Observe('has_again', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Clean();
        Observer.Expect('register', 'ok');
        Observer.Expect('has_registered', 'Yes');
        Observer.Expect('unregister_first', 'ok');
        Observer.Expect('has_after_first', 'No');
        Observer.Expect('unregister_second', 'ok');
        Observer.Expect('register_again', 'ok');
        Observer.Expect('has_again', 'Yes');
        Observer.Verify();
    end;

    [Test]
    procedure P137_Unregister_OtherNameAndOtherCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('register_a', Out(TryRegister(NameA)));
        ClearLastError();
        Observer.Observe('unregister_b', Out(TryUnregister(NameB)));
        ClearLastError();
        Observer.Observe('has_a_after_b', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister_a_lower', Out(TryUnregister(LowerCase(NameA))));
        ClearLastError();
        Observer.Observe('has_a_after_lower', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('unregister_a_again', Out(TryUnregister(NameA)));
        ClearLastError();
        Clean();
        Observer.Expect('register_a', 'ok');
        Observer.Expect('unregister_b', 'ok');
        Observer.Expect('has_a_after_b', 'Yes');
        Observer.Expect('unregister_a_lower', 'ok');
        Observer.Expect('has_a_after_lower', 'No');
        Observer.Expect('unregister_a_again', 'ok');
        Observer.Verify();
    end;

    [Test]
    procedure P137_SetDefault_NotRegistered()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Clean();
        Observer.Observe('set_default_never', Out(TrySetDefault(NameA)));
        ClearLastError();
        Observer.Observe('has_after', Format(HasTableConnection(TableConnectionType::CRM, NameA)));
        Observer.Observe('register_a', Out(TryRegister(NameA)));
        ClearLastError();
        Observer.Observe('set_default_a', Out(TrySetDefault(NameA)));
        ClearLastError();
        Observer.Observe('unregister_a', Out(TryUnregister(NameA)));
        ClearLastError();
        Observer.Observe('set_default_after_unregister', Out(TrySetDefault(NameA)));
        ClearLastError();
        Clean();
        Observer.Expect('set_default_never', 'ok');
        Observer.Expect('has_after', 'No');
        Observer.Expect('register_a', 'ok');
        Observer.Expect('set_default_a', 'ok');
        Observer.Expect('unregister_a', 'ok');
        Observer.Expect('set_default_after_unregister', 'ok');
        Observer.Verify();
    end;
}
