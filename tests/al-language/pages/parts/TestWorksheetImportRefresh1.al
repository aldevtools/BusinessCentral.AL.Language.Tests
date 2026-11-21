// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51756 "PAG WorksheetImportRe Tests 1"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    [HandlerFunctions('EmptyWorksheetHandler')]
    procedure ModalWorksheetWithNoMatchingRows()
    begin
        Initialize();
        Page.RunModal(Page::"PAG Refresh 1 Worksheet");
    end;

    [Test]
    [HandlerFunctions('ImportWorksheetHandler')]
    procedure ModalWorksheetRefreshSelectsImportedRow()
    begin
        Initialize();
        Page.RunModal(Page::"PAG Refresh 1 Worksheet");
    end;

    [ModalPageHandler]
    procedure ImportWorksheetHandler(var Worksheet: TestPage "PAG Refresh 1 Worksheet")
    begin
        Worksheet.ImportRow.Invoke();
        Worksheet.Id.AssertEquals('SEVEN');
        Worksheet.ReadId.AssertEquals('SEVEN');
        Worksheet.CurrentId.AssertEquals('SEVEN');
        Worksheet.CheckImportedSelection.Invoke();
    end;

    [ModalPageHandler]
    procedure EmptyWorksheetHandler(var Worksheet: TestPage "PAG Refresh 1 Worksheet")
    begin
        Worksheet.CheckSelection.Invoke();
    end;

    local procedure InitializeFixture()
    var
        Row: Record "PAG Refresh 1 Row";
    begin
        Row.DeleteAll();
        Row.Id := 'ONE';
        Row.Batch := 'HIDDEN';
        Row.VisibleKind := true;
        Row.Insert();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "PAG Refresh 1 Row";
    begin
        ProbeTable1.DeleteAll();
        InitializeFixture();
    end;
}
