// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/datatransfer/datatransfer-data-type
// Scope: in-scope (Cloud-compatible)
// Fixtures used: ALT Universal (60000), ALT Composite (60001)
// BC versions: 27.5+
//
// CLAIM: DataTransfer.CopyRows throws when invoked outside upgrade/install context.
// This is real, provable Cloud behavior -- not a runner limitation.

codeunit 60875 "Test DataTransfer Scope"
{
    Subtype = Test;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
    end;

    [Test]
    procedure DataTransfer_CopyRows_OutsideUpgrade_Throws()
    var
        DT: DataTransfer;
    begin
        Initialize();
        asserterror begin
            DT.SetTables(Database::"ALT Universal", Database::"ALT Composite");
            DT.CopyRows();
        end;
        Assert.IsTrue(GetLastErrorText() <> '', 'DataTransfer.CopyRows must throw outside upgrade/install context');
    end;
}
