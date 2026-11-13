// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/properties/devenv-movedto-property
// Scope: in-scope
// Fixtures used: Probe Observer (codeunit 69160); table 61178 "LT MV XA Probe Row", live in cross-app fixture A (MvXaLiveTable.al)
//   and declared again with ObsoleteState = Moved and MovedTo = fixture A in cross-app fixture B (MvXbMovedStub.al)
// Probe: al-runner issue 7914. An app (B) that depends on the app (A) declaring a table live may declare the same id and name as a
//   Moved stub: both apps compile and publish. This app depends on both; a row inserted by the table name is read back with Get and
//   through RecordRef.Open(61178), so the run shows one table holds the row. A live duplicate in a dependent app does not compile
//   (must-not-compile case 2149); MovedTo naming the declaring app itself is case 0699.
// BC versions: 27, 28, 29

codeunit 70024 "MV Moved Table Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure MovedStub_InsertGetAndRecordRef()
    var
        Row: Record "LT MV XA Probe Row";
        Row2: Record "LT MV XA Probe Row";
        RecRef: RecordRef;
        Observer: Codeunit "Probe Observer";
    begin
        Row.DeleteAll();
        Row.Id := 7;
        Row.Name := 'alpha';
        Row.Insert();
        Observer.Observe('get', Format(Row2.Get(7)) + ':' + Row2.Name);
        Observer.Observe('tableNo', Format(Database::"LT MV XA Probe Row"));
        RecRef.Open(61178);
        Observer.Observe('recRefCount', Format(RecRef.Count()));
        Observer.Observe('recRefFind', Format(RecRef.FindFirst()));
        Observer.Observe('recRefId', Format(RecRef.Field(1).Value()));
        Observer.Observe('recRefName', Format(RecRef.Field(2).Value()));
        RecRef.Close();
        Observer.Expect('get', 'Yes:alpha');
        Observer.Expect('tableNo', '61178');
        Observer.Expect('recRefCount', '1');
        Observer.Expect('recRefFind', 'Yes');
        Observer.Expect('recRefId', '7');
        Observer.Expect('recRefName', 'alpha');
        Observer.Verify();
    end;
}
