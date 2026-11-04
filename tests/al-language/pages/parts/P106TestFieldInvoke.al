// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List / Group List / Sub / Host from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField.Invoke on controls with OnDrillDown, OnAssistEdit, OnLookup triggers and on plain fields (the log shows which trigger ran)
// BC versions: 29 (27 and 28 by CI)

codeunit 72416 "LT P106 TestField Invoke"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";

    [Test]
    procedure P106_Invoke_DrillDown()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P106 Card";
    begin
        Log.Seed();
        Card.OpenView();
        Log.Reset();
        asserterror Card.DrillCtl.Invoke();
        Observer.ObserveError('af25');
        Observer.Observe('log', Log.Dump());
        Card.Close();
        Observer.Expect('af25|text', 'The Invoke method is not supported.');
        Observer.Expect('af25|code', 'MethodNotSupported');
        Observer.Expect('log', '');
        Observer.Verify();
    end;
}
