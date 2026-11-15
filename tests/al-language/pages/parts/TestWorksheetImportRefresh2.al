// BC Documentation: https://learn.microsoft.com/dynamics365/business-central/dev-itpro/developer/devenv-testing-pages
// Scope: in-scope (Cloud-compatible)
// Fixtures used: local behavior-defining objects
// BC versions: 27.5+

codeunit 51759 "PAG WorksheetImportRe Tests 2"
{
    Subtype = Test;
    TestPermissions = Disabled;

    [Test]
    procedure OpenEditRefreshSelectsImportedRow()
    var
        Worksheet: TestPage "PAG Refresh 2 Worksheet";
    begin
        Initialize();
        Worksheet.OpenEdit();
        Worksheet.Id.AssertEquals('');
        Worksheet.ImportRow.Invoke();
        Worksheet.Id.AssertEquals('SEVEN');
        Worksheet.ReadId.AssertEquals('SEVEN');
        Worksheet.CurrentId.AssertEquals('SEVEN');
        Worksheet.CheckImportedSelection.Invoke();
        Worksheet.Close();
    end;

    local procedure InitializeFixture()
    var
        Row: Record "PAG Refresh 2 Row";
    begin
        Row.DeleteAll();
        Row.Id := 'ONE';
        Row.Batch := 'HIDDEN';
        Row.VisibleKind := true;
        Row.Insert();
    end;

    local procedure Initialize()
    var
        ProbeTable1: Record "PAG Refresh 2 Row";
    begin
        ProbeTable1.DeleteAll();
        InitializeFixture();
    end;
}
