// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51774 "PAG ModalWorksheetBla Tests"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('EmptyWorksheetHandler')]
    procedure ModalWorksheetWithNoMatchingRows()
    begin
        Initialize();
        Page.RunModal(Page::"Refresh Probe Worksheet");
    end;

    [ModalPageHandler]
    procedure EmptyWorksheetHandler(var Worksheet: TestPage "Refresh Probe Worksheet")
    begin
        Worksheet.CheckSelection.Invoke();
    end;

    local procedure InitializeFixture()
    var
        Row: Record "Refresh Probe Row";
    begin
        Row.DeleteAll();
        Row.Id := 'ONE';
        Row.Batch := 'HIDDEN';
        Row.VisibleKind := true;
        Row.Insert();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "Refresh Probe Row";
    begin
        ProbeTable1.DeleteAll();
        InitializeFixture();
    end;
}
