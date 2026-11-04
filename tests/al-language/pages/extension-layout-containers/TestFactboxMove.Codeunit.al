// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Claim: a page carrying this layout modification can open and expose a seeded, non-default value.
// This is not a visual-order assertion. Real-BC execution status is recorded separately.
// Fixtures: shared RG Layout pages, table and extensions. BC versions: 27.5, 28.5, 29.0.
codeunit 69008 "PAG Factbox Move Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure LayoutMove_OpenPage_ReadsSeededValue()
    var
        View: TestPage "PAG Layout Card";
    begin
        Initialize();
        View.OpenView();
        View.Description.AssertEquals('Non-default layout value');
        View.Close();
    end;
    local procedure Initialize()
    var
        Row: Record "PAG Layout Row";
    begin
        FixtureCleanup.Initialize();
        Row.DeleteAll();
        Row.Code := 'ROW1';
        Row.Description := 'Non-default layout value';
        Row.Insert();
    end;
}
