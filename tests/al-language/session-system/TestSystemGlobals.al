// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/system
// Scope: in-scope
// Fixtures used: Assert (60021), ALT Fixture Cleanup (60001)

codeunit 60120 "Test System Globals"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Date/Time Globals ───────────────────────────────────────────────────────

            [Test]
    procedure ClearCollectedErrors_DoesNotThrow()
    begin
        Initialize();
        ClearCollectedErrors();
        Assert.IsTrue(true, 'ClearCollectedErrors() must not throw');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        ClearLastError();
    end;
}
