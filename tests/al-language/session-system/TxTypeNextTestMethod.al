// BC Documentation: https://learn.microsoft.com/en-us/dynamics365/business-central/dev-itpro/developer/methods-auto/database/database-currenttransactiontype-method
// Scope: in-scope
// local object: the session's transaction type at the start of a test method, after the test method before it set one
// Fixtures used: shared Assert (60021); own test codeunit 97185
// Probe (al-runner issue 8606): the type a test method leaves is the type the next test method of the codeunit starts with; the
//   test runner does not put it back to UpdateNoLocks. TxN01 commits, sets Browse and ends with no database call; TxN02 reads it at its
//   start, then sets UpdateNoLocks back after a Commit, as Library - Manufacturing.RefreshProdOrder does after its run.
//   Measured on a local BC 29.1 OnPrem w1 container (2/2 green); BC 27.5, 28.5 and 29.0 are left to CI.
// BC versions: 27, 28, 29
codeunit 97185 "TxU Type Next Test"
{
    Subtype = Test;
    TestPermissions = Disabled;

    var
        Assert: Codeunit Assert;

    [Test]
    procedure TxN01_SetsTypeBrowse()
    begin
        // A Commit first: at the first test method of a codeunit the test runner's own transaction has started, and a set
        // to Browse there has no effect.
        Commit();
        CurrentTransactionType(TransactionType::Browse);
        Assert.AreEqual('Browse', Format(CurrentTransactionType()), 'The type after the set.');
    end;

    [Test]
    procedure TxN02_StartsWithThePreviousTestsType()
    var
        TypeAtStart: Text;
    begin
        TypeAtStart := Format(CurrentTransactionType());
        Commit();
        CurrentTransactionType(TransactionType::UpdateNoLocks);
        Assert.AreEqual('Browse', TypeAtStart, 'The type at the start of the test after the one that set Browse.');
    end;
}
