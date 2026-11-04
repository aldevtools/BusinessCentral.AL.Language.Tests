// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-unregistertableconnection-method
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160)
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: UnregisterTableConnection of a name never registered for the other table connection types
// BC versions: 29 (27 and 28 by CI)

codeunit 74433 "LT P137 Table Conn Types"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [TryFunction]
    local procedure TryUnregisterSql(Name: Text)
    begin
        UnregisterTableConnection(TableConnectionType::ExternalSQL, Name);
    end;

    [TryFunction]
    local procedure TryUnregisterExchange(Name: Text)
    begin
        UnregisterTableConnection(TableConnectionType::Exchange, Name);
    end;

    [TryFunction]
    local procedure TryUnregisterGraph(Name: Text)
    begin
        UnregisterTableConnection(TableConnectionType::MicrosoftGraph, Name);
    end;

    local procedure Out(Ok: Boolean): Text
    begin
        if Ok then
            exit('ok');
        exit(CopyStr('error:' + GetLastErrorText() + '|' + GetLastErrorCode(), 1, 800));
    end;

    [Test]
    procedure P137_Unregister_NeverRegistered_OtherTypes()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Observer.Observe('external_sql', Out(TryUnregisterSql('P137NEVER')));
        ClearLastError();
        Observer.Observe('exchange', Out(TryUnregisterExchange('P137NEVER')));
        ClearLastError();
        Observer.Observe('graph', Out(TryUnregisterGraph('P137NEVER')));
        ClearLastError();
        Observer.Expect('external_sql', 'ok');
        Observer.Expect('exchange', 'ok');
        Observer.Expect('graph', 'ok');
        Observer.Verify();
    end;
}
