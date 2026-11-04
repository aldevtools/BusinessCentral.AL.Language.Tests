// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-commit-method
//   https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/attributes/devenv-commitbehavior-attribute
// Scope: in-scope
// Fixtures used: ALT Universal (60000), ALTFixtureCleanup (60019), shared Assert (60021)
// Probe: written against a real BC 27.5 service tier; every literal below is what that tier
// produced. Other BC versions were not measured.
//
// "Test Commit Behavior Attr" (60881) pins only the fragment "Commit is prohibited in the
// current scope". This codeunit pins the whole text and the error code of a Commit() inside a
// [CommitBehavior(CommitBehavior::Error)] scope.
// BC versions: 27.5

codeunit 68103 "Probe Commit Behavior Err Text"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;
        Cleanup: Codeunit ALTFixtureCleanup;

    local procedure Initialize()
    begin
        Cleanup.Initialize();
        Commit();
    end;

    [Test]
    procedure CommitBehaviorError_Commit_FullTextAndCode()
    // CLAIM: the refusal reads "Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator." with code DB:Ok.
    begin
        Initialize();

        asserterror InsertThenCommitUnderErrorBehavior();

        Assert.AreEqual('Commit is prohibited in the current scope. The operation cannot continue. Contact your system administrator.', GetLastErrorText(), 'full text');
        Assert.AreEqual('DB:Ok', GetLastErrorCode(), 'error code');
    end;

    [CommitBehavior(CommitBehavior::Error)]
    local procedure InsertThenCommitUnderErrorBehavior()
    var
        ALTUniversal: Record "ALT Universal";
    begin
        ALTUniversal.Init();
        ALTUniversal."Entry No." := 68103;
        ALTUniversal.Insert();
        Commit();
    end;
}
