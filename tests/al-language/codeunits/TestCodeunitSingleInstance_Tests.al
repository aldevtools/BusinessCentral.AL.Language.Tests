// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/devenv-codeunit-object
// Scope: in-scope
// Fixtures used: Test SIC Single (60597), Test SIC Multi (60598), Assert (60021)
//
// A SingleInstance=true codeunit must share ONE instance per session, so a value
// set through one codeunit variable/handle is visible through a DIFFERENT
// variable/handle of the SAME codeunit within the same test. A non-SingleInstance
// codeunit must NOT share state across independent variables.

codeunit 60599 "Test Codeunit SingleInstance"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    trigger OnRun()
    begin
    end;

    local procedure Initialize()
    begin
    end;

    [Test]
    procedure TestCodeunit_SingleInstance_StateVisibleThroughDifferentVariable()
    var
        S1: Codeunit "Test SIC Single";
        S2: Codeunit "Test SIC Single";
    begin
        Initialize();

        // S1 and S2 are two independent local codeunit variables of the SAME
        // SingleInstance=true codeunit — each resolves its own codeunit handle,
        // exercising a SEPARATE instance-creation call.
        S1.SetValue(99);
        Assert.AreEqual(99, S2.GetValue(),
            'SingleInstance codeunit must share one instance per session — value set via S1 must be visible via S2');
    end;

    // Contrast case: an ordinary (SingleInstance=false) codeunit must NOT share
    // state across independent variables — this pins the fix to SingleInstance
    // codeunits only and proves the fresh-instance behavior for regular codeunits
    // is unchanged.
    [Test]
    procedure TestCodeunit_NonSingleInstance_FreshInstancePerVariable()
    var
        M1: Codeunit "Test SIC Multi";
        M2: Codeunit "Test SIC Multi";
    begin
        Initialize();

        M1.SetValue(99);
        Assert.AreEqual(0, M2.GetValue(),
            'Non-SingleInstance codeunit must get a fresh instance per variable — M2 must see the default, not M1''s value');
    end;
}
