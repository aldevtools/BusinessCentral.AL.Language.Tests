// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/testpage/testpage-openview-method
// Claim: opening an empty host in view mode completes and exposes its non-empty caption.
// No assumption is asserted about whether BC invokes the part's OnNewRecord; that needs a real-BC probe.
// Fixtures: TPG Empty Header, TPG Empty Line, TPG Empty Host, TPG Empty Lines.
// BC versions: 27.5, 28.5, 29.0.
codeunit 69026 "TPG Empty Host Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        FixtureCleanup: Codeunit ALTFixtureCleanup;
    [Test]
    procedure OpenView_EmptyHostWithListPart_ExposesCaption()
    var
        Host: TestPage "TPG Empty Host";
    begin
        Initialize();
        Host.OpenView();
        if Host.Lines.First() then
            Error('Expected no stored line below the empty host.');
        if StrPos(Host.Caption(), 'Runner Repro Header') = 0 then
            Error('Expected the opened host caption, got %1.', Host.Caption());
        Host.Close();
    end;
    local procedure Initialize()
    var
        Header: Record "TPG Empty Header";
        Line: Record "TPG Empty Line";
    begin
        FixtureCleanup.Initialize();
        Line.DeleteAll();
        Header.DeleteAll();
    end;
}
