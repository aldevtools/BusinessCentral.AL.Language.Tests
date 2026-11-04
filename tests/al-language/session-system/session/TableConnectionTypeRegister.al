// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
// Scope: in-scope
// Fixtures used: Probe Observer (69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: RegisterTableConnection of each TableConnectionType with a dummy connection string: outcome (ok or error text start and code), HasTableConnection afterwards, then UnregisterTableConnection (issue #184 item 21).
// BC versions: 29 (27 and 28 by CI)

codeunit 74449 "LT TCT Register"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryRegister(Type: TableConnectionType; Name: Text; ConnString: Text)
    begin
        RegisterTableConnection(Type, Name, ConnString);
    end;

    [TryFunction]
    local procedure TryUnregister(Type: TableConnectionType; Name: Text)
    begin
        UnregisterTableConnection(Type, Name);
    end;

    local procedure Probe(var Observer: Codeunit "Probe Observer"; Tag: Text; Type: TableConnectionType; ConnString: Text)
    var
        Name: Text;
    begin
        Name := 'LT TCT ' + Tag;
        if TryRegister(Type, Name, ConnString) then
            Observer.Observe(Tag + '_register', 'ok')
        else
            Observer.Observe(Tag + '_register', 'error:' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
        Observer.Observe(Tag + '_has', Format(HasTableConnection(Type, Name)));
        if TryUnregister(Type, Name) then
            Observer.Observe(Tag + '_unregister', 'ok')
        else
            Observer.Observe(Tag + '_unregister', 'error:' + CopyStr(GetLastErrorText(), 1, 200) + '|' + GetLastErrorCode());
        Observer.Observe(Tag + '_has_after', Format(HasTableConnection(Type, Name)));
    end;

    [Test]
    procedure Register_Crm_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'crm', TableConnectionType::CRM, 'Url=http://localhost/none;User=a;Password=b');
        Observer.Expect('crm_register', 'ok');
        Observer.Expect('crm_has', 'Yes');
        Observer.Expect('crm_unregister', 'ok');
        Observer.Expect('crm_has_after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Register_ExternalSql_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'sql', TableConnectionType::ExternalSQL, 'Server=localhost;Database=none;');
        Observer.Expect('sql_register', 'error:You do not have permission to register a table connection of type ExternalSQL. Please contact your administrator.|NotAllowedForCompilationTarget');
        Observer.Expect('sql_has', 'No');
        Observer.Expect('sql_unregister', 'ok');
        Observer.Expect('sql_has_after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Register_Exchange_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'exchange', TableConnectionType::Exchange, 'Url=http://localhost/none');
        Observer.Expect('exchange_register', 'error:You do not have permission to register a table connection of type Exchange. Please contact your administrator.|NotAllowedForCompilationTarget');
        Observer.Expect('exchange_has', 'No');
        Observer.Expect('exchange_unregister', 'ok');
        Observer.Expect('exchange_has_after', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure Register_MicrosoftGraph_Result()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Probe(Observer, 'graph', TableConnectionType::MicrosoftGraph, 'Url=http://localhost/none');
        Observer.Expect('graph_register', 'error:You do not have permission to register a table connection of type MicrosoftGraph. Please contact your administrator.|NotAllowedForCompilationTarget');
        Observer.Expect('graph_has', 'No');
        Observer.Expect('graph_unregister', 'ok');
        Observer.Expect('graph_has_after', 'No');
        Observer.Verify();
    end;
}
