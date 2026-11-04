// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-registertableconnection-method
// Scope: in-scope
// Fixtures used: none
//
// Registering a CRM test connection ('@@test@@') twice raises a text naming the type and the name;
// the name match ignores case; ExternalSQL registration raises a permission text; HasTableConnection
// and GetDefaultTableConnection for ExternalSQL. The connection is unregistered at the end of every
// test.
//
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// BC versions: 29 (27 and 28 by CI)

codeunit 72722 "LT P161 Table Connections"
{
    Subtype = Test;
    TestPermissions = Disabled;

    local procedure Cleanup()
    begin
        if Database.HasTableConnection(TableConnectionType::CRM, 'P161Conn') then
            Database.UnregisterTableConnection(TableConnectionType::CRM, 'P161Conn');
    end;

    [Test]
    procedure P161_RegisterTwice_SameAndOtherCase()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        Database.RegisterTableConnection(TableConnectionType::CRM, 'P161Conn', '@@test@@');
        asserterror Database.RegisterTableConnection(TableConnectionType::CRM, 'P161Conn', '@@test@@');
        Observer.ObserveError('twiceSame');
        asserterror Database.RegisterTableConnection(TableConnectionType::CRM, 'P161CONN', '@@test@@');
        Observer.ObserveError('twiceUpper');
        Observer.Observe('has', Format(Database.HasTableConnection(TableConnectionType::CRM, 'P161Conn')));
        Observer.Observe('hasLower', Format(Database.HasTableConnection(TableConnectionType::CRM, 'p161conn')));
        Cleanup();
        Observer.Observe('hasAfterCleanup', Format(Database.HasTableConnection(TableConnectionType::CRM, 'P161Conn')));
        Observer.Expect('twiceSame|text', 'Table connection P161Conn for table type CRM has already been registered.');
        Observer.Expect('twiceSame|code', 'Argument');
        Observer.Expect('twiceUpper|text', 'Table connection P161CONN for table type CRM has already been registered.');
        Observer.Expect('twiceUpper|code', 'Argument');
        Observer.Expect('has', 'Yes');
        Observer.Expect('hasLower', 'Yes');
        Observer.Expect('hasAfterCleanup', 'No');
        Observer.Verify();
    end;

    [Test]
    procedure P161_Unregister_NotRegistered()
    var
        Observer: Codeunit "Probe Observer";
    begin
        Cleanup();
        Database.UnregisterTableConnection(TableConnectionType::CRM, 'P161Conn');
        Observer.Observe('unregisterMissing', 'no error');
        Database.SetDefaultTableConnection(TableConnectionType::CRM, 'P161Conn');
        Observer.Observe('defaultMissing', 'no error');
        Observer.Expect('unregisterMissing', 'no error');
        Observer.Expect('defaultMissing', 'no error');
        Observer.Verify();
    end;
}
