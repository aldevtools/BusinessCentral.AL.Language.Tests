// BC versions: 27.5, 28.5, 29.0.
// Scope: Cloud-compatible public API.
// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-page-ext-object
// Claim: a page carrying this layout modification can open and expose a seeded, non-default value.
// This is not a visual-order assertion. Real-BC execution status is recorded separately.
// Fixtures: ALT Universal; local page and extension definitions. BC versions: 27.5, 28.5, 29.0.
codeunit 69009 "PAG Repeater Move Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure PageExtension_MoveFirstRepeater_ReadsSeededValue()
    var
        View: TestPage "PAG Layout List";
    begin
        Initialize();
        View.OpenView();
        View.Description.AssertEquals('Non-default layout value');
        View.Close();
    end;
    local procedure Initialize()
    var
        Row: Record "ALT Universal";
    begin
        FixtureCleanup.Initialize();
        Row."Entry No." := 42;
        Row."Code Field" := 'ROW1';
        Row."Text Field" := 'Non-default layout value';
        Row.Insert();
    end;
}
