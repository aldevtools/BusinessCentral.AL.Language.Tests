// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51739 "PAG CardPartDrilldown Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure DrilldownRefreshesTheHeaderBeforeTheNextScan()
    var
        Row: Record "Probe Packing State";
        Document: TestPage "Probe Packing Document";
        FirstShown: Text;
    begin
        Initialize();
        Row.Id := 'ORDER';
        Row.PackageCode := 'FIRST';
        Row.Insert();
        Document.OpenEdit();
        Document.GoToRecord(Row);
        Document.PackageActions.NewPackage.DrillDown();
        FirstShown := Document.PackageCode.Value;
        Document.Scan.SetValue('SCAN');
        Row.Get('ORDER');
        if (FirstShown <> 'FIRST') or (Row.LastScannedPackage <> 'SECOND') then
            Error('Before the next scan the page showed %1. The scan used package %2.', FirstShown, Row.LastScannedPackage);
        Document.Close();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Probe Packing State";
    begin
        ProbeTable1.DeleteAll();
    end;
}
