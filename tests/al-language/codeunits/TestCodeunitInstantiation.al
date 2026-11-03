// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/codeunit/codeunit-run-method
// Scope: in-scope

codeunit 60078 "Test Codeunit Instantiation"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    // ── Codeunit.Run() ──────────────────────────────────────────────────────

    [Test]
    procedure Codeunit_Run_ValidCodeunit_DoesNotThrow()
    begin
        Initialize();
        Codeunit.Run(Codeunit::ALTFixtureCleanup);
        Assert.IsTrue(true, 'Codeunit.Run must not throw on valid codeunit');
    end;

    [Test]
    procedure Codeunit_Variable_CanBeAssigned()
    var
        CU: Codeunit ALTFixtureCleanup;
    begin
        Initialize();
        CU.Initialize();
        Assert.IsTrue(true, 'Calling codeunit method must not throw');
    end;

    [Test]
    procedure Codeunit_Double_Compute_ReturnsTwiceX()
    var
        D: Codeunit ALTDouble;
        Result: Integer;
    begin
        Initialize();
        Result := D.Compute(5);
        Assert.AreEqual(10, Result, 'ALTDouble.Compute(5) must return 10');
    end;

    [Test]
    procedure Codeunit_Square_Compute_ReturnsSquare()
    var
        S: Codeunit ALTSquare;
        Result: Integer;
    begin
        Initialize();
        Result := S.Compute(5);
        Assert.AreEqual(25, Result, 'ALTSquare.Compute(5) must return 25');
    end;

    [Test]
    procedure Codeunit_Run_ReturnsBoolean()
    var
        Result: Boolean;
    begin
        Cleanup.Initialize();
        Commit();  // ensure clean transaction state before Codeunit.Run
        // Assert codeunit has an explicit OnRun trigger (no-op) — safe to call via Codeunit.Run()
        Result := Codeunit.Run(Codeunit::Assert);
        Assert.IsTrue(Result, 'Codeunit.Run must return true on success');
    end;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;
}
