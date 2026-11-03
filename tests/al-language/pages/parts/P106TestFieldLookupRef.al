// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testfield/testfield-data-type
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); LT P106 Item/Group/Log tables, LT P106 Log codeunit, pages LT P106 Card / List / Group List / Sub / Host from P106Fixtures.al
// Probe: written against a local BC 29.0.54011.55816 service tier; every literal asserted below is what that tier produced. Other BC versions are checked by the corpus CI matrix.
// Facts: TestField.Lookup(Selected: RecordRef) (overload #2) on a field with a table relation and on a field with an OnLookup trigger: the RecordRef receives the selected record; OK, Cancel, closed RecordRef, RecordRef of the wrong table
// BC versions: 29 (27 and 28 by CI)

codeunit 72418 "LT P106 TestField Lookup"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Log: Codeunit "LT P106 Log";
        H: Text;
        Mode: Integer;

    [ModalPageHandler]
    procedure GroupH(var P: TestPage "LT P106 Group List")
    begin
        H += 'group=' + P.CodeCtl.Value() + ';';
        if Mode = 2 then
            P.GoToKey('G3');
        if Mode = 1 then
            P.Cancel().Invoke()
        else
            P.OK().Invoke();
    end;

    [Test]
    procedure P106_LookupRef_OnLookupTrigger()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P106 Card";
        RecRef: RecordRef;
    begin
        Log.Seed();
        Card.OpenEdit();
        Log.Reset();
        RecRef.Open(Database::"LT P106 Item");
        Card.LookupCtl.Lookup(RecRef);
        Observer.Observe('log', Log.Dump());
        Observer.Observe('value', Card.LookupCtl.Value());
        Observer.Observe('recref_code', Format(RecRef.Field(1).Value));
        Card.Close();
        Observer.Expect('log', '');
        Observer.Expect('value', '');
        Observer.Expect('recref_code', '');
        Observer.Verify();
    end;

    [Test]
    procedure P106_LookupRef_Errors()
    var
        Observer: Codeunit "Probe Observer";
        Card: TestPage "LT P106 Card";
        RecRef: RecordRef;
        ItemRef: RecordRef;
    begin
        Log.Seed();
        Card.OpenEdit();
        asserterror Card.GrpCtl.Lookup(RecRef);
        Observer.ObserveError('closed_recref');
        ItemRef.Open(Database::"LT P106 Item");
        asserterror Card.GrpCtl.Lookup(ItemRef);
        Observer.ObserveError('wrong_table');
        Card.NameCtl.Lookup(ItemRef);
        Observer.Observe('no_relation', 'no error');
        Card.Close();
        Observer.Expect('closed_recref|text', 'The record is not open.');
        Observer.Expect('closed_recref|code', 'RecordNotOpened');
        Observer.Expect('wrong_table|text', 'The input record belongs to a table different from the one the page is based on.');
        Observer.Expect('wrong_table|code', 'TestSourceTableMismatch');
        Observer.Expect('no_relation', 'no error');
        Observer.Verify();
    end;
}
